#!/bin/bash
# Install rNitro terminal CLI to ~/bin/rnitro (or /usr/local/bin with sudo).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/rnitro"
NAME="rnitro"

if [[ ! -x "$SRC" ]] && [[ -f "$SRC" ]]; then
  chmod +x "$SRC"
fi

install_to() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  ln -sf "$SRC" "$dest"
  echo "✅ Linked $SRC → $dest"
}

if [[ "${1:-}" == "--system" ]] && [[ -w /usr/local/bin ]]; then
  install_to "/usr/local/bin/$NAME"
elif [[ "${1:-}" == "--system" ]]; then
  echo "Need write access to /usr/local/bin — run: sudo $0 --system"
  exit 1
else
  install_to "$HOME/bin/$NAME"
  PATH_LINE='export PATH="$HOME/bin:$PATH"'
  PROFILE=""
  for candidate in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bash_profile"; do
    if [[ -f "$candidate" ]] || [[ "$candidate" == "$HOME/.zshrc" ]]; then
      PROFILE="$candidate"
      break
    fi
  done
  if [[ -n "$PROFILE" ]]; then
    touch "$PROFILE"
    if ! grep -qF '$HOME/bin' "$PROFILE" 2>/dev/null; then
      {
        echo ""
        echo "# rNitro CLI"
        echo "$PATH_LINE"
      } >> "$PROFILE"
      echo "✅ Added ~/bin to PATH in $PROFILE"
      echo "   Restart Terminal or run: source $PROFILE"
    fi
  elif [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo ""
    echo "Add to your shell profile:"
    echo "  $PATH_LINE"
  fi
fi

echo ""
echo "Run:  rnitro"
echo "Tip:  pip3 install psutil   # smoother CPU/process stats on macOS"