#!/usr/bin/env python3
"""Bump macOS/Windows patch versions (+0.0.1) and rename shipped artifacts."""
from __future__ import annotations

import re
import shutil
from pathlib import Path

import versions as v

SITE = v.SITE
VERSION_FILE = v.VERSION_FILE


def bump_id(version_id: str) -> str:
    """v8.2.5-Final-arm64 -> v8.2.6-Final-arm64; v4.2.1-Windows -> v4.2.2-Windows."""
    m = re.match(r"^(v)(\d+)\.(\d+)\.(\d+)(.*)$", version_id)
    if not m:
        raise ValueError(f"Cannot bump version id: {version_id}")
    prefix, major, minor, patch, suffix = m.groups()
    return f"{prefix}{major}.{minor}.{int(patch) + 1}{suffix}"


def bump_label(label: str) -> str:
    m = re.match(r"^(v\d+\.\d+)\.(\d+)(.*)$", label)
    if not m:
        return label
    head, patch, tail = m.groups()
    return f"{head}.{int(patch) + 1}{tail}"


def bump_short(short: str) -> str:
    m = re.match(r"^(v\d+\.\d+)\.(\d+)$", short)
    if not m:
        return short
    head, patch = m.groups()
    return f"{head}.{int(patch) + 1}"


def rename_artifacts(old_id: str, new_id: str, exts: tuple[str, ...]) -> None:
    for ext in exts:
        old_name = f"rNitro-{old_id}.{ext}"
        new_name = f"rNitro-{new_id}.{ext}"
        old_path = SITE / old_name
        new_path = SITE / new_name
        if not old_path.is_file():
            print(f"  skip missing {old_name}")
            continue
        if new_path.is_file():
            new_path.unlink()
        shutil.copy2(old_path, new_path)
        print(f"  + {new_name}")


def main() -> None:
    data = v.load()
    old_stable = data["latest"]
    old_beta = data["beta"]
    old_win = data["windows"]

    new_stable = bump_id(old_stable)
    new_beta = bump_id(old_beta)
    new_win = bump_id(old_win)

    print("Renaming stable artifacts...")
    rename_artifacts(old_stable, new_stable, ("sh", "pkg", "dmg", "zip"))
    print("Renaming beta artifacts...")
    rename_artifacts(old_beta, new_beta, ("sh", "pkg", "dmg", "zip"))
    print("Renaming Windows artifacts...")
    rename_artifacts(old_win, new_win, ("exe", "ps1"))

    stable_rel = data["releases"]["stable"]
    beta_rel = data["releases"]["beta"]
    win_rel = data["releases"]["windows"]

    data["latest"] = new_stable
    data["beta"] = new_beta
    data["windows"] = new_win

    stable_rel["label"] = bump_label(stable_rel["label"])
    stable_rel["short"] = bump_short(stable_rel["short"])
    stable_rel["sh"] = f"rNitro-{new_stable}.sh"
    stable_rel["pkg"] = f"rNitro-{new_stable}.pkg"
    stable_rel["dmg"] = f"rNitro-{new_stable}.dmg"
    stable_rel["zip"] = f"rNitro-{new_stable}.zip"

    beta_rel["label"] = bump_label(beta_rel["label"])
    beta_rel["short"] = bump_short(beta_rel["short"])
    beta_rel["sh"] = f"rNitro-{new_beta}.sh"
    beta_rel["pkg"] = f"rNitro-{new_beta}.pkg"
    beta_rel["dmg"] = f"rNitro-{new_beta}.dmg"
    beta_rel["zip"] = f"rNitro-{new_beta}.zip"

    win_rel["exe"] = f"rNitro-{new_win}.exe"
    win_rel["ps1"] = f"rNitro-{new_win}.ps1"

    v.save(data)
    print(f"\nBumped versions:")
    print(f"  stable: {old_stable} -> {new_stable}")
    print(f"  beta:   {old_beta} -> {new_beta}")
    print(f"  win:    {old_win} -> {new_win}")


if __name__ == "__main__":
    main()