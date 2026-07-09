#!/bin/bash
# Build rNitro-v6.1.1a.exe for website distribution (Windows x64).
# Requires .NET 8 SDK. Cross-compiles from macOS/Linux with EnableWindowsTargeting.
set -euo pipefail

VERSION="v4.2.1-Windows-Final-x86"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")/rnitro-windows-build"
OUT_DIR="$SCRIPT_DIR/publish-win-fd"
EXE_NAME="rNitro-${VERSION}.exe"

if ! command -v dotnet >/dev/null 2>&1; then
  if [[ -x "${HOME}/.dotnet/dotnet" ]]; then
    export DOTNET_ROOT="${HOME}/.dotnet"
    export PATH="${DOTNET_ROOT}:${PATH}"
  else
    echo "❌ .NET SDK not found. Install from https://dotnet.microsoft.com/download"
    exit 1
  fi
fi

# Extract latest C# source from the PowerShell installer
python3 - <<'PY' "$SCRIPT_DIR/install-rNitro-windows.ps1" "$BUILD_DIR/RNitro.cs"
import re, sys, pathlib
text = pathlib.Path(sys.argv[1]).read_text()
m = re.search(r"\$SOURCE = @'(.+?)'@", text, re.S)
pathlib.Path(sys.argv[2]).write_text(m.group(1).strip() + "\n")
PY

mkdir -p "$BUILD_DIR"
cp "$SCRIPT_DIR/../rnitro-windows-build/rNitro.csproj" "$BUILD_DIR/" 2>/dev/null || true

dotnet publish "$BUILD_DIR/rNitro.csproj" -c Release -o "$OUT_DIR"
cp "$OUT_DIR/rNitro.exe" "$SCRIPT_DIR/$EXE_NAME"

echo "✅ Created $SCRIPT_DIR/$EXE_NAME"
ls -lh "$SCRIPT_DIR/$EXE_NAME"
echo ""
echo "Note: framework-dependent build — requires .NET 8 Desktop Runtime on Windows."
echo "Users without it can use install-rNitro-windows.ps1 (.NET Framework 4.x, built into Win10/11)."