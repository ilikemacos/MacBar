#!/bin/bash
set -euo pipefail
SITE="/Users/mehmeh/rnitro-site-work/rnitro-site"
INSTALLER="$SITE/install-rNitro.sh"
RELEASE_SH="$SITE/rNitro-v6.2.4-Final-arm64.sh"

echo "=== Step 1: Compute hash ==="
HASH=$(sed 's/^EXPECTED_HASH=.*/EXPECTED_HASH="MASKED"/' "$INSTALLER" | shasum -a 256 | awk '{print $1}')
echo "Computed hash: $HASH"

echo "=== Step 2: Update EXPECTED_HASH in install-rNitro.sh ==="
sed -i '' "s/^EXPECTED_HASH=.*/EXPECTED_HASH=\"$HASH\"/" "$INSTALLER"

echo "=== Step 3: Update index.html sha-hash and copyHash() ==="
INDEX="$SITE/index.html"
sed -i '' "s|167d0d490ee8bf0699456ccdb06f1df24a89728ed59f1121afb495139416567c|$HASH|g" "$INDEX"

echo "=== Step 4: Copy install-rNitro.sh to rNitro-v6.2.4-Final-arm64.sh ==="
cp "$INSTALLER" "$RELEASE_SH"
chmod +x "$RELEASE_SH"

echo "=== Step 5: Run installer ==="
bash "$RELEASE_SH"

echo "=== Step 6: Update create-dmg.sh and run it ==="
DMG_SCRIPT="$SITE/create-dmg.sh"
sed -i '' 's/^VERSION=.*/VERSION="v6.2.4-Final-arm64"/' "$DMG_SCRIPT"
sed -i '' 's/^INSTALLER_NAME=.*/INSTALLER_NAME="rNitro-v6.2.4-Final-arm64.sh"/' "$DMG_SCRIPT"
bash "$DMG_SCRIPT"

echo "=== Step 7: Update build-rnitro-zip.py ==="
ZIP_PY="/Users/mehmeh/Downloads/build-rnitro-zip.py"
python3 - <<'PY'
from pathlib import Path
p = Path("/Users/mehmeh/Downloads/build-rnitro-zip.py")
text = p.read_text()
text = text.replace("rNitro-v6.2.3-Final-arm64-all-files.zip", "rNitro-v6.2.4-Final-arm64-all-files.zip")
text = text.replace("rNitro-v6.2.3-Final-arm64.dmg", "rNitro-v6.2.4-Final-arm64.dmg")
text = text.replace("rNitro-v6.2.3-Final-arm64.sh", "rNitro-v6.2.4-Final-arm64.sh")
p.write_text(text)
print("Updated build-rnitro-zip.py")
PY

echo "=== Step 8: Run build-rnitro-zip.py ==="
python3 "$ZIP_PY"

echo ""
echo "=== Final zip path and ls -lh ==="
ls -lh "/Users/mehmeh/Downloads/rNitro-v6.2.4-Final-arm64-all-files.zip"