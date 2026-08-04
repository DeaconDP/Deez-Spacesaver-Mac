#!/bin/bash
cd "$(dirname "$0")"
ROOT="$PWD"
APP="$ROOT/dist/Deez-Spacesaver-Mac.app"
BUNDLE_ID="io.worldbuild.DeezSpacesaver"
EXIT_CODE=0

show_dialog() {
  osascript -e "display dialog \"$1\" buttons {\"OK\"} default button \"OK\" with title \"Deez-Spacesaver-Mac\" with icon caution" >/dev/null 2>&1 || true
}

quit_app() {
  if ! pgrep -x "Deez-Spacesaver-Mac" >/dev/null 2>&1; then
    return 0
  fi

  osascript -e "tell application id \"$BUNDLE_ID\" to quit" 2>/dev/null || true

  for _ in {1..10}; do
    if ! pgrep -x "Deez-Spacesaver-Mac" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.5
  done

  if pgrep -x "Deez-Spacesaver-Mac" >/dev/null 2>&1; then
    pkill -x "Deez-Spacesaver-Mac" 2>/dev/null || true
    sleep 0.5
  fi
}

quit_app

osascript -e 'display notification "Building Deez-Spacesaver-Mac…" with title "Deez-Spacesaver-Mac"' >/dev/null 2>&1 || true
if ! "$ROOT/scripts/build-local.sh"; then
  show_dialog "Deez-Spacesaver-Mac could not be rebuilt, so the previous app was not opened. Review the build error in this window."
  echo ""
  echo "Press Enter to close..."
  read
  exit 1
fi

if [[ ! -d "$APP" ]]; then
  show_dialog "Deez-Spacesaver-Mac was not found after building. Download the app from GitHub Releases instead."
  echo ""
  echo "Press Enter to close..."
  read
  exit 1
fi

quit_app

open -n "$APP"
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
  show_dialog "Could not open Deez-Spacesaver-Mac. If this is your first launch, try right-clicking the app and choosing Open."
  echo ""
  echo "Press Enter to close..."
  read
  exit $EXIT_CODE
fi

if [[ "${DEEZSPACESAVER_KEEP_TERMINAL_OPEN:-0}" != "1" ]]; then
  osascript -e 'tell application "Terminal" to close front window' 2>/dev/null || exit 0
fi
