#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
macos_dir=${script_dir:h}
app_name='Tibo Reset Signal'
bundle_dir="$macos_dir/dist/$app_name.app"
contents_dir="$bundle_dir/Contents"
version=${TIBORESETSIGNAL_VERSION:-0.1.0}
build_number=${TIBORESETSIGNAL_BUILD_NUMBER:-1}

cd "$macos_dir"
swift build -c release

rm -rf "$bundle_dir"

mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
cp "$macos_dir/.build/release/TiboResetSignal" "$contents_dir/MacOS/TiboResetSignal"
cp "$macos_dir/Resources/AppIcon.icns" "$contents_dir/Resources/AppIcon.icns"

/usr/libexec/PlistBuddy -c 'Add :CFBundleDisplayName string Tibo Reset Signal' "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleExecutable string TiboResetSignal' "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string AppIcon.icns' "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIdentifier string com.sundaynighttt.tibo-reset-signal' "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleInfoDictionaryVersion string 6.0' "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleName string TiboResetSignal' "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundlePackageType string APPL' "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $version" "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $build_number" "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :LSMinimumSystemVersion string 13.0' "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :LSUIElement bool true' "$contents_dir/Info.plist"
if [[ -n ${TIBORESETSIGNAL_SIGN_IDENTITY:-} ]]; then
  /usr/bin/codesign --force --deep --options runtime --timestamp --sign "$TIBORESETSIGNAL_SIGN_IDENTITY" "$bundle_dir"
else
  /usr/bin/codesign --force --deep --sign - "$bundle_dir"
fi

echo "$bundle_dir"
