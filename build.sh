#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/build/RAM Monitor.app"
mkdir -p "$APP/Contents/MacOS" "$ROOT/build/module-cache"
export CLANG_MODULE_CACHE_PATH="$ROOT/build/module-cache"
swiftc -O -whole-module-optimization -target arm64-apple-macosx13.0 \
  -module-cache-path "$ROOT/build/module-cache" -framework AppKit \
  "$ROOT"/Sources/*.swift -o "$APP/Contents/MacOS/RAMMonitor"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>RAMMonitor</string>
<key>CFBundleIdentifier</key><string>org.nana.ram-cpu-monitor</string>
<key>CFBundleName</key><string>RAM Monitor</string>
<key>CFBundleDisplayName</key><string>RAM Monitor</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.2.2</string>
<key>CFBundleVersion</key><string>6</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
echo "$APP"
