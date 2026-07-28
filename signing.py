#!/usr/bin/env python3
"""macOS code signing helpers for rNitro PKG builds."""
from __future__ import annotations

import subprocess
from pathlib import Path

ADHOC = "-"


def find_installer_identity() -> str | None:
    """Return Developer ID Installer identity name, if any."""
    result = subprocess.run(
        ["security", "find-identity", "-v", "-p", "basic"],
        capture_output=True,
        text=True,
        check=False,
    )
    for line in result.stdout.splitlines():
        if "Developer ID Installer" in line and '"' in line:
            return line.split('"')[1]
    return None


def find_app_identity() -> str | None:
    """Return Developer ID Application identity name, if any."""
    result = subprocess.run(
        ["security", "find-identity", "-v", "-p", "codesigning"],
        capture_output=True,
        text=True,
        check=False,
    )
    for line in result.stdout.splitlines():
        if "Developer ID Application" in line and '"' in line:
            return line.split('"')[1]
    return None


def signing_identity(kind: str = "app") -> str:
    if kind == "installer":
        return find_installer_identity() or ADHOC
    return find_app_identity() or ADHOC


def sign_app_bundle(app: Path, identity: str | None = None) -> None:
    identity = identity or signing_identity("app")
    subprocess.run(["xattr", "-cr", str(app)], check=False)
    exe = app / "Contents/MacOS/rNitro"
    if exe.is_file():
        subprocess.run(
            [
                "codesign",
                "--force",
                "--sign",
                identity,
                "--timestamp=none",
                str(exe),
            ],
            check=True,
        )
    subprocess.run(
        [
            "codesign",
            "--force",
            "--deep",
            "--sign",
            identity,
            "--timestamp=none",
            str(app),
        ],
        check=True,
    )
    result = subprocess.run(
        ["codesign", "--verify", "--deep", str(app)],
        capture_output=True,
        timeout=30,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"codesign verify failed for {app}: {result.stderr.decode().strip()}"
        )


def strip_quarantine(path: Path) -> None:
    subprocess.run(["xattr", "-cr", str(path)], check=False)