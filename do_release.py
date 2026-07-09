#!/usr/bin/env python3
"""Unified rNitro release pipeline.

Modes:
  sync    — refresh version.json hashes + index.html only
  quick   — sync + rebuild PKGs from existing apps + full-release ZIP (~1 min)
  full    — sync + recompile apps from source + PKGs + ZIP (~3–5 min)
  website — stage local website folder + rNitro-WEBSITE.zip in ~/Downloads
  netlify  — stage + deploy to Netlify (claim link if not logged in)
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

SITE = Path(__file__).resolve().parent
PY = sys.executable


def run(script: str, *args: str) -> None:
    cmd = [PY, str(SITE / script), *args]
    print(f"\n→ {' '.join(cmd)}")
    subprocess.run(cmd, cwd=SITE, check=True)


def launch_beta_mac() -> None:
    """Always end local workflows with the Beta app installed and running."""
    run("launch-beta.py")


def release_sync(*, skip_installers: bool) -> None:
    args = ["--skip-installers"] if skip_installers else []
    run("sync-versions.py", *args)


def pkgs_ready() -> bool:
    data = __import__("versions").load()
    stable = __import__("versions").stable_release(data)
    beta = __import__("versions").beta_release(data)
    return (SITE / stable["pkg"]).is_file() and (SITE / beta["pkg"]).is_file()


def release_pkgs(*, quick: bool) -> None:
    if quick and pkgs_ready():
        print("\n→ PKGs already built — skipping build-app-pkg.py")
        return
    args = ["--variant", "all"]
    if quick:
        args.append("--quick")
    run("build-app-pkg.py", *args)


def artifacts_ready(keys: tuple[str, ...]) -> bool:
    data = __import__("versions").load()
    stable = __import__("versions").stable_release(data)
    beta = __import__("versions").beta_release(data)
    names = [stable[k] for k in keys] + [beta[k] for k in keys]
    return all((SITE / name).is_file() for name in names)


def release_dmg(*, quick: bool) -> None:
    if quick and artifacts_ready(("dmg",)):
        print("\n→ DMGs already built — skipping build-app-dmg.py")
        return
    args = ["--variant", "all"]
    if quick:
        args.append("--quick")
    run("build-app-dmg.py", *args)


def release_app_zip(*, quick: bool) -> None:
    data = __import__("versions").load()
    stable = __import__("versions").stable_release(data)
    beta = __import__("versions").beta_release(data)
    combined = __import__("versions").macos_apps_release(data)["zip"]
    needed = [stable["zip"], beta["zip"], combined]
    if quick and all((SITE / name).is_file() for name in needed):
        print("\n→ App ZIPs already built — skipping build-app-zip.py")
        return
    quick_args = ["--quick"] if quick else []
    run("build-app-zip.py", "--variant", "all", *quick_args)
    run("build-app-zip.py", "--variant", "combined", *quick_args)


def release_zip(*, quick: bool) -> None:
    args = ["--quick"] if quick else []
    run("build-rnitro-zip.py", *args)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Unified rNitro release pipeline",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "mode",
        nargs="?",
        choices=["sync", "quick", "full", "website", "netlify"],
        default="quick",
        help="release mode (default: quick)",
    )
    args = parser.parse_args()

    print(f"=== rNitro release: {args.mode} ===")

    if args.mode == "sync":
        release_sync(skip_installers=True)
    elif args.mode == "website":
        release_app_zip(quick=True)
        release_sync(skip_installers=True)
        run("build-netlify-deploy.py")
        print("\n=== Website zip ready ===")
        print("  ~/Downloads/rNitro-WEBSITE.zip")
        print("  Unzip → double-click OPEN-WEBSITE.command")
        return
    elif args.mode == "netlify":
        release_app_zip(quick=True)
        release_sync(skip_installers=True)
        run("deploy-netlify.py")
        print("\n=== Netlify deploy ===")
        print("  Claim link opened in browser (or see Desktop/rnitro-netlify-deploy/CLAIM-NETLIFY.txt)")
        print("  Set subdomain to: getrnitro  →  https://getrnitro.netlify.app/")
        launch_beta_mac()
        return
    elif args.mode == "quick":
        release_pkgs(quick=True)
        release_dmg(quick=True)
        release_app_zip(quick=True)
        release_zip(quick=True)
        run("build-linux-tar.py")
        release_sync(skip_installers=True)
    else:
        release_pkgs(quick=False)
        release_dmg(quick=False)
        release_app_zip(quick=False)
        release_zip(quick=False)
        run("build-linux-tar.py")
        release_sync(skip_installers=False)

    print("\n=== Release complete ===")
    data = __import__("versions").load()
    full = data["releases"]["full"]
    print(f"  Site:     {SITE / 'index.html'}")
    print(f"  Bundle:   {SITE / full['zip']}")
    print(f"  Downloads: ~/Downloads/{full['zip']}")
    if args.mode in ("quick", "full"):
        launch_beta_mac()


if __name__ == "__main__":
    main()