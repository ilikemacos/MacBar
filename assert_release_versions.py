#!/usr/bin/env python3
"""Fail the build if App ZIP Info.plist versions don't match version.json."""
from __future__ import annotations

import json
import subprocess
import tempfile
import zipfile
from pathlib import Path

import versions as v

SITE = v.SITE


def plist_short_version(app_root: Path) -> str:
    plist = app_root / "Contents" / "Info.plist"
    if not plist.is_file():
        # find nested
        matches = list(app_root.rglob("Info.plist"))
        if not matches:
            raise SystemExit(f"No Info.plist under {app_root}")
        plist = matches[0]
    return subprocess.check_output(
        ["/usr/libexec/PlistBuddy", "-c", "Print :CFBundleShortVersionString", str(plist)],
        text=True,
    ).strip()


def version_in_zip(zip_path: Path) -> str:
    with tempfile.TemporaryDirectory(prefix="rnitro-assert-") as tmp:
        with zipfile.ZipFile(zip_path) as zf:
            zf.extractall(tmp)
        root = Path(tmp)
        for name in ("rNitro.app", "rNitro-Stable.app", "rNitro-Beta.app"):
            app = root / name
            if app.is_dir():
                return plist_short_version(app)
        apps = list(root.rglob("*.app"))
        if not apps:
            raise SystemExit(f"No .app in {zip_path.name}")
        return plist_short_version(apps[0])


def main() -> None:
    data = v.load()
    channel_meta = {
        "stable": v.stable_release(data),
        "beta": v.beta_release(data),
        "experimental": v.experimental_release(data),
    }
    failed = False
    for label, meta in channel_meta.items():
        expect = meta["id"]
        zip_name = meta["zip"]
        path = SITE / zip_name
        if not path.is_file():
            print(f"FAIL {label}: missing {zip_name}")
            failed = True
            continue
        got = version_in_zip(path)
        ok = got == expect
        print(f"{'OK' if ok else 'FAIL'} {label}: zip={zip_name} plist={got!r} expect={expect!r}")
        if not ok:
            failed = True
        for kind in ("pkg", "dmg"):
            name = meta.get(kind)
            if not name:
                continue
            p = SITE / name
            if not p.is_file():
                print(f"FAIL {label}: missing {kind} {name}")
                failed = True
            else:
                print(f"OK {label}: {kind}={name} present ({p.stat().st_size:,} bytes)")
    if failed:
        raise SystemExit(1)
    print("All release version asserts passed.")


if __name__ == "__main__":
    main()
