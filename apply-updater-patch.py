#!/usr/bin/env python3
"""Backport the in-app updater block from install-rNitro.sh into an archive .sh."""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

import versions as v

SITE = v.SITE
SOURCE = SITE / "install-rNitro.sh"
START = "// ── Update check"
END = "// ── Real SMC temperature reads"


def extract_updater_block(text: str) -> str:
    start = text.find(START)
    end = text.find(END)
    if start < 0 or end < 0 or end <= start:
        raise SystemExit(f"Could not locate updater block between {START!r} and {END!r}")
    return text[start:end]


def target_version(text: str) -> str:
    match = re.search(r'let CURRENT_VERSION = "(v[^"]+)"', text)
    if not match:
        raise SystemExit("Target .sh has no let CURRENT_VERSION = ...")
    return match.group(1)


def channel_flags(version_id: str) -> str:
    channel = "beta" if "Beta" in version_id else "stable"
    beta_ui = "true" if channel == "beta" else "false"
    return (
        f'let CURRENT_VERSION = "{version_id}"\n'
        f'let RNITRO_BUILD_CHANNEL = "{channel}"\n'
        f"let RNITRO_FEATURE_BETA_UI = (RNITRO_BUILD_CHANNEL == \"beta\")"
    )


def patch_target(target: Path, updater: str, version_id: str) -> None:
    text = target.read_text(encoding="utf-8")
    old_start = text.find(START)
    old_end = text.find(END)
    if old_start < 0 or old_end < 0:
        raise SystemExit(f"{target.name}: missing updater markers")

    patched = updater
    patched = re.sub(
        r'let CURRENT_VERSION = "v[^"]+"\n(?:let RNITRO_BUILD_CHANNEL = "[^"]+"\n)?(?:let RNITRO_FEATURE_BETA_UI = \([^)]+\)\n)?',
        channel_flags(version_id) + "\n",
        patched,
        count=1,
    )
    if 'let RNITRO_BUILD_CHANNEL' not in patched:
        patched = patched.replace(
            f'let CURRENT_VERSION = "{version_id}"',
            channel_flags(version_id),
            1,
        )

    new_text = text[:old_start] + patched + text[old_end:]
    new_hash = compute_expected_hash(new_text)
    new_text, count = re.subn(
        r'^EXPECTED_HASH="[a-f0-9]{64}"',
        f'EXPECTED_HASH="{new_hash}"',
        new_text,
        count=1,
        flags=re.MULTILINE,
    )
    if count != 1:
        raise SystemExit(f"{target.name}: EXPECTED_HASH line not found")
    if "refreshRegistrationIfNeeded" not in new_text:
        new_text = new_text.replace(
            "    @discardableResult\n    static func setEnabled(_ on: Bool) -> Bool {",
            "    static func refreshRegistrationIfNeeded() {\n"
            "        guard #available(macOS 13.0, *), isEnabled() else { return }\n"
            "        _ = setEnabled(true)\n"
            "    }\n\n"
            "    @discardableResult\n    static func setEnabled(_ on: Bool) -> Bool {",
            1,
        )
        new_hash = compute_expected_hash(new_text)
        new_text = re.sub(
            r'^EXPECTED_HASH="[a-f0-9]{64}"',
            f'EXPECTED_HASH="{new_hash}"',
            new_text,
            count=1,
            flags=re.MULTILINE,
        )
    if "refreshRegistrationIfNeeded" not in new_text:
        new_text = new_text.replace(
            "    @discardableResult\n    static func setEnabled(_ on: Bool) -> Bool {",
            "    static func refreshRegistrationIfNeeded() {\n"
            "        guard #available(macOS 13.0, *), isEnabled() else { return }\n"
            "        _ = setEnabled(true)\n"
            "    }\n\n"
            "    @discardableResult\n    static func setEnabled(_ on: Bool) -> Bool {",
            1,
        )
        new_hash = compute_expected_hash(new_text)
        new_text = re.sub(
            r'^EXPECTED_HASH="[a-f0-9]{64}"',
            f'EXPECTED_HASH="{new_hash}"',
            new_text,
            count=1,
            flags=re.MULTILINE,
        )
    target.write_text(new_text, encoding="utf-8")
    print(f"Patched {target.name} (hash {new_hash[:12]}…)")


def compute_expected_hash(text: str) -> str:
    masked = re.sub(
        r'^EXPECTED_HASH=.*',
        'EXPECTED_HASH="MASKED"',
        text,
        count=1,
        flags=re.MULTILINE,
    )
    proc = subprocess.run(
        ["shasum", "-a", "256"],
        input=masked,
        text=True,
        capture_output=True,
        check=True,
    )
    return proc.stdout.split()[0]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("targets", nargs="+", help="Archive .sh files to patch")
    parser.add_argument("--source", type=Path, default=SOURCE)
    args = parser.parse_args()

    source_text = args.source.read_text(encoding="utf-8")
    updater = extract_updater_block(source_text)

    for name in args.targets:
        target = SITE / name if not Path(name).is_absolute() else Path(name)
        if not target.is_file():
            raise SystemExit(f"Missing {target}")
        patch_target(target, updater, target_version(target.read_text(encoding="utf-8")))


if __name__ == "__main__":
    main()