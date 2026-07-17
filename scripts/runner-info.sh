#!/usr/bin/env bash
# runner-info.sh – emit sanitized runner diagnostics.
#
# Outputs: CPU architecture, macOS version, Xcode version,
#          available disk space, and installed iOS runtimes.
#
# Does NOT output: serial numbers, hardware UUIDs, IP addresses,
# usernames, home-directory paths, or environment variable dumps.
set -euo pipefail

echo "=== Runner Diagnostics ==="
echo ""

echo "CPU Architecture: $(uname -m)"
echo ""

echo "--- macOS Version ---"
sw_vers
echo ""

echo "--- Xcode Version ---"
xcodebuild -version
echo ""

echo "--- Available Disk Space (root volume) ---"
# Print only Size/Used/Available/Capacity columns; omit filesystem path
df -h / | awk 'NR==1{print $2,$3,$4,$5} NR==2{print $2,$3,$4,$5}'
echo ""

echo "--- Installed iOS Runtimes ---"
xcrun simctl list runtimes 2>/dev/null | grep -i "^iOS" || echo "(none found)"
echo ""

echo "=== End of Diagnostics ==="
