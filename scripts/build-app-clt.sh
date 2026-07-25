#!/usr/bin/env bash
# Build a development app bundle using Apple Command Line Tools only.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIGURATION="${1:-Debug}"
MINIMUM_MACOS="14.4"
BUILD_ROOT="$ROOT/build/CommandLineTools"
STAGING_APP="$BUILD_ROOT/DeezSpacesaver.app"
APP_CONTENTS="$STAGING_APP/Contents"
APP_EXECUTABLE="$APP_CONTENTS/MacOS/DeezSpacesaver"
COMPILED_EXECUTABLE="$BUILD_ROOT/DeezSpacesaver"
APP_RESOURCES="$APP_CONTENTS/Resources"
DIST="$ROOT/dist"
DIST_APP="$DIST/DeezSpacesaver.app"
DIST_NEW="$DIST/.DeezSpacesaver.app.new"

SWIFTC="${SWIFTC:-$(xcrun --find swiftc 2>/dev/null || true)}"
SDK_PATH="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)}"

if [[ -z "$SWIFTC" || ! -x "$SWIFTC" ]]; then
  echo "error: Swift compiler not found in Apple Command Line Tools." >&2
  exit 1
fi

if [[ -z "$SDK_PATH" || ! -d "$SDK_PATH" ]]; then
  echo "error: macOS SDK not found in Apple Command Line Tools." >&2
  exit 1
fi

SOURCES=()
while IFS= read -r source; do
  SOURCES+=("$source")
done < <(
  python3 - "$ROOT/DeezSpacesaver" <<'PY'
import os
import sys

source_root = sys.argv[1]
for base, _, files in os.walk(source_root):
    for filename in sorted(files):
        if filename.endswith(".swift"):
            print(os.path.join(base, filename))
PY
)

if [[ ${#SOURCES[@]} -eq 0 ]]; then
  echo "error: no Swift sources found." >&2
  exit 1
fi

rm -rf "$STAGING_APP"
rm -f "$COMPILED_EXECUTABLE"
rm -rf "$COMPILED_EXECUTABLE.dSYM"
mkdir -p "$APP_CONTENTS/MacOS" "$APP_RESOURCES"

ARCH="$(uname -m)"
OPTIMIZATION_FLAGS=(-Onone -g)
if [[ "$CONFIGURATION" == "Release" ]]; then
  OPTIMIZATION_FLAGS=(-O)
fi

echo "→ Compiling DeezSpacesaver with Apple Command Line Tools"
"$SWIFTC" \
  -sdk "$SDK_PATH" \
  -target "${ARCH}-apple-macosx${MINIMUM_MACOS}" \
  -swift-version 5 \
  -strict-concurrency=complete \
  -parse-as-library \
  -module-name DeezSpacesaver \
  "${OPTIMIZATION_FLAGS[@]}" \
  "${SOURCES[@]}" \
  -o "$COMPILED_EXECUTABLE"
cp "$COMPILED_EXECUTABLE" "$APP_EXECUTABLE"
chmod +x "$APP_EXECUTABLE"

echo "→ Writing app metadata"
python3 - \
  "$ROOT/DeezSpacesaver/Info.plist" \
  "$APP_CONTENTS/Info.plist" \
  "$MINIMUM_MACOS" <<'PY'
import plistlib
import sys

source, destination, minimum_macos = sys.argv[1:]
with open(source, "rb") as handle:
    info = plistlib.load(handle)

info["CFBundleExecutable"] = "DeezSpacesaver"
info["CFBundleIdentifier"] = "io.worldbuild.DeezSpacesaver"
info["CFBundleName"] = "DeezSpacesaver"
info["CFBundleDisplayName"] = "DeezSpacesaver"
info["CFBundleIconFile"] = "AppIcon"
info["LSMinimumSystemVersion"] = minimum_macos

with open(destination, "wb") as handle:
    plistlib.dump(info, handle, sort_keys=True)
PY
printf 'APPL????' > "$APP_CONTENTS/PkgInfo"

echo "→ Building app icon"
GENERATED_ICONSET="$BUILD_ROOT/AppIcon.appiconset"
rm -rf "$GENERATED_ICONSET"
swift \
  "$ROOT/scripts/generate-app-icon.swift" \
  "$GENERATED_ICONSET" >/dev/null
ICONSET="$BUILD_ROOT/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for icon in "$GENERATED_ICONSET/"*.png; do
  cp "$icon" "$ICONSET/"
done
if ! iconutil -c icns "$ICONSET" -o "$APP_RESOURCES/AppIcon.icns"; then
  if [[ -f "$DIST_APP/Contents/Resources/AppIcon.icns" ]]; then
    echo "warning: iconutil rejected the generated iconset; preserving the previous development icon." >&2
    cp "$DIST_APP/Contents/Resources/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
  else
    echo "warning: app icon could not be generated; continuing with the system default icon." >&2
    python3 - "$APP_CONTENTS/Info.plist" <<'PY'
import plistlib
import sys

path = sys.argv[1]
with open(path, "rb") as handle:
    info = plistlib.load(handle)
info.pop("CFBundleIconFile", None)
with open(path, "wb") as handle:
    plistlib.dump(info, handle, sort_keys=True)
PY
  fi
fi

echo "→ Signing development app"
codesign \
  --force \
  --sign - \
  --timestamp=none \
  --entitlements "$ROOT/DeezSpacesaver/DeezSpacesaver.entitlements" \
  "$STAGING_APP"
codesign --verify --deep --strict "$STAGING_APP"

mkdir -p "$DIST"
rm -rf "$DIST_NEW"
mv "$STAGING_APP" "$DIST_NEW"
rm -rf "$DIST_APP"
mv "$DIST_NEW" "$DIST_APP"
touch "$DIST_APP"

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
if [[ -x "$LSREGISTER" ]]; then
  "$LSREGISTER" -f -R -trusted "$DIST_APP" >/dev/null
fi

echo "→ Built: $DIST_APP"
