#!/usr/bin/env python3
"""Resolve rNitro.app bundles for release packaging."""
from __future__ import annotations

import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path

import versions as v

SITE = v.SITE
APP_PATH = Path.home() / "Applications/rNitro.app"


def validate_app(app: Path) -> None:
    if not app.is_dir():
        raise SystemExit(f"App bundle missing: {app}")
    exe = app / "Contents/MacOS/rNitro"
    if not exe.is_file() or not exe.stat().st_mode & 0o111:
        raise SystemExit(f"Executable missing or not runnable: {exe}")
    plist = app / "Contents/Info.plist"
    if not plist.is_file():
        raise SystemExit(f"Info.plist missing: {plist}")


def run_installer(script_name: str) -> None:
    script = SITE / script_name
    if not script.is_file():
        raise SystemExit(f"Missing installer: {script}")
    print(f"Building from {script_name}...")
    import os

    env = os.environ.copy()
    # Quiet packaging: installers open the app by default; skip during release builds.
    env["RNITRO_NO_LAUNCH"] = "1"
    subprocess.run(["bash", str(script)], cwd=SITE, check=True, env=env)


def app_from_legacy_zip(artifact_name: str, work: Path) -> Path | None:
    zip_name = artifact_name.replace(".pkg", ".zip").replace(".dmg", ".zip")
    legacy = SITE / zip_name
    if not legacy.is_file():
        return None
    work.mkdir(parents=True, exist_ok=True)
    extract = work / "zip-extract"
    extract.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(legacy) as zf:
        zf.extractall(extract)
    for name in ("rNitro.app", "rNitro-Stable.app", "rNitro-Beta.app"):
        app = extract / name
        if app.is_dir():
            return app
    return None


def app_from_pkg(pkg_name: str, work: Path) -> Path | None:
    pkg = SITE / pkg_name
    if not pkg.is_file():
        return None
    work.mkdir(parents=True, exist_ok=True)
    expand = work / "pkg-expand"
    if expand.exists():
        shutil.rmtree(expand)
    subprocess.run(
        ["pkgutil", "--expand-full", str(pkg), str(expand)],
        check=True,
        capture_output=True,
    )
    for app in expand.rglob("rNitro.app"):
        if app.is_dir():
            return app
    return None


def stage_app_copy(app_src: Path, dest: Path) -> None:
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(app_src, dest)


def resolve_app(
    *,
    installer_script: str,
    artifact_name: str,
    work: Path,
    quick: bool = False,
) -> Path:
    app_src: Path | None = None
    if quick:
        app_src = app_from_legacy_zip(artifact_name, work)
        if app_src is None:
            app_src = app_from_pkg(artifact_name.replace(".zip", ".pkg").replace(".dmg", ".pkg"), work)
        if app_src is None and APP_PATH.is_dir():
            validate_app(APP_PATH)
            app_src = APP_PATH

    if app_src is None:
        run_installer(installer_script)
        validate_app(APP_PATH)
        app_src = APP_PATH

    staged = work / "rNitro.app"
    stage_app_copy(app_src, staged)
    return staged