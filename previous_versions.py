#!/usr/bin/env python3
"""Archive (previous) macOS release metadata for the download page."""
from __future__ import annotations

import versions as v

SITE = v.SITE

ARCHIVE_SPECS: list[dict[str, str]] = [
    {"id": "v8.3.9-Beta-arm64", "channel": "beta"},
    {"id": "v8.3.8-Beta-arm64", "channel": "beta"},
    {"id": "v8.3.7-Beta-arm64", "channel": "beta"},
    {"id": "v8.3.6-Beta-arm64", "channel": "beta"},
    {"id": "v8.3.5-Beta-arm64", "channel": "beta"},
    {"id": "v8.3.4-Final-arm64", "channel": "stable"},
    {"id": "v8.2.8-Beta-arm64", "channel": "beta"},
    {"id": "v8.3.3-Beta-arm64", "channel": "beta"},
    {"id": "v8.3.2-Beta-arm64", "channel": "beta"},
    {"id": "v8.3.1-Final-arm64", "channel": "stable"},
    {"id": "v8.3.1-Beta-arm64", "channel": "beta"},
    {"id": "v8.2.9-Final-arm64", "channel": "stable"},
    {"id": "v8.2.7-Beta-arm64", "channel": "beta"},
    {"id": "v8.2.6-Beta-arm64", "channel": "beta"},
    {"id": "v8.2.5-Final-arm64", "channel": "stable"},
    {"id": "v8.2.5-Beta-arm64", "channel": "beta"},
    {"id": "v8.2.4-Final-arm64", "channel": "stable"},
    {"id": "v8.2.4-Beta-arm64", "channel": "beta"},
    {"id": "v8.2.3-Beta-arm64", "channel": "beta"},
    {"id": "v8.2.2-Final-arm64", "channel": "stable"},
    {"id": "v8.2.1-Beta-arm64", "channel": "beta"},
    {"id": "v8.1.1-Beta-arm64", "channel": "beta"},
    {"id": "v7.3.2-Final-arm64", "channel": "stable"},
    {"id": "v7.0.1a-Final-arm64", "channel": "stable"},
    {"id": "v7.0.2-Beta-arm64", "channel": "beta"},
    {"id": "v7.0.1-Beta-arm64", "channel": "beta"},
]


def artifact_names(release_id: str) -> dict[str, str | None]:
    base = f"rNitro-{release_id}"
    sh = f"{base}.sh"
    pkg = f"{base}.pkg"
    dmg = f"{base}.dmg"
    zip_name = f"{base}.zip"
    return {
        "sh": sh if (SITE / sh).is_file() else None,
        "pkg": pkg if (SITE / pkg).is_file() else None,
        "dmg": dmg if (SITE / dmg).is_file() else None,
        "zip": zip_name if (SITE / zip_name).is_file() else None,
    }


def build_archive(data: dict | None = None) -> list[dict]:
    data = data or v.load()
    stable_id = v.stable_id(data)
    beta_id = v.beta_id(data)
    rows: list[dict] = []
    for spec in ARCHIVE_SPECS:
        rid = spec["id"]
        if rid in (stable_id, beta_id):
            continue
        files = artifact_names(rid)
        if not files["sh"]:
            continue
        sh_path = SITE / files["sh"]
        rows.append(
            {
                "id": rid,
                "channel": spec["channel"],
                "sh": files["sh"],
                "pkg": files["pkg"],
                "dmg": files["dmg"],
                "zip": files["zip"],
                "sh_hash": v.file_sha256(sh_path),
            }
        )
    return rows


def deploy_files(archive: list[dict], *, website: bool = False) -> list[str]:
    """website=True: .sh + .zip for archive rows. Full deploy includes pkg/dmg too."""
    names: list[str] = []
    keys = ("sh", "zip") if website else ("sh", "zip", "pkg", "dmg")
    for row in archive:
        for key in keys:
            fname = row.get(key)
            if fname and (SITE / fname).is_file():
                names.append(fname)
    return names