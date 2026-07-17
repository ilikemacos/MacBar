#!/usr/bin/env python3
"""Archive (previous) macOS release metadata for the download page."""
from __future__ import annotations

import versions as v

SITE = v.SITE

# One prior generation per channel (kept on CDN so old bookmarks / update URLs don't 404).
# When you ship a new channel version, move the outgoing id into this list and drop the older row.
ARCHIVE_SPECS: list[dict[str, str]] = [
    {"id": "v1.2.8-Final", "channel": "stable"},
    {"id": "v1.2.12", "channel": "beta"},
    {"id": "v1.3.3-Experimental", "channel": "experimental"},
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
    exp_id = (data.get("experimental") or "").strip()
    rows: list[dict] = []
    for spec in ARCHIVE_SPECS:
        rid = spec["id"]
        if rid in (stable_id, beta_id, exp_id):
            continue
        files = artifact_names(rid)
        # Prefer hosting zip (App ZIP); require at least zip or sh to list the row
        if not files["zip"] and not files["sh"]:
            continue
        sh_hash = ""
        if files["sh"]:
            sh_hash = v.file_sha256(SITE / files["sh"])
        rows.append(
            {
                "id": rid,
                "channel": spec["channel"],
                "sh": files["sh"],
                "pkg": files["pkg"],
                "dmg": files["dmg"],
                "zip": files["zip"],
                "sh_hash": sh_hash,
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