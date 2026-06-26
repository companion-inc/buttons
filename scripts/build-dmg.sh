#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
configuration="${1:-release}"
version="${BUTTONS_VERSION:-0.1.0}"
build_number="${BUTTONS_BUILD_NUMBER:-}"
dist_dir="$repo_root/dist"
staging_dir="$repo_root/.build/dmg/Buttons"
dmg_path="$dist_dir/Buttons-$version.dmg"

if [ -z "$build_number" ]; then
  build_number="$(git -C "$repo_root" rev-list --count HEAD 2>/dev/null || echo 1)"
fi

rm -rf "$staging_dir"
mkdir -p "$staging_dir" "$dist_dir"

BUTTONS_VERSION="$version" BUTTONS_BUILD_NUMBER="$build_number" "$repo_root/scripts/package-buttons-app.sh" "$configuration" >/dev/null

cp -R "$repo_root/.build/$configuration/Buttons.app" "$staging_dir/Buttons.app"
ln -s /Applications "$staging_dir/Applications"

rm -f "$dmg_path"
hdiutil create \
  -volname "Buttons" \
  -srcfolder "$staging_dir" \
  -ov \
  -format UDZO \
  "$dmg_path" >/dev/null

echo "$dmg_path"
