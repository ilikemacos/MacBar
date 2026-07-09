#!/usr/bin/env python3
"""Build the complete rNitro full-release macOS PKG installer."""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import full_release as fr
import versions as v

PKG_OUT = Path("/Users/mehmeh/Downloads/rNitro-Full-Release.pkg")
INSTALL_LOCATION = "/Users/Shared/rNitro-Full-Release"
PKG_ID = "com.rnitro.full-release"


def build_pkg(stage: Path, data: dict, out_pkg: Path) -> None:
    version = fr.pkg_version(data)
    scripts_dir = stage.parent / "pkg-scripts"
    scripts_dir.mkdir(exist_ok=True)
    postinstall = scripts_dir / "postinstall"
    postinstall.write_text(
        f"""#!/bin/bash
set -e
TARGET="{INSTALL_LOCATION}"
if [[ -d "$TARGET" ]]; then
  /usr/bin/open "$TARGET"
fi
exit 0
""",
        encoding="utf-8",
    )
    postinstall.chmod(0o755)

    component = stage.parent / "component.pkg"
    if component.exists():
        component.unlink()
    if out_pkg.exists():
        out_pkg.unlink()

    subprocess.run(
        [
            "pkgbuild",
            "--root",
            str(stage),
            "--scripts",
            str(scripts_dir),
            "--identifier",
            PKG_ID,
            "--version",
            version,
            "--install-location",
            INSTALL_LOCATION,
            str(component),
        ],
        check=True,
    )

    subprocess.run(
        [
            "productbuild",
            "--package",
            str(component),
            "--identifier",
            PKG_ID,
            "--version",
            version,
            str(out_pkg),
        ],
        check=True,
    )


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Build rNitro full-release PKG")
    parser.add_argument(
        "--quick",
        action="store_true",
        help="Skip app rebuilds (reuse legacy ZIPs for PKG when available)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=PKG_OUT,
        help=f"Output PKG path (default: {PKG_OUT})",
    )
    args = parser.parse_args()

    data = v.load()

    if not args.quick:
        print("Building app PKGs and favicons...")
        fr.ensure_apps_built(quick=False)
    else:
        print("Quick mode — building PKGs from legacy ZIPs if available...")
        fr.ensure_pkgs_built(quick=True)

    with tempfile.TemporaryDirectory(prefix="rnitro-pkg-") as tmp:
        stage = Path(tmp) / "root"
        stage.mkdir()
        print("Staging release files...")
        fr.stage_release(stage, data)
        print("Building full-release PKG...")
        build_pkg(stage, data, args.output)

    size = args.output.stat().st_size
    print(f"\nCreated {args.output}")
    print(f"Install location: {INSTALL_LOCATION}")
    print(f"Size: {size:,} bytes ({size / (1024 * 1024):.1f} MB)")


if __name__ == "__main__":
    main()