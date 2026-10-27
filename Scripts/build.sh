#!/bin/bash
# Generates the Xcode project and builds the app into .build/DerivedData.
set -euo pipefail
cd "$(dirname "$0")/.."
CONFIGURATION="${1:-Debug}"
mkdir -p .build
xcodegen generate --quiet
if ! xcodebuild -project WiFiQR.xcodeproj -scheme WiFiQR -configuration "$CONFIGURATION" -destination 'platform=macOS' -derivedDataPath .build/DerivedData build > ".build/build-$CONFIGURATION.log" 2>&1; then
  tail -50 ".build/build-$CONFIGURATION.log"
  exit 1
fi
echo "Built .build/DerivedData/Build/Products/$CONFIGURATION/WiFi QR.app"
