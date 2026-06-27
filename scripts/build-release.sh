#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIGURATION="${1:-Release}"
"$ROOT/scripts/build-app.sh" "$CONFIGURATION"
"$ROOT/scripts/create-dmg.sh"

echo "Done."
