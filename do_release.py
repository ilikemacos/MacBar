#!/usr/bin/env python3
"""Unified rNitro release pipeline (v1.2-ready).

Modes:
  sync     — refresh installers + index from version.json
  build    — recompile apps + zip/pkg/dmg (no --quick) + assert plists
  quick    — reuse artifacts when present; still assert plists
  website  — stage Netlify folder + WEBSITE zip (no nested full zip)
  netlify  — stage + deploy to getrnitro (draft → promote)
  github   — create/update GitHub Releases for stable + beta (+ linux)
  ship     — sync → build → assert → website stage → github → netlify
             (full path for a real public release)

Packaging installers are invoked with RNITRO_NO_LAUNCH=1 so builds do not open
the app mid-ship. After build/ship, launch-experimental.py reinstalls Exp on this
Mac unless --no-launch-experimental is set.

Post-deploy, deploy-netlify.py verifies stable + beta + experimental App ZIPs
are HTTP 200 and ≥ 1.4 MB on the live site.

Always push main README after ship if you changed version.json:
  git add README.md version.json && git commit && git push
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


def run_argv(*argv: str) -> None:
    print(f"\n→ {' '.join(argv)}")
    subprocess.run(list(argv), cwd=SITE, check=True)


def load_versions():
    import versions as v

    return v, v.load()


def release_sync(*, skip_installers: bool = False) -> None:
    args = ["--skip-installers"] if skip_installers else []
    run("sync-versions.py", *args)


def release_app_zip(*, quick: bool) -> None:
    v, data = load_versions()
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    combined = v.macos_apps_release(data)["zip"]
    needed = [stable["zip"], beta["zip"], combined]
    if quick and all((SITE / name).is_file() for name in needed):
        print("\n→ App ZIPs present — skipping rebuild (quick)")
        return
    # Never use --quick for a real ship; compile is the only way plists stay true.
    quick_args = ["--quick"] if quick else []
    run("build-app-zip.py", "--variant", "all", *quick_args)
    # Combined: prefer packing from the two channel zips (avoids double compile hangs).
    try:
        _combined_from_channel_zips(stable["zip"], beta["zip"], combined)
    except Exception as exc:
        print(f"  combined pack failed ({exc}); falling back to build-app-zip combined")
        run("build-app-zip.py", "--variant", "combined", *quick_args)


def _combined_from_channel_zips(stable_zip: str, beta_zip: str, out_name: str) -> None:
    import shutil
    import tempfile
    import zipfile

    out = SITE / out_name
    stage = Path(tempfile.mkdtemp()) / "stage"
    stage.mkdir()
    for zip_name, dest in ((stable_zip, "rNitro-Stable.app"), (beta_zip, "rNitro-Beta.app")):
        tmp = Path(tempfile.mkdtemp())
        with zipfile.ZipFile(SITE / zip_name) as zf:
            zf.extractall(tmp)
        app = tmp / "rNitro.app"
        if not app.is_dir():
            raise FileNotFoundError(f"rNitro.app missing in {zip_name}")
        shutil.move(str(app), str(stage / dest))
        shutil.rmtree(tmp, ignore_errors=True)
    (stage / "README — Install rNitro.txt").write_text(
        "rNitro macOS Apps — Stable + Beta\n"
        f"  rNitro-Stable.app from {stable_zip}\n"
        f"  rNitro-Beta.app from {beta_zip}\n"
        "Install only one at a time.\n",
        encoding="utf-8",
    )
    if out.exists():
        out.unlink()
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(stage.rglob("*")):
            if path.is_file():
                zf.write(path, path.relative_to(stage).as_posix())
    shutil.rmtree(stage.parent, ignore_errors=True)
    print(f"  + {out_name} ({out.stat().st_size:,} bytes)")


def release_pkgs(*, quick: bool) -> None:
    args = ["--variant", "all"]
    if quick:
        args.append("--quick")
    run("build-app-pkg.py", *args)


def release_dmg(*, quick: bool) -> None:
    args = ["--variant", "all"]
    if quick:
        args.append("--quick")
    run("build-app-dmg.py", *args)


def release_assert() -> None:
    run("assert_release_versions.py")


def release_stage_netlify() -> None:
    """Stage publish dir without nested full-site zip."""
    from importlib import util

    import versions as v

    spec = util.spec_from_file_location("bnd", SITE / "build-netlify-deploy.py")
    bnd = util.module_from_spec(spec)
    assert spec.loader
    spec.loader.exec_module(bnd)
    data = v.load()
    data["archive"] = data.get("archive") or []
    v.save(data)
    print("\n→ staging Netlify (include_bundle_zip=False)")
    bnd.stage(data, include_bundle_zip=False)


def release_netlify_deploy() -> None:
    release_stage_netlify()
    run("deploy-netlify.py")


def release_github() -> None:
    # Replaces stable/beta/linux release assets for current version.json tags.
    # Does not wipe unrelated history unless you pass --delete-all yourself.
    run("publish-github-releases.py")


def release_homebrew() -> None:
    formula = SITE / "build-homebrew.py"
    if formula.is_file():
        run("build-homebrew.py")


def restore_and_launch_experimental() -> None:
    """Reinstall Experimental into ~/Applications and launch it.

    Packaging installers for stable/beta overwrite the local app; this Mac
    always runs Experimental after build/ship (override with --no-launch-experimental).
    """
    run("launch-experimental.py")


def print_summary() -> None:
    v, data = load_versions()
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    exp = v.experimental_release(data)
    print("\n=== Release summary ===")
    print(f"  Stable: {stable['id']}  →  {stable['zip']}")
    print(f"  Beta:   {beta['id']}  →  {beta['zip']}")
    print(f"  Exp:    {exp['id']}  →  {exp['zip']}")
    print(f"  Site:   {SITE / 'index.html'}")
    print(f"  Stage:  {SITE / 'netlify-deploy'}")
    print("  Next:   git add README.md version.json && git commit && git push origin main")
    print("          (Releases alone won't update the repo homepage README.)")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Unified rNitro release pipeline",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "mode",
        nargs="?",
        choices=["sync", "build", "quick", "website", "netlify", "github", "ship"],
        default="sync",
        help="pipeline mode (default: sync)",
    )
    parser.add_argument(
        "--skip-netlify",
        action="store_true",
        help="With ship: skip Netlify deploy",
    )
    parser.add_argument(
        "--skip-github",
        action="store_true",
        help="With ship: skip GitHub releases",
    )
    parser.add_argument(
        "--launch-beta",
        action="store_true",
        help="Install and launch beta on this Mac at the end (overrides experimental)",
    )
    parser.add_argument(
        "--no-launch-experimental",
        action="store_true",
        help="Do not reinstall/launch Experimental after build/ship (default: always do)",
    )
    parser.add_argument(
        "--launch-experimental",
        action="store_true",
        help="Force Experimental reinstall/launch (default after build/ship anyway)",
    )
    args = parser.parse_args()

    print(f"=== rNitro release: {args.mode} ===")

    if args.mode == "sync":
        release_sync(skip_installers=False)

    elif args.mode == "build":
        release_sync(skip_installers=False)
        release_app_zip(quick=False)
        release_pkgs(quick=True)  # package from freshly built zips
        release_dmg(quick=True)
        release_assert()
        release_homebrew()

    elif args.mode == "quick":
        release_sync(skip_installers=True)
        release_app_zip(quick=True)
        release_pkgs(quick=True)
        release_dmg(quick=True)
        release_assert()

    elif args.mode == "website":
        release_sync(skip_installers=True)
        release_stage_netlify()
        # Optional website zip for local preview
        if (SITE / "build-netlify-deploy.py").is_file():
            try:
                run("build-netlify-deploy.py")
            except subprocess.CalledProcessError:
                print("  (website zip step skipped/failed — netlify-deploy/ is staged)")

    elif args.mode == "netlify":
        release_sync(skip_installers=True)
        release_stage_netlify()
        # deploy-netlify re-stages; ensure it does not force full zip
        run("deploy-netlify.py")

    elif args.mode == "github":
        release_assert()
        release_github()

    elif args.mode == "ship":
        release_sync(skip_installers=False)
        release_app_zip(quick=False)
        release_pkgs(quick=True)
        release_dmg(quick=True)
        release_assert()
        release_homebrew()
        release_stage_netlify()
        if not args.skip_github:
            release_github()
        if not args.skip_netlify:
            run("deploy-netlify.py")
        print("\n⚠ Remember to push main so README matches releases:")
        print("   git add -u && git commit -m 'release' && git push origin main")

    print_summary()

    # This Mac always runs Experimental after packaging (stable/beta installers
    # otherwise leave ~/Applications on the last channel built).
    want_exp = (
        args.launch_experimental
        or (
            args.mode in ("build", "quick", "ship")
            and not args.no_launch_experimental
            and not args.launch_beta
        )
    )
    if args.launch_beta:
        run("launch-beta.py")
    elif want_exp:
        restore_and_launch_experimental()


if __name__ == "__main__":
    main()
