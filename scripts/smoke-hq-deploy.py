#!/usr/bin/env python3
"""Post-deploy smoke checks for chopstickshq.com/rnitro (and optional getrnitro).

Usage:
  python3 scripts/smoke-hq-deploy.py
  python3 scripts/smoke-hq-deploy.py --base https://chopstickshq.com/rnitro
"""
from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

SITE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SITE))
import versions as v  # noqa: E402

DEFAULT_BASE = "https://chopstickshq.com/rnitro"


def head(url: str, timeout: float = 25) -> tuple[int, int]:
    req = urllib.request.Request(url, method="HEAD")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            length = int(resp.headers.get("Content-Length") or 0)
            return resp.status, length
    except urllib.error.HTTPError as e:
        return e.code, 0
    except Exception as e:
        print(f"  FAIL {url}: {e}")
        return 0, 0


def get_text(url: str, timeout: float = 25) -> str:
    with urllib.request.urlopen(url, timeout=timeout) as resp:
        return resp.read().decode("utf-8", errors="replace")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--base", default=DEFAULT_BASE, help="Product base URL (no trailing slash)")
    args = ap.parse_args()
    base = args.base.rstrip("/")
    data = v.load()
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    exp = v.experimental_release(data)

    failed = 0
    print(f"Smoke HQ: {base}")
    print(f"  expect stable={stable['id']} beta={beta['id']} exp={exp['id']}")

    # version.json
    vurl = f"{base}/version.json"
    try:
        remote = json.loads(get_text(vurl))
        print(f"  OK version.json latest={remote.get('latest')} beta={remote.get('beta')} exp={remote.get('experimental')}")
        if remote.get("latest") != stable["id"]:
            print(f"  FAIL stable mismatch remote={remote.get('latest')}")
            failed += 1
        if remote.get("beta") != beta["id"]:
            print(f"  FAIL beta mismatch remote={remote.get('beta')}")
            failed += 1
        if remote.get("experimental") != exp["id"]:
            print(f"  FAIL experimental mismatch remote={remote.get('experimental')}")
            failed += 1
    except Exception as e:
        print(f"  FAIL version.json: {e}")
        failed += 1

    # ZIPs
    for label, meta in (("stable", stable), ("beta", beta), ("experimental", exp)):
        z = meta.get("zip")
        if not z:
            continue
        url = f"{base}/{z}"
        status, length = head(url)
        ok = status == 200 and length >= 1_400_000
        print(f"  {'OK' if ok else 'FAIL'} {label} {z} HTTP {status} {length/1_048_576:.1f} MB")
        if not ok:
            failed += 1

    # HTML pages + T&C strings
    for path, needles in (
        ("/", ["Stable vs Beta vs Experimental", "disagreeTcAndGoHome", "tc-remember"]),
        ("/terms.html", ["Terms", "AS IS"]),
        ("/faq.html", ["FAQ", "rNitro"]),
        ("/privacy.html", ["Privacy"]),
    ):
        url = base + path if path != "/" else base + "/"
        try:
            html = get_text(url)
            missing = [n for n in needles if n not in html]
            if missing:
                print(f"  FAIL {url} missing {missing}")
                failed += 1
            else:
                print(f"  OK {path} ({len(html)} bytes)")
        except Exception as e:
            print(f"  FAIL {url}: {e}")
            failed += 1

    # Optional archive ZIPs listed in version.json
    for row in data.get("archive") or []:
        z = row.get("zip")
        if not z:
            continue
        # only check recent experimental archives if present locally expectation
        if "Experimental" not in row.get("id", ""):
            continue
        status, length = head(f"{base}/{z}")
        if status == 200:
            print(f"  OK archive {z} ({length/1_048_576:.1f} MB)")
        else:
            print(f"  WARN archive missing {z} HTTP {status}")

    if failed:
        print(f"\n{failed} check(s) failed")
        return 1
    print("\nAll smoke checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
