#!/usr/bin/env python3
"""Shared version metadata for rNitro release tooling."""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

SITE = Path(__file__).resolve().parent
VERSION_FILE = SITE / "version.json"
GITHUB_REPO = "https://github.com/ilikemacos/MacBar"


def github_release_tag(rel_id: str) -> str:
    return rel_id.removesuffix("-arm64")


def github_release_page_url(rel_id: str) -> str:
    tag = github_release_tag(rel_id)
    return f"{GITHUB_REPO}/releases/tag/{tag}"


def github_asset_url(rel_id: str, filename: str) -> str:
    tag = github_release_tag(rel_id)
    return f"{GITHUB_REPO}/releases/download/{tag}/{filename}"


def github_releases_url() -> str:
    return f"{GITHUB_REPO}/releases"


def load() -> dict:
    return json.loads(VERSION_FILE.read_text(encoding="utf-8"))


def save(data: dict) -> None:
    VERSION_FILE.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def stable_id(data: dict | None = None) -> str:
    data = data or load()
    return data["latest"]


def beta_id(data: dict | None = None) -> str:
    data = data or load()
    return data["beta"]


def windows_id(data: dict | None = None) -> str:
    data = data or load()
    return data["windows"]


def linux_id(data: dict | None = None) -> str:
    data = data or load()
    return data.get("linux", "")


def stable_release(data: dict | None = None) -> dict:
    data = data or load()
    rel = dict(data["releases"]["stable"])
    rel["id"] = data["latest"]
    return rel


def beta_release(data: dict | None = None) -> dict:
    data = data or load()
    rel = dict(data["releases"]["beta"])
    rel["id"] = data["beta"]
    return rel


def experimental_release(data: dict | None = None) -> dict:
    data = data or load()
    rel = dict(data.get("releases", {}).get("experimental") or {})
    rel["id"] = data.get("experimental", rel.get("id", "v0.0.0-Experimental"))
    return rel


def intel_beta_release(data: dict | None = None) -> dict:
    data = data or load()
    rel = dict(data.get("releases", {}).get("intel_beta") or {})
    rel["id"] = data.get("intel_beta", rel.get("id", "v0.0.0-Intel"))
    return rel


def intel_stable_release(data: dict | None = None) -> dict:
    data = data or load()
    rel = dict(data.get("releases", {}).get("intel_stable") or {})
    rel["id"] = data.get("intel_stable", rel.get("id", "v0.0.0-Intel"))
    return rel


def windows_release(data: dict | None = None) -> dict:
    data = data or load()
    rel = dict(data["releases"]["windows"])
    rel["id"] = data["windows"]
    return rel


def linux_release(data: dict | None = None) -> dict:
    data = data or load()
    rel = dict(data["releases"]["linux"])
    rel["id"] = data.get("linux", rel.get("id", ""))
    return rel


def full_release(data: dict | None = None) -> dict:
    data = data or load()
    return dict(data.get("releases", {}).get("full") or {"label": "Full Release", "zip": "rnitro-netlify.zip"})


def macos_apps_release(data: dict | None = None) -> dict:
    data = data or load()
    return dict(data["releases"]["macos_apps"])


def cli_release(data: dict | None = None) -> dict:
    data = data or load()
    rel = dict(data["releases"]["cli"])
    rel["id"] = data.get("cli", rel.get("version", "v0.1-cli"))
    return rel


def installer_path(name: str) -> Path:
    return SITE / name


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def masked_installer_hash(path: Path) -> str:
    lines = path.read_bytes().splitlines(keepends=True)
    masked = []
    for line in lines:
        if line.startswith(b"EXPECTED_HASH="):
            masked.append(b'EXPECTED_HASH="MASKED"\n')
        else:
            masked.append(line)
    return hashlib.sha256(b"".join(masked)).hexdigest()


def update_expected_hash(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    if not re.search(r'^EXPECTED_HASH=".*"', text, flags=re.M):
        raise ValueError(f"EXPECTED_HASH line not found in {path}")
    new_hash = masked_installer_hash(path)
    updated = re.sub(
        r'^EXPECTED_HASH=".*"',
        f'EXPECTED_HASH="{new_hash}"',
        text,
        count=1,
        flags=re.M,
    )
    if updated != text:
        path.write_text(updated, encoding="utf-8")
    return new_hash


def validate(data: dict) -> None:
    if data["latest"] != data["releases"]["stable"].get("id", data["latest"]):
        # id may be omitted in releases.stable; ensure sh/zip names match
        pass
    stable = stable_release(data)
    beta = beta_release(data)
    if f"rNitro-{data['latest']}.sh" != stable["sh"]:
        raise ValueError(
            f"releases.stable.sh ({stable['sh']}) must match rNitro-{data['latest']}.sh"
        )
    if f"rNitro-{data['beta']}.sh" != beta["sh"]:
        raise ValueError(
            f"releases.beta.sh ({beta['sh']}) must match rNitro-{data['beta']}.sh"
        )
    if f"rNitro-{data['latest']}.pkg" != stable["pkg"]:
        raise ValueError(
            f"releases.stable.pkg ({stable['pkg']}) must match rNitro-{data['latest']}.pkg"
        )
    if f"rNitro-{data['beta']}.pkg" != beta["pkg"]:
        raise ValueError(
            f"releases.beta.pkg ({beta['pkg']}) must match rNitro-{data['beta']}.pkg"
        )
    if f"rNitro-{data['latest']}.dmg" != stable["dmg"]:
        raise ValueError(
            f"releases.stable.dmg ({stable['dmg']}) must match rNitro-{data['latest']}.dmg"
        )
    if f"rNitro-{data['beta']}.dmg" != beta["dmg"]:
        raise ValueError(
            f"releases.beta.dmg ({beta['dmg']}) must match rNitro-{data['beta']}.dmg"
        )
    if f"rNitro-{data['latest']}.zip" != stable["zip"]:
        raise ValueError(
            f"releases.stable.zip ({stable['zip']}) must match rNitro-{data['latest']}.zip"
        )
    if f"rNitro-{data['beta']}.zip" != beta["zip"]:
        raise ValueError(
            f"releases.beta.zip ({beta['zip']}) must match rNitro-{data['beta']}.zip"
        )
def macos_release_files(data: dict | None = None) -> list[str]:
    data = data or load()
    stable = stable_release(data)
    beta = beta_release(data)
    win = windows_release(data)
    linux = linux_release(data)
    files = [
        stable["pkg"],
        beta["pkg"],
        stable["dmg"],
        beta["dmg"],
        stable["zip"],
        beta["zip"],
        macos_apps_release(data)["zip"],
        stable["sh"],
        beta["sh"],
        win["exe"],
        win["ps1"],
        "install-rNitro-windows.ps1",
    ]
    if beta.get("source_sh"):
        files.append(beta["source_sh"])
    if linux.get("tar"):
        files.extend([linux["tar"], linux["sh"]])
    return files