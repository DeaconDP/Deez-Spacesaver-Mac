#!/usr/bin/env bash
# Full CI parity check: regenerate project, build, and run unit tests.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED="$ROOT/build/DerivedData"
PROJECT="$ROOT/DeezSpacesaver.xcodeproj"
SCHEME="DeezSpacesaver"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

if [[ ! -d "$DEVELOPER_DIR" ]]; then
  echo "error: Xcode not found at $DEVELOPER_DIR" >&2
  echo "Install Xcode or set DEVELOPER_DIR to your Xcode.app/Contents/Developer path." >&2
  exit 1
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "error: xcodebuild is not usable (check xcode-select / DEVELOPER_DIR)" >&2
  exit 1
fi

echo "→ Regenerating Xcode project"
python3 "$ROOT/scripts/generate-xcodeproj.py"

echo "→ Building $SCHEME ($CONFIGURATION)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED" \
  build

echo "→ Running unit tests"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED" \
  -destination 'platform=macOS' \
  test

echo "✓ verify passed"
