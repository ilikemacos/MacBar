#!/usr/bin/env python3
"""Package rNitro terminal CLI for website download."""
from __future__ import annotations

import tarfile
from pathlib import Path

SITE = Path(__file__).resolve().parent
CLI_DIR = SITE / "cli"
OUT_NAME = "rNitro-CLI.tar.gz"
FILES = ("rnitro", "monitor.py", "tui.py", "install-cli.sh")


def build(out: Path | None = None) -> Path:
    out = out or (SITE / OUT_NAME)
    if out.exists():
        out.unlink()
    with tarfile.open(out, "w:gz") as tf:
        for name in FILES:
            path = CLI_DIR / name
            if not path.is_file():
                raise SystemExit(f"Missing CLI file: {path}")
            tf.add(path, arcname=name)
            print(f"  + {name}")
    size = out.stat().st_size
    print(f"Created {out} ({size / 1024:.1f} KB)")
    return out


if __name__ == "__main__":
    build()