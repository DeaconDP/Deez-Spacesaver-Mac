#!/usr/bin/env bash
# Shared xcodebuild step — outputs to dist/Deez-Spacesaver-Mac.app
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIGURATION="${1:-Debug}"
DERIVED="$ROOT/build/DerivedData"
PRODUCT="$DERIVED/Build/Products/$CONFIGURATION/Deez-Spacesaver-Mac.app"
DIST="$ROOT/dist"

resolve_developer_dir() {
  local selected default="/Applications/Xcode.app/Contents/Developer"
  selected="$(xcode-select -p 2>/dev/null || true)"
  if [[ -n "$selected" && -d "$selected" ]] && DEVELOPER_DIR="$selected" xcodebuild -version >/dev/null 2>&1; then
    echo "$selected"
    return 0
  fi
  if [[ -d "$default" ]] && DEVELOPER_DIR="$default" xcodebuild -version >/dev/null 2>&1; then
    echo "$default"
    return 0
  fi
  return 1
}

if [[ -z "${DEVELOPER_DIR:-}" ]] || [[ ! -d "${DEVELOPER_DIR:-}" ]]; then
  DEVELOPER_DIR="$(resolve_developer_dir || true)"
fi
export DEVELOPER_DIR

if [[ -z "${DEVELOPER_DIR:-}" ]] || ! xcodebuild -version >/dev/null 2>&1; then
  echo "→ Full Xcode unavailable; using Apple Command Line Tools"
  exec "$ROOT/scripts/build-app-clt.sh" "$CONFIGURATION"
fi

echo "→ Regenerating Xcode project"
python3 "$ROOT/scripts/generate-xcodeproj.py"

echo "→ Regenerating app icons"
swift "$ROOT/scripts/generate-app-icon.swift"

echo "→ Building Deez-Spacesaver-Mac ($CONFIGURATION)"
set +e
xcodebuild \
  -project DeezSpacesaver.xcodeproj \
  -scheme DeezSpacesaver \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED" \
  build
BUILD_EXIT=$?
set -e

if [[ $BUILD_EXIT -ne 0 ]]; then
  exit $BUILD_EXIT
fi

mkdir -p "$DIST"
rm -rf "$DIST/Deez-Spacesaver-Mac.app"
cp -R "$PRODUCT" "$DIST/Deez-Spacesaver-Mac.app"
touch "$DIST/Deez-Spacesaver-Mac.app"

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
if [[ -x "$LSREGISTER" ]]; then
  "$LSREGISTER" -f -R -trusted "$DIST/Deez-Spacesaver-Mac.app" >/dev/null
fi

echo "→ Built: $DIST/Deez-Spacesaver-Mac.app"
