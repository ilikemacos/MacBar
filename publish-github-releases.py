#!/usr/bin/env python3
"""Upload stable + beta App ZIPs to GitHub Releases (ilikemacos/rNitro)."""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

import versions as v

SITE = Path(__file__).resolve().parent
REPO = "ilikemacos/rNitro"


def run(cmd: list[str], *, cwd: Path = SITE) -> None:
    print(f"\n→ {' '.join(cmd)}")
    subprocess.run(cmd, cwd=cwd, check=True)


def ensure_zip(data: dict, channel: str, *, build: bool) -> Path:
    rel = v.stable_release(data) if channel == "stable" else v.beta_release(data)
    zip_path = SITE / rel["zip"]
    if zip_path.is_file() and not build:
        print(f"  using existing {zip_path.name}")
        return zip_path
    variant = channel if channel in ("stable", "beta") else "all"
    run([sys.executable, str(SITE / "build-app-zip.py"), "--variant", variant])
    if not zip_path.is_file():
        raise SystemExit(f"Missing ZIP after build: {zip_path}")
    return zip_path


def release_notes(channel: str, data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    if channel == "stable":
        return f"""## rNitro {stable['label']} — Stable (Final)

**Recommended for everyday use.**

1. Download `{stable['zip']}` below
2. Unzip → drag `rNitro.app` to Applications
3. Right-click → **Open** once if macOS blocks it

Also available: [getrnitro.netlify.app](https://getrnitro.netlify.app/)

**Includes:** CPU monitor, benchmark, stress test, System Advisor, AI chat (OpenAI + OpenRouter).
"""
    return f"""## rNitro {beta['label']} — Beta

**For power users and experimental features.**

1. Download `{beta['zip']}` below
2. Unzip → drag `rNitro.app` to Applications
3. Right-click → **Open** once if macOS blocks it

Also available: [getrnitro.netlify.app](https://getrnitro.netlify.app/)

**Includes:** All stable features + AES-256-GCM key storage, all AI providers, first-launch tips, Low Power Mode badge, critical temp banners.
"""


def tag_id(channel: str, data: dict) -> str:
    rel_id = v.stable_id(data) if channel == "stable" else v.beta_id(data)
    # v8.2.6-Final-arm64 → v8.2.6-Final
    return rel_id.removesuffix("-arm64")


def publish(channel: str, data: dict, zip_path: Path, *, replace: bool) -> None:
    tag = tag_id(channel, data)
    title = (
        f"{v.stable_release(data)['label']} — Stable"
        if channel == "stable"
        else f"{v.beta_release(data)['label']} — Beta"
    )
    notes = release_notes(channel, data)
    if replace:
        subprocess.run(
            ["gh", "release", "delete", tag, "-R", REPO, "--yes"],
            cwd=SITE,
            check=False,
        )
    cmd = [
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
        notes,
    ]
    if channel == "stable":
        cmd.append("--latest")
    try:
        run(cmd)
    except subprocess.CalledProcessError:
        if not replace:
            print(f"Release {tag} may exist — retry with --replace")
            raise


def main() -> None:
    parser = argparse.ArgumentParser(description="Publish stable/beta ZIPs to GitHub Releases")
    parser.add_argument(
        "--channel",
        choices=["stable", "beta", "all"],
        default="all",
        help="Which release to publish (default: all)",
    )
    parser.add_argument(
        "--build",
        action="store_true",
        help="Rebuild App ZIPs before upload",
    )
    parser.add_argument(
        "--replace",
        action="store_true",
        help="Delete and recreate existing release tags",
    )
    args = parser.parse_args()

    data = v.load()
    channels = ["stable", "beta"] if args.channel == "all" else [args.channel]
    for channel in channels:
        zip_path = ensure_zip(data, channel, build=args.build)
        publish(channel, data, zip_path, replace=args.replace)
        print(f"✅ Published {channel}: {zip_path.name}")


if __name__ == "__main__":
    main()