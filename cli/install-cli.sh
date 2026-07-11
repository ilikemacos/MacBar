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
  if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo ""
    echo "Add to your shell profile:"
    echo '  export PATH="$HOME/bin:$PATH"'
  fi
fi

echo ""
echo "Run:  rnitro"
echo "Tip:  pip3 install psutil   # smoother CPU/process stats on macOS"