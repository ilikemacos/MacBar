#!/usr/bin/env bash
# rNitro Linux installer — v0.1-Linux-Beta-Pre-release-x64
set -euo pipefail

INSTALL_ROOT="${HOME}/.local/share/rnitro"
VENV="${INSTALL_ROOT}/venv"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_DIR="${HOME}/.local/share/applications"
AUTOSTART_DIR="${HOME}/.config/autostart"

echo "=== rNitro Linux installer ==="

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1"; exit 1; }
}

need python3

PYVER="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
python3 -c 'import sys; exit(0 if sys.version_info >= (3, 10) else 1)' || {
  echo "Python 3.10+ required (found ${PYVER})"
  exit 1
}

python3 -c "import gi; gi.require_version('Gtk','4.0'); gi.require_version('Adw','1')" 2>/dev/null || {
  echo "Install GTK4 + libadwaita + PyGObject:"
  echo "  Debian/Ubuntu: sudo apt install python3-gi python3-venv gir1.2-gtk-4.0 gir1.2-adw-1"
  echo "  Fedora:        sudo dnf install python3-gobject gtk4 libadwaita"
  echo "  Arch:          sudo pacman -S python-gobject gtk4 libadwaita"
  exit 1
}

if [[ ! -d "${SCRIPT_DIR}/linux/rnitro" ]]; then
  echo "Missing package at ${SCRIPT_DIR}/linux/rnitro"
  exit 1
fi

mkdir -p "${INSTALL_ROOT}"
rm -rf "${INSTALL_ROOT}/linux"
cp -R "${SCRIPT_DIR}/linux" "${INSTALL_ROOT}/linux"

if [[ ! -d "${VENV}" ]]; then
  python3 -m venv "${VENV}"
fi
# shellcheck disable=SC1091
source "${VENV}/bin/activate"
pip install -q --upgrade pip
pip install -q psutil || echo "Note: psutil not installed — rNitro will use /proc fallback."

SITE_PACKAGES="${VENV}/lib/python${PYVER}/site-packages"
mkdir -p "${SITE_PACKAGES}"
rm -rf "${SITE_PACKAGES}/rnitro"
cp -R "${INSTALL_ROOT}/linux/rnitro" "${SITE_PACKAGES}/rnitro"

mkdir -p "${DESKTOP_DIR}"
cat > "${DESKTOP_DIR}/rnitro.desktop" <<EOF
[Desktop Entry]
Name=rNitro
Comment=Linux system monitor
Exec=${VENV}/bin/python3 -m rnitro
Path=${INSTALL_ROOT}
Icon=utilities-system-monitor
Terminal=false
Type=Application
Categories=System;Monitor;
StartupWMClass=net.getrnitro.linux
EOF

if [[ "${RNITRO_AUTOSTART:-}" == "1" ]] || [[ "${1:-}" == "--autostart" ]]; then
  mkdir -p "${AUTOSTART_DIR}"
  cp "${DESKTOP_DIR}/rnitro.desktop" "${AUTOSTART_DIR}/rnitro.desktop"
  echo "Autostart enabled."
elif [[ -t 0 ]] && [[ "${RNITRO_NO_PROMPT:-}" != "1" ]]; then
  read -r -p "Enable autostart on login? [y/N] " ans || ans="n"
  if [[ "${ans}" =~ ^[Yy]$ ]]; then
    mkdir -p "${AUTOSTART_DIR}"
    cp "${DESKTOP_DIR}/rnitro.desktop" "${AUTOSTART_DIR}/rnitro.desktop"
    echo "Autostart enabled."
  fi
fi

echo ""
echo "Installed to ${INSTALL_ROOT}"
echo "Launch: ${VENV}/bin/python3 -m rnitro"
echo "Optional tray icon: sudo apt install gir1.2-ayatanaappindicator3-0.1"
echo ""

cd "${INSTALL_ROOT}"
exec "${VENV}/bin/python3" -m rnitro