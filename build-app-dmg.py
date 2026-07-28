#!/usr/bin/env python3
"""Build rNitro macOS DMG installers (drag rNitro.app to Applications)."""
from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import release_apps as apps
import signing as sig
import versions as v


def sign_app_bundle(app: Path) -> None:
    sig.sign_app_bundle(app)


def write_install_command(stage: Path, installer_name: str, *, product: str = "MacBar") -> None:
    cmd = stage / f"Install {product}.command"
    cmd.write_text(
        f"""#!/bin/bash
cd "$(dirname "$0")"
xattr -cr . 2>/dev/null
chmod +x "{installer_name}"
./"{installer_name}"
""",
        encoding="utf-8",
    )
    cmd.chmod(0o755)


def write_fix_open_command(stage: Path, *, bundle: str = "MacBar.app", exe: str = "MacBar") -> None:
    cmd = stage / f"Fix and Open {bundle.replace('.app', '')}.command"
    cmd.write_text(
        f"""#!/bin/bash
cd "$(dirname "$0")"
xattr -cr "{bundle}" 2>/dev/null
if [[ ! -d "$HOME/Applications/{bundle}" ]]; then
  ditto --noqtn "{bundle}" "$HOME/Applications/{bundle}"
  xattr -cr "$HOME/Applications/{bundle}" 2>/dev/null
  /usr/bin/codesign --force --sign - --timestamp=none "$HOME/Applications/{bundle}/Contents/MacOS/{exe}" 2>/dev/null || true
  /usr/bin/codesign --force --sign - --timestamp=none "$HOME/Applications/{bundle}" 2>/dev/null || true
fi
xattr -cr "$HOME/Applications/{bundle}" 2>/dev/null
open "$HOME/Applications/{bundle}"
""",
        encoding="utf-8",
    )
    cmd.chmod(0o755)


def create_dmg(
    *,
    installer_script: str,
    dmg_name: str,
    sh_name: str,
    quick: bool = False,
) -> Path:
    out_dmg = SCRIPT_DIR / dmg_name

    with tempfile.TemporaryDirectory(prefix="rnitro-dmg-") as tmp:
        work = Path(tmp)
        stage = work / "stage"
        stage.mkdir()

        app_stage = apps.resolve_app(
            installer_script=installer_script,
            artifact_name=dmg_name,
            work=work,
            quick=quick,
        )
        bundle = apps.bundle_folder_name(app_stage)
        dest = stage / bundle
        shutil.move(str(app_stage), str(dest))
        sign_app_bundle(dest)
        subprocess.run(
            ["codesign", "--verify", "--deep", "--strict", str(dest)],
            check=True,
        )

        shutil.copy2(SCRIPT_DIR / sh_name, stage / sh_name)
        varela = SCRIPT_DIR / "VarelaRound.ttf"
        if varela.is_file():
            shutil.copy2(varela, stage / "VarelaRound.ttf")
        ui_fonts = SCRIPT_DIR / "fonts" / "ui"
        if ui_fonts.is_dir():
            dest_fonts = stage / "fonts" / "ui"
            dest_fonts.mkdir(parents=True, exist_ok=True)
            for f in ui_fonts.glob("*.ttf"):
                shutil.copy2(f, dest_fonts / f.name)
            man = ui_fonts / "manifest.json"
            if man.is_file():
                shutil.copy2(man, dest_fonts / "manifest.json")
        (stage / "Applications").symlink_to("/Applications")
        product = "MacBar" if bundle == "MacBar.app" else "rNitro"
        exe = "MacBar" if bundle == "MacBar.app" else "rNitro"
        write_install_command(stage, sh_name, product=product)
        write_fix_open_command(stage, bundle=bundle, exe=exe)

        if out_dmg.exists():
            out_dmg.unlink()
        subprocess.run(
            [
                "hdiutil",
                "create",
                "-volname",
                "rNitro",
                "-srcfolder",
                str(stage),
                "-ov",
                "-format",
                "UDZO",
                str(out_dmg),
            ],
            check=True,
        )
        subprocess.run(["xattr", "-cr", str(out_dmg)], check=False)

    size = out_dmg.stat().st_size
    print(f"Created {out_dmg} ({size / (1024 * 1024):.1f} MB)")
    return out_dmg


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Build rNitro macOS DMG installers")
    parser.add_argument(
        "--variant",
        choices=["beta", "stable", "experimental", "all"],
        default="all",
        help="Which build to package (default: all)",
    )
    parser.add_argument(
        "--quick",
        action="store_true",
        help="Reuse existing PKG/ZIP/app when available (skip recompile)",
    )
    args = parser.parse_args()

    data = v.load()
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    downloads = Path.home() / "Downloads"

    builds: list[tuple[str, str, str]] = []
    if args.variant in ("stable", "all"):
        builds.append((stable["sh"], stable["dmg"], stable["sh"]))
    if args.variant in ("beta", "all"):
        builds.append((beta.get("source_sh") or beta["sh"], beta["dmg"], beta["sh"]))
    if args.variant in ("experimental", "all"):
        exp = v.experimental_release(data)
        builds.append((exp.get("source_sh") or exp["sh"], exp["dmg"], exp["sh"]))
    for installer_script, dmg_name, sh_name in builds:
        out = create_dmg(
            installer_script=installer_script,
            dmg_name=dmg_name,
            sh_name=sh_name,
            quick=args.quick,
        )
        shutil.copy2(out, downloads / out.name)
        print(f"Copied to {downloads / out.name}")


if __name__ == "__main__":
    main()