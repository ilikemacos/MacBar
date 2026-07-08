#!/usr/bin/env python3
"""Publish one full rNitro bundle ZIP to GitHub Releases (replaces per-channel zips)."""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

import versions as v

SITE = Path(__file__).resolve().parent
REPO = "ilikemacos/rNitro"
OLD_RELEASE_TAGS = ("v8.2.6-Final", "v8.2.8-Beta")


def run(cmd: list[str], *, cwd: Path = SITE, check: bool = True) -> None:
    print(f"\n→ {' '.join(cmd)}")
    subprocess.run(cmd, cwd=cwd, check=check)


def ensure_bundle(data: dict, *, build: bool) -> Path:
    zip_name = v.full_release(data)["zip"]
    zip_path = SITE / zip_name
    if zip_path.is_file() and not build:
        print(f"  using existing {zip_path.name} ({zip_path.stat().st_size / 1_048_576:.1f} MB)")
        return zip_path
    args = ["--quick"] if not build else []
    run([sys.executable, str(SITE / "build-rnitro-zip.py"), *args])
    if not zip_path.is_file():
        raise SystemExit(f"Missing bundle ZIP: {zip_path}")
    return zip_path


def delete_old_releases() -> None:
    for tag in OLD_RELEASE_TAGS:
        subprocess.run(
            ["gh", "release", "delete", tag, "-R", REPO, "--yes"],
            cwd=SITE,
            check=False,
        )


def release_notes(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    bundle = v.full_release(data)["zip"]
    return f"""## rNitro — complete download (one ZIP)

Everything in a single archive — website, installers, and apps.

1. Download **`{bundle}`** below
2. Unzip anywhere
3. Double-click **`OPEN-WEBSITE.command`** to open the local download page, or browse files directly

### Inside the ZIP
- **Website** — `index.html`, fonts, changelog (same as getrnitro.netlify.app)
- **Stable** — `{stable["zip"]}`, PKG, DMG, `.sh` ({stable["id"]})
- **Beta** — `{beta["zip"]}`, PKG, DMG, `.sh` ({beta["id"]})
- **Both apps** — `rNitro-macOS-Apps.zip` (Stable + Beta `.app` bundles)
- **Windows** — EXE + PowerShell installer
- **Older macOS builds** — previous-version `.sh` installers

Also live: [getrnitro.netlify.app](https://getrnitro.netlify.app/)
"""


def publish_bundle(data: dict, zip_path: Path, *, replace: bool) -> None:
    tag = v.github_release_tag(v.beta_id(data))
    title = f"rNitro {stable_label(data)} + {beta_label(data)} — Full bundle"
    if replace:
        delete_old_releases()
        subprocess.run(
            ["gh", "release", "delete", tag, "-R", REPO, "--yes"],
            cwd=SITE,
            check=False,
        )
    run(
        [
            "gh",
            "release",
            "create",
            tag,
            str(zip_path),
            "--repo",
            REPO,
            "--title",
            title,
            "--notes",
            release_notes(data),
            "--latest",
        ]
    )


def stable_label(data: dict) -> str:
    return v.stable_release(data)["label"]


def beta_label(data: dict) -> str:
    return v.beta_release(data)["label"]


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Publish one full rNitro bundle ZIP to GitHub Releases",
    )
    parser.add_argument(
        "--build",
        action="store_true",
        help="Rebuild bundle ZIP before upload (default: reuse existing)",
    )
    parser.add_argument(
        "--replace",
        action="store_true",
        help="Delete old per-channel releases and recreate bundle release",
    )
    args = parser.parse_args()

    data = v.load()
    zip_path = ensure_bundle(data, build=args.build)
    publish_bundle(data, zip_path, replace=args.replace or True)
    print(f"✅ Published bundle: {zip_path.name}")
    print(f"   {v.github_bundle_url(data)}")


if __name__ == "__main__":
    main()