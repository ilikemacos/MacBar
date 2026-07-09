#!/usr/bin/env python3
"""Generate Homebrew formula (brew install rnitro) and install.sh from version.json."""
from __future__ import annotations

import hashlib
from pathlib import Path

import versions as v

SITE = v.SITE
FORMULA_DIR = SITE / "homebrew" / "Formula"
TAP_ROOT = SITE.parent / "homebrew-rnitro"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def render_formula(rel: dict, sha: str) -> str:
    zip_name = rel["zip"]
    version = rel["short"].removeprefix("v")
    url = v.github_asset_url(rel["id"], zip_name)
    release_url = v.github_release_page_url(rel["id"])

    return f"""class Rnitro < Formula
  desc "Real-time CPU monitor for macOS — usage, temperature, and per-core stats"
  homepage "https://getrnitro.netlify.app/"
  url "{url}"
  version "{version}"
  sha256 "{sha}"
  license "MIT"

  depends_on macos: ">= :monterey"
  depends_on arch: :arm64

  def install
    app = "rNitro.app"
    odie "Expected #{{app}} in the download archive" unless (buildpath/app).directory?

    dest_root = if File.writable?("/Applications")
      Pathname("/Applications")
    else
      Pathname("#{{ENV['HOME']}}/Applications")
    end
    app_dest = dest_root/app
    rm_rf app_dest if app_dest.exist?
    cp_r buildpath/app, app_dest

    (bin/"rnitro").write <<~EOS
      #!/bin/bash
      set -euo pipefail
      cli="#{{app_dest}}/Contents/Resources/cli/rnitro"
      if [[ -f "$cli" ]]; then
        exec /usr/bin/env python3 "$cli" "$@"
      fi
      exec /usr/bin/open -a "#{{app_dest}}" "$@"
    EOS
    (bin/"rnitro").chmod 0755
  end

  def post_install
    dest = File.writable?("/Applications") ? "/Applications/rNitro.app" : "#{{ENV['HOME']}}/Applications/rNitro.app"
    system "/usr/bin/xattr", "-dr", "com.apple.quarantine", dest
  end

  def uninstall
    rm_rf "/Applications/rNitro.app"
    rm_rf "#{{Dir.home}}/Applications/rNitro.app"
  end

  def caveats
    dest = File.writable?("/Applications") ? "/Applications/rNitro.app" : "#{{ENV['HOME']}}/Applications/rNitro.app"
    <<~EOS
      rNitro was installed to #{{dest}}
      Run `rnitro` from Terminal or open it from Applications.

      First launch: if macOS blocks the app, right-click rNitro.app → Open → Open.
      Release: {release_url}
    EOS
  end

  test do
    assert_predicate bin/"rnitro", :exist?
  end
end
"""


def render_install_sh(rel: dict, sha: str) -> str:
    zip_name = rel["zip"]
    url = v.github_asset_url(rel["id"], zip_name)
    version = rel["label"]

    return f"""#!/bin/bash
# rNitro installer — same result as: brew tap ilikemacos/rnitro && brew install rnitro
# Use when Homebrew is unavailable or /opt/homebrew is not writable.
set -euo pipefail

URL="{url}"
SHA="{sha}"
VERSION="{version}"

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "rNitro requires Apple Silicon (arm64)." >&2
  exit 1
fi

if [[ -w /Applications ]]; then
  DEST="/Applications/rNitro.app"
else
  DEST="$HOME/Applications/rNitro.app"
  mkdir -p "$HOME/Applications"
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "→ Downloading rNitro $VERSION"
curl -fsSL -o "$TMP/rnitro.zip" "$URL"
echo "$SHA  $TMP/rnitro.zip" | shasum -a 256 -c -

ditto -xk "$TMP/rnitro.zip" "$TMP/extract"
[[ -d "$TMP/extract/rNitro.app" ]] || {{ echo "rNitro.app missing in archive" >&2; exit 1; }}

rm -rf "$DEST"
ditto "$TMP/extract/rNitro.app" "$DEST"
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

BIN_DIR="${{HOME}}/.local/bin"
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/rnitro" <<'LAUNCHER'
#!/bin/bash
APP="/Applications/rNitro.app"
[[ -d "$APP" ]] || APP="$HOME/Applications/rNitro.app"
exec /usr/bin/open -a "$APP" "$@"
LAUNCHER
chmod +x "$BIN_DIR/rnitro"

echo ""
echo "✅ rNitro installed to $DEST"
echo "   Run: rnitro"
echo "   First launch: right-click → Open if Gatekeeper blocks it."
"""


def main() -> None:
    data = v.load()
    stable = v.stable_release(data)
    zip_path = SITE / stable["zip"]
    if not zip_path.is_file():
        raise SystemExit(f"Missing {stable['zip']} — run: python3 build-app-zip.py --variant stable")

    sha = sha256_file(zip_path)
    FORMULA_DIR.mkdir(parents=True, exist_ok=True)

    formula_body = render_formula(stable, sha)
    formula_path = FORMULA_DIR / "rnitro.rb"
    formula_path.write_text(formula_body + "\n", encoding="utf-8")

    install_sh = TAP_ROOT / "install.sh" if TAP_ROOT.is_dir() else FORMULA_DIR.parent / "install.sh"
    install_sh.write_text(render_install_sh(stable, sha) + "\n", encoding="utf-8")
    install_sh.chmod(0o755)

    print(f"Wrote {formula_path.relative_to(SITE)}  ({stable['label']})")
    print(f"Wrote {install_sh}")

    if TAP_ROOT.is_dir():
        tap_formula = TAP_ROOT / "Formula" / "rnitro.rb"
        tap_formula.parent.mkdir(parents=True, exist_ok=True)
        tap_formula.write_text(formula_body + "\n", encoding="utf-8")
        (TAP_ROOT / "install.sh").write_text(install_sh.read_text(encoding="utf-8"), encoding="utf-8")
        (TAP_ROOT / "install.sh").chmod(0o755)
        print(f"Synced → {TAP_ROOT}/")

    print("\nInstall (Homebrew):")
    print("  brew tap ilikemacos/rnitro")
    print("  brew install rnitro")
    print("\nInstall (no Homebrew):")
    print("  curl -fsSL https://raw.githubusercontent.com/ilikemacos/homebrew-rnitro/main/install.sh | bash")


if __name__ == "__main__":
    main()