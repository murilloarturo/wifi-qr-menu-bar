#!/bin/bash
# Builds the app, quits a running copy, and opens the new build.
set -euo pipefail
cd "$(dirname "$0")/.."
CONFIGURATION="${1:-Debug}"
Scripts/build.sh "$CONFIGURATION"
if pkill -x "WiFi QR"; then
  while pgrep -x "WiFi QR" > /dev/null; do sleep 0.2; done
fi
open ".build/DerivedData/Build/Products/$CONFIGURATION/WiFi QR.app"
