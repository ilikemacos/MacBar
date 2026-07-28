#!/usr/bin/env python3
"""Resolve rNitro.app bundles for release packaging."""
from __future__ import annotations

import shutil
import subprocess
import zipfile
from pathlib import Path

import versions as v

SITE = v.SITE
APP_CANDIDATES = [
    Path.home() / "Applications/rNitro.app",
    Path.home() / "Applications/MacBar.app",  # transitional
]


def _executable(app: Path) -> Path | None:
    for name in ("rNitro", "MacBar"):
        exe = app / "Contents/MacOS" / name
        if exe.is_file() and exe.stat().st_mode & 0o111:
            return exe
    return None


def validate_app(app: Path) -> None:
    if not app.is_dir():
        raise SystemExit(f"App bundle missing: {app}")
    if _executable(app) is None:
        raise SystemExit(f"Executable missing or not runnable under {app}/Contents/MacOS/")
    plist = app / "Contents/Info.plist"
    if not plist.is_file():
        raise SystemExit(f"Info.plist missing: {plist}")


def installed_app() -> Path | None:
    for path in APP_CANDIDATES:
        if path.is_dir():
            try:
                validate_app(path)
                return path
            except SystemExit:
                continue
    return None


def run_installer(script_name: str) -> None:
    script = SITE / script_name
    if not script.is_file():
        raise SystemExit(f"Missing installer: {script}")
    print(f"Building from {script_name}...")
    import os
    env = os.environ.copy()
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
    for name in ("rNitro.app", "MacBar.app", "rNitro-Stable.app", "rNitro-Beta.app"):
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
    for pattern in ("rNitro.app", "MacBar.app"):
        for app in expand.rglob(pattern):
            if app.is_dir():
                return app
    return None


def stage_app_copy(app_src: Path, dest: Path) -> None:
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(app_src, dest)


def bundle_folder_name(app_src: Path) -> str:
    if app_src.name == "MacBar.app" or (app_src / "Contents/MacOS/MacBar").is_file():
        # package as rNitro.app for distribution after rebrand revert
        return "rNitro.app"
    return "rNitro.app"


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
            app_src = app_from_pkg(
                artifact_name.replace(".zip", ".pkg").replace(".dmg", ".pkg"), work
            )
        if app_src is None:
            app_src = installed_app()

    if app_src is None:
        run_installer(installer_script)
        app_src = installed_app()
        if app_src is None:
            raise SystemExit("Installer finished but no rNitro.app found in ~/Applications")
        validate_app(app_src)

    staged = work / "rNitro.app"
    stage_app_copy(app_src, staged)
    # If source was MacBar binary layout, rename binary if needed after copy
    mac_exe = staged / "Contents/MacOS/MacBar"
    r_exe = staged / "Contents/MacOS/rNitro"
    if mac_exe.is_file() and not r_exe.is_file():
        mac_exe.rename(r_exe)
    return staged
