#!/usr/bin/env bash
# Install local git hooks that run the same checks as CI before push.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$ROOT/.git/hooks"

if [[ ! -d "$ROOT/.git" ]]; then
  echo "error: not a git repository ($ROOT)" >&2
  exit 1
fi

mkdir -p "$HOOKS_DIR"

cat > "$HOOKS_DIR/pre-push" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
echo "pre-push: running scripts/verify.sh (same as CI)…"
exec "$ROOT/scripts/verify.sh"
HOOK

chmod +x "$HOOKS_DIR/pre-push"
chmod +x "$ROOT/scripts/verify.sh"

echo "Installed pre-push hook → scripts/verify.sh"
echo "Skip once with: git push --no-verify"
