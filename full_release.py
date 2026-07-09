#!/usr/bin/env python3
"""Shared staging logic for rNitro full-release PKG."""
from __future__ import annotations

import os
import subprocess
from pathlib import Path

import versions as v

SITE = Path(__file__).resolve().parent
PKG_NAME = "rNitro-Full-Release.pkg"
PKG_OUT = Path.home() / "Downloads" / PKG_NAME

STATIC_FILES = [
    "README.md",
    "LICENSE",
    "uninstall-rNitro.sh",
    "index.html",
    "googleadfac0eaf77a74e6.html",
    "version.json",
    "terms-and-conditions.txt",
    "favicon.ico",
    "favicon.png",
    "favicon-192.png",
    "apple-touch-icon.png",
    "VarelaRound.ttf",
    "GeistMono.ttf",
    "create-dmg.sh",
    "create-windows-exe.sh",
    "build-app-pkg.py",
    "build-app-dmg.py",
    "build-app-zip.py",
    "build-rnitro-zip.py",
    "build-rnitro-pkg.py",
    "generate-favicon.py",
    "versions.py",
    "sync-versions.py",
    "make-v6-nochat.sh.py",
    "compute_hash.py",
    "signing.py",
    "do_release.py",
    "rNitro-Open-Installer.command",
]
DIRS = ["fonts"]

WEBSITE_FILES = [
    "404.html",
    "index.html",
    "googleadfac0eaf77a74e6.html",
    "version.json",
    "changelog.json",
    "terms-and-conditions.txt",
    "favicon.ico",
    "favicon.png",
    "favicon-192.png",
    "apple-touch-icon.png",
    "VarelaRound.ttf",
    "GeistMono.ttf",
]

WEBSITE_README = """rNitro Website
==============

Double-click index.html to open the download page in your browser.

Installers (.pkg / .sh), Windows builds, and release scripts are in the
parent folder (one level up from this website/ folder).
"""


def full_release_readme(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    apps = v.macos_apps_release(data)
    win = v.windows_release(data)
    return f"""rNitro Full Release Bundle
==========================

Double-click {PKG_NAME} to install everything to /Users/Shared/rNitro-Full-Release
(admin password required; Finder opens the folder when done).

CONTENTS
--------
  website/index.html            — download website (open locally in browser)
  index.html + version.json     — same site files at zip root
  {stable["pkg"]} / {beta["pkg"]} — PKG installers (Applications)
  {stable["dmg"]} / {beta["dmg"]} — DMG drag-to-Applications
  {apps["zip"]}              — ZIP with Stable + Beta .app bundles
  {stable["sh"]} / {beta["sh"]}   — source compile installers
  {win["exe"]} / {win["ps1"]}   — Windows builds
  terms-and-conditions.txt
  build scripts + favicons

QUICK START (macOS)
-------------------
1. Agree to Terms on the website before download
2. Double-click {stable["pkg"]} or {beta["pkg"]} to install rNitro.app to Applications
3. Or run: bash {stable["sh"]} (stable) / bash {beta["sh"]} (beta) to compile from source

https://getrnitro.netlify.app/
"""


def release_files(data: dict) -> list[str]:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    apps = v.macos_apps_release(data)
    win = v.windows_release(data)
    linux = v.linux_release(data)
    files = STATIC_FILES + [
        stable["pkg"],
        beta["pkg"],
        stable["dmg"],
        beta["dmg"],
        stable["zip"],
        beta["zip"],
        apps["zip"],
        stable["sh"],
        beta["sh"],
        beta["source_sh"],
        win["exe"],
        win["ps1"],
        "install-rNitro-windows.ps1",
    ]
    if linux.get("tar"):
        files.extend([linux["tar"], linux["sh"]])
    return files


def ensure_pkgs_built(quick: bool = False) -> None:
    cmd = ["python3", str(SITE / "build-app-pkg.py"), "--variant", "all"]
    if quick:
        cmd.append("--quick")
    subprocess.run(cmd, cwd=SITE, check=True)


def ensure_apps_built(quick: bool = False) -> None:
    subprocess.run(
        ["python3", str(SITE / "generate-favicon.py")],
        cwd=SITE,
        check=True,
    )
    ensure_pkgs_built(quick=quick)


def write_readme(data: dict) -> Path:
    readme_path = SITE / "README — Full Release.txt"
    readme_path.write_text(full_release_readme(data), encoding="utf-8")
    return readme_path


def stage_release(stage: Path, data: dict) -> list[str]:
    """Copy all release artifacts into stage. Returns paths added (for logging)."""
    write_readme(data)
    added: list[str] = []
    for name in release_files(data):
        src = SITE / name
        if not src.is_file():
            raise FileNotFoundError(f"Missing release file: {src}")
        dst = stage / name
        dst.parent.mkdir(parents=True, exist_ok=True)
        if src.resolve() != dst.resolve():
            import shutil

            shutil.copy2(src, dst)
        added.append(name)
        print(f"  + {name}")

    for name in DIRS:
        src_dir = SITE / name
        if not src_dir.is_dir():
            raise FileNotFoundError(f"Missing release dir: {src_dir}")
        for root, _, files in os.walk(src_dir):
            for fname in files:
                src = Path(root) / fname
                rel = src.relative_to(SITE)
                dst = stage / rel
                dst.parent.mkdir(parents=True, exist_ok=True)
                import shutil

                shutil.copy2(src, dst)
        added.append(f"{name}/")
        print(f"  + {name}/")

    return added


def pkg_version(data: dict) -> str:
    import re

    for key in ("latest", "beta"):
        m = re.search(r"v?(\d+\.\d+\.\d+)", data[key])
        if m:
            return m.group(1)
    return "1.0.0"