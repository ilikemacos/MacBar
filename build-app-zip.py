#!/usr/bin/env python3
"""Build self-contained rNitro.app ZIP archives with README and Terms."""
from __future__ import annotations

import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
import release_apps as apps
import signing as sig
import versions as v
TERMS_FILE = SCRIPT_DIR / "terms-and-conditions.txt"
TERMS_ZIP_NAME = "Terms and Conditions.txt"

README_SINGLE = """rNitro {version}
{underline}

INSTALLATION
------------
1. Double-click this ZIP file to extract rNitro.app
2. Drag rNitro.app into your Applications folder
   (Finder → Applications, or ~/Applications)
3. Open Applications and double-click rNitro
4. rNitro lives in your menu bar (top-right). Click the icon to open the monitor.

FIRST LAUNCH
------------
If macOS says the app cannot be opened:
  • Right-click rNitro.app → Open → Open (one time only), or
  • System Settings → Privacy & Security → Open Anyway

REQUIREMENTS
------------
  • macOS 12 Monterey or later
  • Apple Silicon Mac (arm64)
  • Launch at Login requires macOS 13+

UNINSTALL
---------
Drag rNitro.app from Applications to Trash.

ALTERNATIVE: COMPILE FROM SOURCE
--------------------------------
The .sh installer on https://getrnitro.netlify.app/ compiles rNitro on your Mac
(~30 seconds) and installs to ~/Applications/rNitro.app.

SUPPORT
-------
https://getrnitro.netlify.app/
"""

README_COMBINED_TEMPLATE = """rNitro macOS — Stable + Beta
=============================

This archive contains both macOS builds:

  • rNitro-Stable.app  — {stable_id} (CPU monitor, no AI chat)
  • rNitro-Beta.app    — {beta_id} (stable features + AI chat)

INSTALLATION
------------
1. Double-click this ZIP to extract the files
2. Choose ONE app to install (Stable or Beta — not both at once)
3. Drag your chosen .app into Applications
4. Optionally rename it to rNitro.app if you prefer
5. Open from Applications — rNitro lives in your menu bar

FIRST LAUNCH
------------
If macOS blocks the app: right-click → Open → Open (once), or use
System Settings → Privacy & Security → Open Anyway.

TERMS
-----
By installing or using rNitro you agree to Terms and Conditions.txt
included in this archive.

REQUIREMENTS
------------
  • macOS 12+ on Apple Silicon (arm64)
  • Launch at Login requires macOS 13+

SUPPORT
-------
https://getrnitro.netlify.app/
"""


def readme_text(version: str) -> str:
    underline = "=" * len(f"rNitro {version}")
    return README_SINGLE.format(version=version, underline=underline)


def terms_text() -> str:
    if not TERMS_FILE.is_file():
        raise SystemExit(f"Missing terms file: {TERMS_FILE}")
    return TERMS_FILE.read_text(encoding="utf-8")


def prepare_app_bundle(app: Path) -> None:
    sig.sign_app_bundle(app)
    sig.strip_quarantine(app)


def write_zip(stage: Path, out_zip: Path) -> None:
    if out_zip.exists():
        out_zip.unlink()
    with zipfile.ZipFile(out_zip, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(stage.rglob("*")):
            if path.is_file():
                zf.write(path, arcname=path.relative_to(stage).as_posix())
                print(f"  + {path.relative_to(stage)}")
    size = out_zip.stat().st_size
    print(f"\nCreated {out_zip}")
    print(f"Size: {size:,} bytes ({size / (1024 * 1024):.1f} MB)")


def create_zip(
    version: str,
    installer_script: str,
    out_name: str | None = None,
    *,
    quick: bool = False,
) -> Path:
    zip_name = out_name or f"rNitro-{version}.zip"
    out_zip = SCRIPT_DIR / zip_name

    with tempfile.TemporaryDirectory(prefix="rnitro-zip-") as tmp:
        work = Path(tmp)
        stage = work / "stage"
        stage.mkdir()
        app_stage = apps.resolve_app(
            installer_script=installer_script,
            artifact_name=zip_name.replace(".zip", ".pkg"),
            work=work,
            quick=quick,
        )
        shutil.move(str(app_stage), str(stage / "rNitro.app"))
        prepare_app_bundle(stage / "rNitro.app")
        (stage / "README — Install rNitro.txt").write_text(readme_text(version), encoding="utf-8")
        (stage / TERMS_ZIP_NAME).write_text(terms_text(), encoding="utf-8")
        write_zip(stage, out_zip)
    return out_zip


def create_combined_zip(out_name: str | None = None, *, quick: bool = False) -> Path:
    data = v.load()
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    apps_rel = v.macos_apps_release(data)
    out_name = out_name or apps_rel["zip"]
    out_zip = SCRIPT_DIR / out_name

    with tempfile.TemporaryDirectory(prefix="rnitro-combined-") as tmp:
        stage = Path(tmp) / "stage"
        stage.mkdir()

        stable_work = Path(tmp) / "stable"
        stable_work.mkdir(parents=True, exist_ok=True)
        stable_app = apps.resolve_app(
            installer_script=stable["sh"],
            artifact_name=stable["pkg"],
            work=stable_work,
            quick=quick,
        )
        shutil.move(str(stable_app), str(stage / "rNitro-Stable.app"))
        prepare_app_bundle(stage / "rNitro-Stable.app")

        beta_work = Path(tmp) / "beta"
        beta_work.mkdir(parents=True, exist_ok=True)
        beta_app = apps.resolve_app(
            installer_script=beta["source_sh"],
            artifact_name=beta["pkg"],
            work=beta_work,
            quick=quick,
        )
        shutil.move(str(beta_app), str(stage / "rNitro-Beta.app"))
        prepare_app_bundle(stage / "rNitro-Beta.app")

        (stage / "README — Install rNitro.txt").write_text(
            README_COMBINED_TEMPLATE.format(stable_id=stable["id"], beta_id=beta["id"]),
            encoding="utf-8",
        )
        (stage / TERMS_ZIP_NAME).write_text(terms_text(), encoding="utf-8")
        write_zip(stage, out_zip)
    return out_zip


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Build rNitro.app ZIP distribution")
    parser.add_argument(
        "--variant",
        choices=["beta", "stable", "refresh", "all", "combined"],
        default="combined",
        help="Which build to package (default: combined)",
    )
    parser.add_argument(
        "--quick",
        action="store_true",
        help="Reuse existing PKG/ZIP/app when available (skip recompile)",
    )
    args = parser.parse_args()

    downloads = Path.home() / "Downloads"

    if args.variant == "combined":
        out = create_combined_zip(quick=args.quick)
        shutil.copy2(out, downloads / out.name)
        print(f"Copied to {downloads / out.name}")
        return

    data = v.load()
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    builds = []
    if args.variant in ("beta", "all"):
        builds.append((beta["id"], beta.get("source_sh") or beta["sh"], beta["zip"]))
    if args.variant in ("stable", "all"):
        builds.append((stable["id"], stable["sh"], stable["zip"]))
    if args.variant in ("refresh", "all") and data.get("refresh"):
        ref = v.refresh_release(data)
        builds.append((ref["id"], ref["source_sh"], ref["zip"]))

    for version, script, zip_name in builds:
        out = create_zip(version, script, zip_name, quick=args.quick)
        shutil.copy2(out, downloads / out.name)
        print(f"Copied to {downloads / out.name}")


if __name__ == "__main__":
    main()