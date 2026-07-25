#!/bin/bash
cd "$(dirname "$0")"
ROOT="$PWD"
APP="$ROOT/dist/DeezSpacesaver.app"
BUNDLE_ID="io.worldbuild.DeezSpacesaver"
EXIT_CODE=0

show_dialog() {
  osascript -e "display dialog \"$1\" buttons {\"OK\"} default button \"OK\" with title \"DeezSpacesaver\" with icon caution" >/dev/null 2>&1 || true
}

quit_app() {
  if ! pgrep -x DeezSpacesaver >/dev/null 2>&1; then
    return 0
  fi

  osascript -e "tell application id \"$BUNDLE_ID\" to quit" 2>/dev/null || true

  for _ in {1..10}; do
    if ! pgrep -x DeezSpacesaver >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.5
  done

  if pgrep -x DeezSpacesaver >/dev/null 2>&1; then
    pkill -x DeezSpacesaver 2>/dev/null || true
    sleep 0.5
  fi
}

quit_app

osascript -e 'display notification "Building DeezSpacesaver…" with title "DeezSpacesaver"' >/dev/null 2>&1 || true
if ! "$ROOT/scripts/build-local.sh"; then
  show_dialog "DeezSpacesaver could not be rebuilt, so the previous app was not opened. Review the build error in this window."
  echo ""
  echo "Press Enter to close..."
  read
  exit 1
fi

if [[ ! -d "$APP" ]]; then
  show_dialog "DeezSpacesaver was not found after building. Download the app from GitHub Releases instead."
  echo ""
  echo "Press Enter to close..."
  read
  exit 1
fi

quit_app

open -n "$APP"
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
  show_dialog "Could not open DeezSpacesaver. If this is your first launch, try right-clicking the app and choosing Open."
  echo ""
  echo "Press Enter to close..."
  read
  exit $EXIT_CODE
fi

if [[ "${DEEZSPACESAVER_KEEP_TERMINAL_OPEN:-0}" != "1" ]]; then
  osascript -e 'tell application "Terminal" to close front window' 2>/dev/null || exit 0
fi
