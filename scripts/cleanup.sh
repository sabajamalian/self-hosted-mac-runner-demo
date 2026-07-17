#!/usr/bin/env bash
# cleanup.sh – shut down and delete only the simulator created for this run,
#              then remove run-scoped temporary build data.
#
# Safe to run multiple times (idempotent). Does not remove any simulator or
# data that was not created by this workflow run. Continues past individual
# errors so that all cleanup tasks are attempted.
set -uo pipefail  # intentionally omit -e so cleanup is not interrupted by errors

CLEANUP_ERRORS=0

# ── Guard: nothing to do if RUNNER_TEMP is unset ─────────────────────────────
if [[ -z "${RUNNER_TEMP:-}" ]]; then
  echo "RUNNER_TEMP is not set; nothing to clean up."
  exit 0
fi

# ── Simulator cleanup ─────────────────────────────────────────────────────────
UDID_FILE="$RUNNER_TEMP/simulator_udid"

if [[ ! -f "$UDID_FILE" ]]; then
  echo "No simulator UDID file found at $UDID_FILE; skipping simulator cleanup."
else
  SIMULATOR_UDID="$(cat "$UDID_FILE" 2>/dev/null || true)"

  if [[ -z "$SIMULATOR_UDID" ]]; then
    echo "UDID file is empty; skipping simulator cleanup."
  else
    echo "=== Cleaning up simulator: $SIMULATOR_UDID ==="

    # Check whether the simulator still exists
    if xcrun simctl list devices --json 2>/dev/null | grep -F "$SIMULATOR_UDID" >/dev/null; then
      echo "Shutting down simulator..."
      xcrun simctl shutdown "$SIMULATOR_UDID" 2>/dev/null || true

      echo "Deleting simulator..."
      if ! xcrun simctl delete "$SIMULATOR_UDID" 2>/dev/null; then
        echo "WARNING: Could not delete simulator $SIMULATOR_UDID" >&2
        CLEANUP_ERRORS=$((CLEANUP_ERRORS + 1))
      else
        echo "Simulator deleted."
      fi
    else
      echo "Simulator $SIMULATOR_UDID not found (already deleted)."
    fi
  fi

  # Remove the UDID record regardless
  rm -f "$UDID_FILE"
fi

# ── Run-scoped build artifact cleanup ────────────────────────────────────────
echo "=== Removing run-scoped build data ==="
for ITEM in \
  "$RUNNER_TEMP/DerivedData" \
  "$RUNNER_TEMP/TestResults.xcresult" \
  "$RUNNER_TEMP/xcodebuild.log" \
  "$RUNNER_TEMP/simulator-screenshot.png" \
  "$RUNNER_TEMP/artifacts"; do
  if [[ -e "$ITEM" ]]; then
    echo "Removing: $(basename "$ITEM")"
    rm -rf "$ITEM" || {
      echo "WARNING: Could not remove $ITEM" >&2
      CLEANUP_ERRORS=$((CLEANUP_ERRORS + 1))
    }
  fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
if [[ "$CLEANUP_ERRORS" -eq 0 ]]; then
  echo "=== Cleanup complete ==="
else
  echo "=== Cleanup finished with $CLEANUP_ERRORS warning(s) ===" >&2
fi

# Exit 0 even with warnings: cleanup should not fail a workflow that already
# recorded a test outcome, and non-zero would mask the real build result.
exit 0
