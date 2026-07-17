#!/usr/bin/env bash
# ci.sh – build and run xcodebuild tests against a pre-booted iOS simulator.
#
# Reads the simulator UDID from RUNNER_TEMP (written by create-simulator.sh).
# Stores DerivedData and the .xcresult bundle under RUNNER_TEMP.
# Preserves the xcodebuild exit status so the caller can detect failures.
set -euo pipefail

# ── Resolve paths ─────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -z "${RUNNER_TEMP:-}" ]]; then
  RUNNER_TEMP="$(mktemp -d /tmp/runner-demo-XXXXXX)"
  export RUNNER_TEMP
  echo "Local mode: RUNNER_TEMP=$RUNNER_TEMP"
fi

UDID_FILE="$RUNNER_TEMP/simulator_udid"
if [[ ! -f "$UDID_FILE" ]]; then
  echo "ERROR: No simulator UDID found at $UDID_FILE" >&2
  echo "       Run scripts/create-simulator.sh first." >&2
  exit 1
fi

SIMULATOR_UDID="$(cat "$UDID_FILE")"
if [[ -z "$SIMULATOR_UDID" ]]; then
  echo "ERROR: Simulator UDID file is empty." >&2
  exit 1
fi

# ── Build paths ───────────────────────────────────────────────────────────────
PROJECT="$REPO_ROOT/RunnerDemo/RunnerDemo.xcodeproj"
SCHEME="RunnerDemo"
BUILD_DIR="$RUNNER_TEMP/DerivedData"
RESULT_BUNDLE="$RUNNER_TEMP/TestResults.xcresult"
LOG_FILE="$RUNNER_TEMP/xcodebuild.log"

mkdir -p "$BUILD_DIR"
rm -rf "$RESULT_BUNDLE"

echo "=== Running Tests ==="
echo "Project:         $PROJECT"
echo "Scheme:          $SCHEME"
echo "Simulator UDID:  $SIMULATOR_UDID"
echo "Build directory: $BUILD_DIR"
echo "Result bundle:   $RESULT_BUNDLE"
echo ""

# ── Run xcodebuild test ───────────────────────────────────────────────────────
# Use set +e so we can capture the exit code without aborting on failure.
set +e
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -derivedDataPath "$BUILD_DIR" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | tee "$LOG_FILE"
BUILD_EXIT_CODE="${PIPESTATUS[0]}"
set -e

echo ""
if [[ "$BUILD_EXIT_CODE" -eq 0 ]]; then
  echo "=== Tests PASSED ==="
else
  echo "=== Tests FAILED (xcodebuild exit code: $BUILD_EXIT_CODE) ===" >&2
fi

echo "Log file:      $LOG_FILE"
echo "Result bundle: $RESULT_BUNDLE"

exit "$BUILD_EXIT_CODE"
