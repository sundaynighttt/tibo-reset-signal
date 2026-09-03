#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
repo_dir=${script_dir:h}
source_png="$repo_dir/ios/TiboResetSignalApp/Assets.xcassets/AppIcon.appiconset/TiboResetSignal-AppIcon.png"
iconset_dir=$(mktemp -d)/TiboResetSignal.iconset
mkdir -p "${source_png:h}" "$iconset_dir"

swift "$script_dir/generate-icon.swift" "$source_png"
resized_png=$(mktemp).png
sips -z 1024 1024 "$source_png" --out "$resized_png" >/dev/null
mv "$resized_png" "$source_png"

for spec in \
  '16 icon_16x16.png' \
  '32 icon_16x16@2x.png' \
  '32 icon_32x32.png' \
  '64 icon_32x32@2x.png' \
  '128 icon_128x128.png' \
  '256 icon_128x128@2x.png' \
  '256 icon_256x256.png' \
  '512 icon_256x256@2x.png' \
  '512 icon_512x512.png' \
  '1024 icon_512x512@2x.png'; do
  size=${spec%% *}
  name=${spec#* }
  sips -z "$size" "$size" "$source_png" --out "$iconset_dir/$name" >/dev/null
done

iconutil -c icns "$iconset_dir" -o "$repo_dir/macos/Resources/AppIcon.icns"
