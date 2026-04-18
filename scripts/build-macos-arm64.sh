#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script must be run on macOS." >&2
  exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "This script targets Apple Silicon (arm64) macOS hosts." >&2
  exit 1
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

require_command cargo
require_command flutter
require_command python3

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

min_macos_version="${MIN_MACOS_VERSION:-12.3}"
create_dmg="${CREATE_DMG:-1}"
app_path="flutter/build/macos/Build/Products/Release/RustDesk.app"

if [[ "$create_dmg" != "0" ]]; then
  require_command create-dmg
fi

version="$(python3 - <<'PY'
from pathlib import Path

for line in Path("Cargo.toml").read_text(encoding="utf-8").splitlines():
    if line.startswith("version"):
        print(line.split("=", 1)[1].strip().strip('"'))
        break
PY
)"

tmpdir="$(mktemp -d)"
restore() {
  cp "$tmpdir/Cargo.toml" Cargo.toml
  cp "$tmpdir/Podfile" flutter/macos/Podfile
  cp "$tmpdir/project.pbxproj" flutter/macos/Runner.xcodeproj/project.pbxproj
  rm -rf "$tmpdir"
}
trap restore EXIT

cp Cargo.toml "$tmpdir/Cargo.toml"
cp flutter/macos/Podfile "$tmpdir/Podfile"
cp flutter/macos/Runner.xcodeproj/project.pbxproj "$tmpdir/project.pbxproj"

sed -i '' -E "s/platform :osx, '.*'/platform :osx, '${min_macos_version}'/" flutter/macos/Podfile
sed -i '' -E "s/osx_minimum_system_version = \"[0-9]+\.[0-9]+\"/osx_minimum_system_version = \"${min_macos_version}\"/" Cargo.toml
sed -i '' -E "s/MACOSX_DEPLOYMENT_TARGET = [0-9]+\.[0-9]+;/MACOSX_DEPLOYMENT_TARGET = ${min_macos_version};/" flutter/macos/Runner.xcodeproj/project.pbxproj

export MACOSX_DEPLOYMENT_TARGET="$min_macos_version"

cargo build --release --features flutter,hwcodec,unix-file-copy-paste,screencapturekit
cp target/release/liblibrustdesk.dylib target/release/librustdesk.dylib

(
  cd flutter
  flutter build macos --release
)

cp -rf target/release/service "$app_path/Contents/MacOS/"

echo "App output: $repo_root/$app_path"

if [[ "$create_dmg" == "0" ]]; then
  exit 0
fi

dmg_name="rustdesk-${version}-aarch64.dmg"
rm -f "$dmg_name"
create-dmg \
  --icon "RustDesk.app" 200 190 \
  --hide-extension "RustDesk.app" \
  --window-size 800 400 \
  --app-drop-link 600 185 \
  "$dmg_name" \
  "$app_path"

echo "DMG output: $repo_root/$dmg_name"
