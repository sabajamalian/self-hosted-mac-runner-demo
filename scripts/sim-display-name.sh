#!/usr/bin/env bash
# sim-display-name.sh – print a human-readable name for a simulator given its UDID.
#
# Usage: sim-display-name.sh <UDID>
# Output: "Device Name / Runtime Short Name" (e.g. "iPhone 15 / iOS17-2")
#         or "Unknown" when the UDID is not found.
set -euo pipefail

UDID="${1:-}"
if [[ -z "$UDID" ]]; then
  echo "Unknown"
  exit 0
fi

xcrun simctl list devices --json 2>/dev/null \
  | python3 -c "
import json, sys
udid = sys.argv[1]
data = json.load(sys.stdin)
for rt, devs in data.get('devices', {}).items():
    for d in devs:
        if d.get('udid') == udid:
            rt_short = rt.rsplit('.', 1)[-1].replace('iOS-', 'iOS', 1)
            print(d.get('name', 'Unknown') + ' / ' + rt_short)
            sys.exit(0)
print('Unknown')
" "$UDID" 2>/dev/null || echo "Unknown"
