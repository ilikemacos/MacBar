#!/usr/bin/env python3
"""Package rNitro Refresh CLI (v0.3) for website download."""
from __future__ import annotations

import tarfile
from pathlib import Path

SITE = Path(__file__).resolve().parent
CLI_DIR = SITE / "cli"
OUT_NAME = "rNitro-CLI-Refresh.tar.gz"
FILES = ("rnitro", "monitor.py", "tui.py", "ask.py", "install-cli.sh")


def build(out: Path | None = None) -> Path:
    out = out or (SITE / OUT_NAME)
    if out.exists():
        out.unlink()
    tui = CLI_DIR / "tui.py"
    tui_text = tui.read_text(encoding="utf-8")
    tui_refresh = tui_text.replace('VERSION = "v0.2-cli"', 'VERSION = "v0.3-refresh-cli"', 1)
    tui.write_text(tui_refresh, encoding="utf-8")
    try:
        return _write_tar(out)
    finally:
        tui.write_text(tui_text, encoding="utf-8")


def _write_tar(out: Path) -> Path:
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