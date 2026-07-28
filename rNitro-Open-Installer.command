#!/bin/bash
# Opens an rNitro PKG when macOS Gatekeeper blocks a double-click.
# Usage: double-click this file after downloading the PKG, or drag the PKG onto it.
set -euo pipefail

pick_pkg() {
  local candidate
  for candidate in \
    "$HOME/Downloads/rNitro-v8.1.1-Beta-arm64.pkg" \
    "$HOME/Downloads/rNitro-v8.1.1-Beta-arm64 (1).pkg" \
    "$HOME/Downloads/rNitro-v7.0.1a-Final-arm64.pkg" \
    "$HOME/Downloads/rNitro-v7.0.1a-Final-arm64 (1).pkg"
  do
    if [[ -f "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

if [[ $# -ge 1 && -f "$1" ]]; then
  PKG="$1"
else
  PKG="$(pick_pkg || true)"
fi

if [[ -z "${PKG:-}" || ! -f "$PKG" ]]; then
  osascript -e 'display alert "rNitro PKG not found" message "Download the Stable or Beta PKG first, then run this helper again." as warning'
  exit 1
fi

xattr -cr "$PKG" 2>/dev/null || true
open "$PKG"
osascript -e 'display notification "Opening rNitro installer…" with title "rNitro"'