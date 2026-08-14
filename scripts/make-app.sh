#!/bin/bash
# Wraps the SwiftPM executable in a minimal .app bundle so SLUJ can be
# launched like a normal Mac app. Read-only: it only writes inside .build/.
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

swift build -c "$CONFIG"

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
APP="$BIN_DIR/SLUJ.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/SLUJ" "$APP/Contents/MacOS/SLUJ"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>SLUJ</string>
    <key>CFBundleDisplayName</key>     <string>SLUJ</string>
    <key>CFBundleIdentifier</key>      <string>dev.sluj.SLUJ</string>
    <key>CFBundleExecutable</key>      <string>SLUJ</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>0.1.0</string>
    <key>CFBundleVersion</key>         <string>1</string>
    <key>LSMinimumSystemVersion</key>  <string>14.0</string>
    <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
PLIST

echo "Built $APP"
echo "Run it with:  open \"$APP\""
