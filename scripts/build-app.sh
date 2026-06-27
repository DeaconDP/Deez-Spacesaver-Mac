#!/usr/bin/env bash
# Shared xcodebuild step — outputs to dist/DeezSpacesaver.app
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIGURATION="${1:-Debug}"
DERIVED="$ROOT/build/DerivedData"
PRODUCT="$DERIVED/Build/Products/$CONFIGURATION/DeezSpacesaver.app"
DIST="$ROOT/dist"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

if [[ ! -d "$DEVELOPER_DIR" ]]; then
  echo "Xcode not found at $DEVELOPER_DIR" >&2
  exit 1
fi

echo "→ Regenerating Xcode project"
python3 "$ROOT/scripts/generate-xcodeproj.py"

echo "→ Building DeezSpacesaver ($CONFIGURATION)"
xcodebuild \
  -project DeezSpacesaver.xcodeproj \
  -scheme DeezSpacesaver \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED" \
  build

mkdir -p "$DIST"
rm -rf "$DIST/DeezSpacesaver.app"
cp -R "$PRODUCT" "$DIST/DeezSpacesaver.app"

echo "→ Built: $DIST/DeezSpacesaver.app"
