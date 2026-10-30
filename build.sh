#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

version="${VERSION:-$(<version.txt)}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Expected a version such as 0.1.0." >&2
  exit 1
fi

app="$PWD/.build/LP Clock.app"
mkdir -p "$app/Contents/MacOS"
if [[ "${UNIVERSAL:-0}" == 1 ]]; then
  binaries=()
  for arch in arm64 x86_64; do
    scratch=".build/release-$arch"
    swift build -c release --arch "$arch" --scratch-path "$scratch"
    binaries+=("$(swift build -c release --arch "$arch" --scratch-path "$scratch" --show-bin-path)/LPClock")
  done
  lipo -create "${binaries[@]}" -output "$app/Contents/MacOS/LPClock"
else
  swift build -c release
  cp "$(swift build -c release --show-bin-path)/LPClock" "$app/Contents/MacOS/LPClock"
fi

cp Info.plist "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $version" "$app/Contents/Info.plist"
codesign --force --sign - "$app"
echo "$app"
