#!/bin/bash
cd "$(dirname "$0")"
ROOT="$PWD"
APP="$ROOT/dist/DeezSpacesaver.app"
EXECUTABLE="$APP/Contents/MacOS/DeezSpacesaver"
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

source_is_newer_than_binary() {
  local src_mtime binary_mtime
  src_mtime=$(stat -f "%m" "$1" 2>/dev/null || echo 0)
  binary_mtime=$(stat -f "%m" "$EXECUTABLE" 2>/dev/null || echo 0)
  [[ "$src_mtime" -gt "$binary_mtime" ]]
}

needs_build() {
  if [[ ! -f "$EXECUTABLE" ]]; then
    return 0
  fi

  while IFS= read -r -d '' src; do
    if source_is_newer_than_binary "$src"; then
      return 0
    fi
  done < <(find "$ROOT/DeezSpacesaver" \( -name '*.swift' -o -path '*/Assets.xcassets/*' \) -print0 2>/dev/null)

  local plist="$ROOT/DeezSpacesaver/Info.plist"
  local entitlements="$ROOT/DeezSpacesaver/DeezSpacesaver.entitlements"
  if [[ -f "$plist" ]] && source_is_newer_than_binary "$plist"; then
    return 0
  fi
  if [[ -f "$entitlements" ]] && source_is_newer_than_binary "$entitlements"; then
    return 0
  fi

  return 1
}

if [[ ! -d "/Applications/Xcode.app/Contents/Developer" ]]; then
  show_dialog "Xcode is required to build DeezSpacesaver from source. Download the ready-made app from the GitHub Releases page instead."
  echo ""
  echo "Press Enter to close..."
  read
  exit 1
fi

export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

quit_app

if needs_build; then
  osascript -e 'display notification "Building DeezSpacesaver…" with title "DeezSpacesaver"' >/dev/null 2>&1 || true
  if ! "$ROOT/scripts/build-local.sh"; then
    show_dialog "DeezSpacesaver could not be built. Try opening the project in Xcode, or download the app from GitHub Releases."
    echo ""
    echo "Press Enter to close..."
    read
    exit 1
  fi
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

osascript -e 'tell application "Terminal" to close front window' 2>/dev/null || exit 0
