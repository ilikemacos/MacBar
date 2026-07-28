#!/usr/bin/env python3
"""Build, install, and launch rNitro Experimental on this Mac."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

SITE = Path(__file__).resolve().parent
sys.path.insert(0, str(SITE))

import versions as v


def launch_experimental(*, quiet: bool = False) -> None:
    data = v.load()
    exp = v.experimental_release(data)
    source = exp.get("source_sh") or "install-rNitro-experimental.sh"
    script = SITE / source
    if not script.is_file():
        # Fall back to versioned sh if present
        script = SITE / exp["sh"]
    if not script.is_file():
        raise SystemExit(f"Missing experimental installer: {source}")
    print(f"\n→ Experimental launch: {script.name} ({exp['id']})")
    subprocess.run(["bash", str(script)], cwd=SITE, check=True)


def main() -> None:
    launch_experimental()


if __name__ == "__main__":
    main()
