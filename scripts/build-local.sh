#!/usr/bin/env bash
# Debug build for local development / run.command
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/scripts/build-app.sh" Debug
