#!/usr/bin/env python3
"""Publish Stable, Beta, and Linux release assets to GitHub Releases."""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

import versions as v

SITE = Path(__file__).resolve().parent
REPO = "ilikemacos/rNitro"
BUNDLE_TAG = "v8.3.0-Beta"  # old single-bundle release to remove


def run(cmd: list[str], *, cwd: Path = SITE, check: bool = True) -> None:
    print(f"\n→ {' '.join(cmd)}")
    subprocess.run(cmd, cwd=cwd, check=check)


def channel_assets(data: dict, channel: str) -> tuple[dict, list[Path]]:
    rel = v.stable_release(data) if channel == "stable" else v.beta_release(data)
    names = [rel["zip"], rel["pkg"], rel["dmg"]]
    paths = []
    for name in names:
        path = SITE / name
        if not path.is_file():
            raise SystemExit(f"Missing {channel} artifact: {path}")
        paths.append(path)
    return rel, paths


def release_notes(data: dict, channel: str) -> str:
    rel = v.stable_release(data) if channel == "stable" else v.beta_release(data)
    other = v.beta_release(data) if channel == "stable" else v.stable_release(data)
    channel_label = "Stable (Final)" if channel == "stable" else "Beta"
    lines = [
        f"## rNitro {rel['label']} — {channel_label}",
        "",
        "Download **App ZIP** (contains `rNitro.app`), **PKG**, or **DMG** below.",
        "",
        "### Install from App ZIP",
        "1. Download the `.zip`",
        "2. Unzip → drag **rNitro.app** to **Applications**",
        "3. First launch: right-click → **Open** → **Open** if Gatekeeper blocks it",
        "",
        "### Other formats",
        f"- **PKG** — `{rel['pkg']}` — double-click installer (admin password)",
        f"- **DMG** — `{rel['dmg']}` — open disk image, drag app to Applications",
        "",
        f"Also available: [{other['label']}]({v.github_release_page_url(other['id'])})",
        "",
        "Website with all builds: [getrnitro.netlify.app](https://getrnitro.netlify.app/)",
    ]
    return "\n".join(lines)


def delete_release(tag: str) -> None:
    subprocess.run(
        ["gh", "release", "delete", tag, "-R", REPO, "--yes"],
        cwd=SITE,
        check=False,
    )


def publish_channel(data: dict, channel: str, *, latest: bool) -> None:
    rel, paths = channel_assets(data, channel)
    tag = v.github_release_tag(rel["id"])
    title = f"rNitro {rel['label']}"
    delete_release(tag)
    cmd = [
        "gh",
        "release",
        "create",
        tag,
        *[str(p) for p in paths],
        "--repo",
        REPO,
        "--title",
        title,
        "--notes",
        release_notes(data, channel),
    ]
    if latest:
        cmd.append("--latest")
    run(cmd)
    print(f"✅ {tag}: {', '.join(p.name for p in paths)}")


def linux_assets(data: dict) -> tuple[dict, list[Path]]:
    rel = v.linux_release(data)
    names = [rel["tar"], rel["sh"]]
    paths = []
    for name in names:
        path = SITE / name
        if not path.is_file():
            raise SystemExit(f"Missing Linux artifact: {path}")
        paths.append(path)
    return rel, paths


def linux_release_notes(data: dict) -> str:
    rel = v.linux_release(data)
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    lines = [
        f"## rNitro {rel['label']}",
        "",
        "Pre-release Linux build for x86_64 — Monitor, Advisor, Chat, and App Cleaner (GTK4 + libadwaita).",
        "",
        "### Install",
        f"1. Download `{rel['tar']}` or `{rel['sh']}` below",
        "2. Extract the tarball (if needed) and run: `bash install-rNitro-linux.sh`",
        "3. Installs to `~/.local/share/rnitro` with a desktop entry",
        "",
        "### Requirements",
        "- Python 3.10+",
        "- python3-gi, GTK 4, libadwaita",
        "- Optional: lm-sensors, nvidia-smi, Ayatana AppIndicator for tray",
        "",
        f"macOS stable: [{stable['label']}]({v.github_release_page_url(stable['id'])})",
        f"macOS beta: [{beta['label']}]({v.github_release_page_url(beta['id'])})",
        "",
        "Website: [getrnitro.netlify.app](https://getrnitro.netlify.app/)",
    ]
    return "\n".join(lines)


def publish_linux(data: dict) -> None:
    rel, paths = linux_assets(data)
    tag = v.github_release_tag(rel["id"])
    title = f"rNitro {rel['label']}"
    delete_release(tag)
    cmd = [
        "gh",
        "release",
        "create",
        tag,
        *[str(p) for p in paths],
        "--repo",
        REPO,
        "--title",
        title,
        "--notes",
        linux_release_notes(data),
    ]
    run(cmd)
    print(f"✅ {tag}: {', '.join(p.name for p in paths)}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Publish Stable, Beta, and Linux assets to GitHub Releases",
    )
    parser.add_argument(
        "--replace-bundle",
        action="store_true",
        default=True,
        help="Delete old full-bundle release tag (default: yes)",
    )
    args = parser.parse_args()

    data = v.load()
    if args.replace_bundle:
        print(f"Removing old bundle release {BUNDLE_TAG}…")
        delete_release(BUNDLE_TAG)

    publish_channel(data, "stable", latest=False)
    publish_channel(data, "beta", latest=True)
    publish_linux(data)

    stable = v.stable_release(data)
    beta = v.beta_release(data)
    linux = v.linux_release(data)
    print("\n✅ GitHub releases published")
    print(f"   Stable: {v.github_release_page_url(stable['id'])}")
    print(f"   Beta:   {v.github_release_page_url(beta['id'])}")
    print(f"   Linux:  {v.github_release_page_url(linux['id'])}")


if __name__ == "__main__":
    main()