#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
configuration="${1:-debug}"
build_dir="$repo_root/.build/$configuration"
app_dir="$build_dir/Buttons.app"
version="${BUTTONS_VERSION:-0.1.0}"
build_number="${BUTTONS_BUILD_NUMBER:-}"

if [ -z "$build_number" ]; then
  build_number="$(git -C "$repo_root" rev-list --count HEAD 2>/dev/null || echo 1)"
fi

cd "$repo_root"
swift build --configuration "$configuration" --product Buttons
swift build --configuration "$configuration" --product ButtonsComputerUseRuntime

rm -rf "$app_dir"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources" "$app_dir/Contents/Helpers"
cp "$build_dir/Buttons" "$app_dir/Contents/MacOS/Buttons"
cp "$build_dir/ButtonsComputerUseRuntime" "$app_dir/Contents/Helpers/ButtonsComputerUseRuntime"
/usr/bin/swift "$repo_root/scripts/render-app-icon.swift" "$app_dir/Contents/Resources/Buttons.icns"

cat > "$app_dir/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>Buttons</string>
  <key>CFBundleExecutable</key>
  <string>Buttons</string>
  <key>CFBundleIconFile</key>
  <string>Buttons</string>
  <key>CFBundleIconName</key>
  <string>Buttons</string>
  <key>CFBundleIdentifier</key>
  <string>ai.companion.buttons</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Buttons</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$version</string>
  <key>CFBundleVersion</key>
  <string>$build_number</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSScreenCaptureUsageDescription</key>
  <string>Buttons needs screen recording access so button agents can see the current screen when running computer-use workflows.</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$app_dir" >/dev/null
echo "$app_dir"
