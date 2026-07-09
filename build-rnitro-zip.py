#!/usr/bin/env python3
"""Build the complete rNitro full-release ZIP (website + PKGs + installers)."""
from __future__ import annotations

import os
import shutil
import sys
import zipfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import full_release as fr
import versions as v

NETLIFY_ZIP = "rnitro-netlify.zip"


def write_netlify_zip(data: dict, out_path: Path) -> None:
    from importlib import util

    spec = util.spec_from_file_location(
        "_build_netlify_deploy", SCRIPT_DIR / "build-netlify-deploy.py"
    )
    mod = util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)

    stage_dir = mod.stage(data)

    def pack_zip(target: Path) -> None:
        if target.exists():
            target.unlink()
        with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as zf:
            for root, _, files in os.walk(stage_dir):
                for fname in files:
                    full = Path(root) / fname
                    arc = full.relative_to(stage_dir).as_posix()
                    zf.write(full, arcname=arc)
                    print(f"  + {arc}")

    pack_zip(out_path)
    # Include the release zip on the live site so "Download Full Release ZIP" works.
    shutil.copy2(out_path, stage_dir / NETLIFY_ZIP)
    print(f"  + {NETLIFY_ZIP} (self, for Netlify download button)")
    pack_zip(out_path)


def write_zip(data: dict, out_path: Path) -> None:
    if out_path.name == NETLIFY_ZIP:
        write_netlify_zip(data, out_path)
        return
    fr.write_readme(data)
    if out_path.exists():
        out_path.unlink()

    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for name in fr.release_files(data):
            path = SCRIPT_DIR / name
            if not path.is_file():
                raise FileNotFoundError(f"Missing release file: {path}")
            zf.write(path, arcname=name)
            print(f"  + {name}")

        for name in fr.DIRS:
            root_dir = SCRIPT_DIR / name
            if not root_dir.is_dir():
                raise FileNotFoundError(f"Missing release dir: {root_dir}")
            for root, _, files in os.walk(root_dir):
                for fname in files:
                    full = Path(root) / fname
                    arc = full.relative_to(SCRIPT_DIR).as_posix()
                    zf.write(full, arcname=arc)
            print(f"  + {name}/")

        readme_tmp = SCRIPT_DIR / ".website-readme-tmp.txt"
        readme_tmp.write_text(fr.WEBSITE_README, encoding="utf-8")
        try:
            zf.write(readme_tmp, arcname="website/README.txt")
            for name in fr.WEBSITE_FILES:
                path = SCRIPT_DIR / name
                if not path.is_file():
                    raise FileNotFoundError(f"Missing website file: {path}")
                zf.write(path, arcname=f"website/{name}")
                print(f"  + website/{name}")
            fonts_dir = SCRIPT_DIR / "fonts"
            if fonts_dir.is_dir():
                for root, _, files in os.walk(fonts_dir):
                    for fname in files:
                        full = Path(root) / fname
                        arc = "website/" + full.relative_to(SCRIPT_DIR).as_posix()
                        zf.write(full, arcname=arc)
            print("  + website/fonts/")
        finally:
            readme_tmp.unlink(missing_ok=True)


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Build rNitro full-release ZIP")
    parser.add_argument(
        "--quick",
        action="store_true",
        help="Skip app rebuilds (reuse existing PKGs)",
    )
    args = parser.parse_args()

    data = v.load()
    full = v.full_release(data)
    zip_name = full["zip"]
    zip_site = SCRIPT_DIR / zip_name
    zip_downloads = Path.home() / "Downloads" / zip_name

    if not args.quick:
        print("Building app PKGs and favicons...")
        fr.ensure_apps_built(quick=False)
    else:
        print("Quick mode — using existing PKGs")
        stable = v.stable_release(data)
        beta = v.beta_release(data)
        if not (SCRIPT_DIR / stable["pkg"]).is_file() or not (SCRIPT_DIR / beta["pkg"]).is_file():
            fr.ensure_pkgs_built(quick=True)

    print("Writing ZIP...")
    write_zip(data, zip_site)
    shutil.copy2(zip_site, zip_downloads)

    size = zip_site.stat().st_size
    print(f"\nCreated {zip_site}")
    print(f"Copied to {zip_downloads}")
    print(f"Size: {size:,} bytes ({size / (1024 * 1024):.1f} MB)")


if __name__ == "__main__":
    main()