#!/usr/bin/env python3
"""Build rNitro macOS PKG installers (installs rNitro.app to /Applications)."""
from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import full_release as fr
import signing as sig
import versions as v

APP_PATH = Path.home() / "Applications/rNitro.app"
INSTALL_LOCATION = "/Applications"
PKG_IDS = {
    "stable": "com.rnitro.cpumonitor",
    "beta": "com.rnitro.cpumonitor.beta",
}


def run_installer(script_name: str) -> None:
    script = SCRIPT_DIR / script_name
    if not script.is_file():
        raise SystemExit(f"Missing installer: {script}")
    print(f"Building from {script_name}...")
    subprocess.run(["bash", str(script)], cwd=SCRIPT_DIR, check=True)


def validate_app(app: Path) -> None:
    if not app.is_dir():
        raise SystemExit(f"App bundle missing: {app}")
    exe = app / "Contents/MacOS/rNitro"
    if not exe.is_file() or not exe.stat().st_mode & 0o111:
        raise SystemExit(f"Executable missing or not runnable: {exe}")


def app_from_legacy_zip(zip_name: str, work: Path) -> Path | None:
    legacy = SCRIPT_DIR / zip_name.replace(".pkg", ".zip")
    if not legacy.is_file():
        return None
    extract = work / "extracted"
    extract.mkdir()
    with zipfile.ZipFile(legacy) as zf:
        zf.extractall(extract)
    app = extract / "rNitro.app"
    return app if app.is_dir() else None


def stage_app(app_src: Path, stage: Path) -> None:
    if stage.exists():
        shutil.rmtree(stage)
    shutil.copytree(app_src, stage / "rNitro.app")
    sig.sign_app_bundle(stage / "rNitro.app")


def write_postinstall(scripts_dir: Path) -> None:
    postinstall = scripts_dir / "postinstall"
    postinstall.write_text(
        """#!/bin/bash
APP="/Applications/rNitro.app"
if [[ -d "$APP" ]]; then
  /usr/bin/xattr -cr "$APP" 2>/dev/null || true
  if [[ -f "$APP/Contents/MacOS/rNitro" ]]; then
    /usr/bin/codesign --force --sign - --timestamp=none "$APP/Contents/MacOS/rNitro" 2>/dev/null || true
    /usr/bin/codesign --force --sign - --timestamp=none "$APP" 2>/dev/null || true
  fi
fi
exit 0
""",
        encoding="utf-8",
    )
    postinstall.chmod(0o755)


def build_pkg(stage: Path, pkg_id: str, version: str, out_pkg: Path) -> None:
    scripts_dir = stage.parent / "scripts"
    scripts_dir.mkdir(exist_ok=True)
    write_postinstall(scripts_dir)
    component = stage.parent / "component.pkg"
    if component.exists():
        component.unlink()
    if out_pkg.exists():
        out_pkg.unlink()

    installer_id = sig.signing_identity("installer")
    pkgbuild_cmd = [
        "pkgbuild",
        "--root",
        str(stage),
        "--scripts",
        str(scripts_dir),
        "--identifier",
        pkg_id,
        "--version",
        version,
        "--install-location",
        INSTALL_LOCATION,
    ]
    if installer_id != sig.ADHOC:
        pkgbuild_cmd.extend(["--sign", installer_id])
    pkgbuild_cmd.append(str(component))
    subprocess.run(pkgbuild_cmd, check=True)

    product_cmd = [
        "productbuild",
        "--package",
        str(component),
        "--identifier",
        pkg_id,
        "--version",
        version,
    ]
    if installer_id != sig.ADHOC:
        product_cmd.extend(["--sign", installer_id])
    product_cmd.append(str(out_pkg))
    subprocess.run(product_cmd, check=True)

    sig.strip_quarantine(out_pkg)
    if installer_id == sig.ADHOC:
        print(
            "  ⚠ PKG is ad-hoc signed (no Developer ID). "
            "Users must right-click → Open on first launch."
        )
    else:
        print(f"  ✓ PKG signed with: {installer_id}")


def create_pkg(
    variant: str,
    installer_script: str,
    pkg_name: str,
    *,
    quick: bool = False,
) -> Path:
    data = v.load()
    version = fr.pkg_version(data)
    pkg_id = PKG_IDS[variant]
    out_pkg = SCRIPT_DIR / pkg_name

    with tempfile.TemporaryDirectory(prefix=f"rnitro-pkg-{variant}-") as tmp:
        work = Path(tmp)
        stage = work / "root"
        stage.mkdir()

        app_src: Path | None = None
        if quick:
            app_src = app_from_legacy_zip(pkg_name, work)

        if app_src is None:
            run_installer(installer_script)
            validate_app(APP_PATH)
            app_src = APP_PATH

        stage_app(app_src, stage)
        build_pkg(stage, pkg_id, version, out_pkg)

    size = out_pkg.stat().st_size
    print(f"Created {out_pkg} ({size / (1024 * 1024):.1f} MB)")
    return out_pkg


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Build rNitro macOS PKG installers")
    parser.add_argument(
        "--variant",
        choices=["beta", "stable", "all"],
        default="all",
        help="Which build to package (default: all)",
    )
    parser.add_argument(
        "--quick",
        action="store_true",
        help="Reuse legacy .zip apps when available (skip recompile)",
    )
    args = parser.parse_args()

    data = v.load()
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    downloads = Path.home() / "Downloads"

    builds: list[tuple[str, str, str]] = []
    if args.variant in ("stable", "all"):
        builds.append(("stable", stable["sh"], stable["pkg"]))
    if args.variant in ("beta", "all"):
        src = beta.get("source_sh") or beta["sh"]
        builds.append(("beta", src, beta["pkg"]))
    for variant, script, pkg_name in builds:
        out = create_pkg(variant, script, pkg_name, quick=args.quick)
        shutil.copy2(out, downloads / out.name)
        print(f"Copied to {downloads / out.name}")


if __name__ == "__main__":
    main()