#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
macos_dir=${script_dir:h}
repo_dir=${macos_dir:h}
version=${1:-${TIBORESETSIGNAL_VERSION:-0.1.0}}
artifact_name="TiboResetSignal-macOS-$version"
stage_dir="$macos_dir/dist/$artifact_name"
dmg_path="$repo_dir/dist/$artifact_name.dmg"

TIBORESETSIGNAL_VERSION="$version" "$script_dir/build-macos.sh" >/dev/null

rm -rf "$stage_dir"
mkdir -p "$stage_dir" "$repo_dir/dist"
cp -R "$macos_dir/dist/Tibo Reset Signal.app" "$stage_dir/"
ln -s /Applications "$stage_dir/Applications"
cp "$repo_dir/LICENSE" "$stage_dir/LICENSE.txt"

rm -f "$dmg_path"
hdiutil create \
  -volname "TiboResetSignal $version" \
  -srcfolder "$stage_dir" \
  -format UDZO \
  -ov \
  "$dmg_path" >/dev/null

if [[ -n ${TIBORESETSIGNAL_SIGN_IDENTITY:-} ]]; then
  /usr/bin/codesign --force --timestamp --sign "$TIBORESETSIGNAL_SIGN_IDENTITY" "$dmg_path"
fi

if [[ -n ${TIBORESETSIGNAL_NOTARY_PROFILE:-} ]]; then
  xcrun notarytool submit "$dmg_path" --keychain-profile "$TIBORESETSIGNAL_NOTARY_PROFILE" --wait
  xcrun stapler staple "$dmg_path"
fi

echo "$dmg_path"
