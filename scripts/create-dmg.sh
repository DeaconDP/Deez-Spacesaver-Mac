#!/usr/bin/env bash
# Create dist/DeezSpacesaver.dmg from dist/DeezSpacesaver.app
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/DeezSpacesaver.app"
DMG="$ROOT/dist/DeezSpacesaver.dmg"
STAGING="$ROOT/build/dmg-staging"

if [[ ! -d "$APP" ]]; then
  echo "Missing $APP — run build-app.sh first" >&2
  exit 1
fi

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

create_dmg_hdiutil() {
  local temp_dmg="$ROOT/build/DeezSpacesaver-temp.dmg"
  rm -f "$temp_dmg"
  hdiutil create -volname "DeezSpacesaver" -srcfolder "$STAGING" -ov -format UDRW "$temp_dmg"
  hdiutil convert "$temp_dmg" -format UDZO -imagekey zlib-level=9 -o "$DMG"
  rm -f "$temp_dmg"
}

if command -v create-dmg >/dev/null 2>&1; then
  if create-dmg \
    --volname "DeezSpacesaver" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --app-drop-link 425 185 \
    "$DMG" \
    "$STAGING" 2>/dev/null; then
    :
  else
    rm -f "$DMG"
    create_dmg_hdiutil
  fi
else
  create_dmg_hdiutil
fi

rm -rf "$STAGING"
echo "→ DMG: $DMG"
