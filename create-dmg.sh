#!/bin/bash
# Build rNitro DMG for website distribution.
# Usage: bash create-dmg.sh [v7.0.1a-Final-arm64 | v8.1.1-Beta-arm64]
set -euo pipefail

VERSION="${1:-v8.1.1-Beta-arm64}"
DMG_NAME="rNitro-${VERSION}.dmg"
INSTALLER_NAME="rNitro-${VERSION}.sh"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/rnitro-dmg.XXXXXXXX")"
APP_SRC="${HOME}/Applications/rNitro.app"
APP_STAGE="$STAGE/rNitro.app"

cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

sign_app_bundle() {
  local app="$1"
  xattr -cr "$app" 2>/dev/null || true
  local exe="$app/Contents/MacOS/rNitro"
  if [[ ! -f "$exe" ]]; then
    echo "❌ Cannot sign: missing $exe"
    return 1
  fi
  codesign --force --sign - --timestamp=none "$exe"
  codesign --force --sign - --timestamp=none "$app"
}

if [[ ! -d "$APP_SRC" ]]; then
  echo "❌ $APP_SRC not found. Run: bash $SCRIPT_DIR/$INSTALLER_NAME"
  exit 1
fi

if [[ ! -f "$SCRIPT_DIR/$INSTALLER_NAME" ]]; then
  echo "❌ $SCRIPT_DIR/$INSTALLER_NAME not found."
  exit 1
fi

echo "📦 Staging DMG contents..."
ditto --noqtn "$APP_SRC" "$APP_STAGE"
xattr -cr "$STAGE" 2>/dev/null || true

echo "🔏 Re-signing staged app (fixes invalid signatures from post-build plist edits)..."
sign_app_bundle "$APP_STAGE"
codesign --verify --deep --strict "$APP_STAGE"

cp "$SCRIPT_DIR/$INSTALLER_NAME" "$STAGE/"
cp "$SCRIPT_DIR/VarelaRound.ttf" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

cat > "$STAGE/Install rNitro.command" << EOF
#!/bin/bash
cd "\$(dirname "\$0")"
xattr -cr . 2>/dev/null
chmod +x "$INSTALLER_NAME"
./"$INSTALLER_NAME"
EOF
chmod +x "$STAGE/Install rNitro.command"

cat > "$STAGE/Fix and Open rNitro.command" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
xattr -cr "rNitro.app" 2>/dev/null
if [[ ! -d "$HOME/Applications/rNitro.app" ]]; then
  ditto --noqtn "rNitro.app" "$HOME/Applications/rNitro.app"
  xattr -cr "$HOME/Applications/rNitro.app" 2>/dev/null
  sign_app_bundle() {
    local app="$1"
    xattr -cr "$app" 2>/dev/null || true
    codesign --force --sign - --timestamp=none "$app/Contents/MacOS/rNitro"
    codesign --force --sign - --timestamp=none "$app"
  }
  sign_app_bundle "$HOME/Applications/rNitro.app" 2>/dev/null || true
fi
xattr -cr "$HOME/Applications/rNitro.app" 2>/dev/null
open "$HOME/Applications/rNitro.app"
EOF
chmod +x "$STAGE/Fix and Open rNitro.command"

rm -f "$SCRIPT_DIR/$DMG_NAME"
hdiutil create -volname "rNitro" -srcfolder "$STAGE" -ov -format UDZO "$SCRIPT_DIR/$DMG_NAME"
xattr -cr "$SCRIPT_DIR/$DMG_NAME" 2>/dev/null || true

echo "✅ Created $SCRIPT_DIR/$DMG_NAME"
echo "   Recommended: double-click 'Install rNitro.command' inside the DMG."
ls -lh "$SCRIPT_DIR/$DMG_NAME"