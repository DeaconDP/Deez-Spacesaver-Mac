#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENV_FILE="${NOTARIZE_ENV:-$ROOT/notarize.env}"
APP="$ROOT/dist/Deez-Spacesaver-Mac.app"
DMG="$ROOT/dist/Deez-Spacesaver-Mac.dmg"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Create $ENV_FILE with:"
  echo "  APPLE_ID=your@email.com"
  echo "  APPLE_TEAM_ID=XXXXXXXXXX"
  echo "  APPLE_APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx"
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

: "${APPLE_ID:?APPLE_ID required}"
: "${APPLE_TEAM_ID:?APPLE_TEAM_ID required}"
: "${APPLE_APP_SPECIFIC_PASSWORD:?APPLE_APP_SPECIFIC_PASSWORD required}"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

if [[ ! -d "$APP" ]]; then
  echo "Run scripts/build-release.sh first"
  exit 1
fi

echo "→ Signing app"
codesign --force --deep --options runtime --sign "Developer ID Application: ${SIGN_IDENTITY:-$APPLE_TEAM_ID}" "$APP"

SUBMIT_PATH="$APP"
if [[ -f "$DMG" ]]; then
  echo "→ Signing DMG"
  codesign --force --sign "Developer ID Application: ${SIGN_IDENTITY:-$APPLE_TEAM_ID}" "$DMG"
  SUBMIT_PATH="$DMG"
fi

echo "→ Notarizing $SUBMIT_PATH"
xcrun notarytool submit "$SUBMIT_PATH" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
  --team-id "$APPLE_TEAM_ID" \
  --wait

if [[ -f "$DMG" ]]; then
  echo "→ Stapling DMG"
  xcrun stapler staple "$DMG"
else
  echo "→ Stapling app"
  xcrun stapler staple "$APP"
fi

echo "Notarization complete."
