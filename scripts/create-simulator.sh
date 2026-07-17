#!/usr/bin/env bash
# create-simulator.sh – dynamically create, boot, and record a run-scoped iOS simulator.
#
# Selects the newest available iOS runtime and a compatible iPhone device type.
# Persists the simulator UDID to RUNNER_TEMP for use by subsequent steps.
# Works both in GitHub Actions (RUNNER_TEMP is set automatically) and locally.
set -euo pipefail

# ── Environment setup ─────────────────────────────────────────────────────────
if [[ -z "${RUNNER_TEMP:-}" ]]; then
  RUNNER_TEMP="$(mktemp -d /tmp/runner-demo-XXXXXX)"
  export RUNNER_TEMP
  echo "Local mode: RUNNER_TEMP=$RUNNER_TEMP"
fi

UDID_FILE="$RUNNER_TEMP/simulator_udid"

# Use the GitHub Actions run ID if available; otherwise generate one
RUN_ID="${GITHUB_RUN_ID:-local-$$}"
SIM_NAME="RunnerDemo-CI-${RUN_ID}"

echo "=== Creating iOS Simulator ==="
echo "Simulator name: $SIM_NAME"

# ── Select newest available iOS runtime ──────────────────────────────────────
RUNTIME=$(xcrun simctl list runtimes --json \
  | python3 -c '
import json, sys
data = json.load(sys.stdin)
runtimes = [
    r for r in data.get("runtimes", [])
    if r.get("isAvailable", False) and "iOS" in r.get("name", "")
]
if not runtimes:
    print("ERROR: No available iOS runtimes found", file=sys.stderr)
    sys.exit(1)
runtimes.sort(key=lambda r: r.get("version", "0"), reverse=True)
print(runtimes[0]["identifier"])
')
echo "Selected runtime: $RUNTIME"

# ── Select a compatible iPhone device type ────────────────────────────────────
DEVICE_TYPE=$(xcrun simctl list devicetypes --json \
  | python3 -c '
import json, sys
data = json.load(sys.stdin)
types = [
    d for d in data.get("devicetypes", [])
    if "iPhone" in d.get("name", "")
    # Exclude Pro Max / Plus variants: they require more simulator resources
    # and standard-size models provide consistent, reliable test environments.
    and "Max" not in d.get("name", "")
    and "Plus" not in d.get("name", "")
]
if not types:
    print("ERROR: No iPhone device types found", file=sys.stderr)
    sys.exit(1)
# Sort descending by name to prefer the most recent model
types.sort(key=lambda d: d.get("name", ""), reverse=True)
print(types[0]["identifier"])
')
echo "Selected device type: $DEVICE_TYPE"

# ── Create the simulator ──────────────────────────────────────────────────────
UDID=$(xcrun simctl create "$SIM_NAME" "$DEVICE_TYPE" "$RUNTIME")
echo "Created simulator UDID: $UDID"

# Persist UDID for ci.sh and cleanup.sh
echo "$UDID" > "$UDID_FILE"
echo "UDID persisted to: $UDID_FILE"

# ── Boot the simulator ────────────────────────────────────────────────────────
echo "Booting simulator..."
xcrun simctl boot "$UDID"

# Wait until the simulator reports Booted status
echo "Waiting for boot to complete..."
xcrun simctl bootstatus "$UDID" -b
echo "Simulator is booted."

echo "=== Simulator Ready: $UDID ==="
