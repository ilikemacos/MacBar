#!/usr/bin/env python3
"""Build, install, and launch rNitro Beta on this Mac."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

SITE = Path(__file__).resolve().parent
sys.path.insert(0, str(SITE))

import versions as v


def launch_beta(*, quiet: bool = False) -> None:
    data = v.load()
    beta = v.beta_release(data)
    script = SITE / beta["source_sh"]
    if not script.is_file():
        raise SystemExit(f"Missing beta installer: {script}")
    print(f"\n→ Beta launch: {script.name} ({beta['id']})")
    subprocess.run(["bash", str(script)], cwd=SITE, check=True)


def main() -> None:
    launch_beta()


if __name__ == "__main__":
    main()