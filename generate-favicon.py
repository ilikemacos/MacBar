#!/usr/bin/env python3
"""Build favicon.ico from PNG sizes (no dependencies)."""
from __future__ import annotations

import struct
import subprocess
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
ICNS = Path.home() / "Applications/rNitro.app/Contents/Resources/AppIcon.icns"


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as f:
        f.seek(16)
        w, h = struct.unpack(">II", f.read(8))
    return w, h


def write_ico(png_paths: list[Path], out: Path) -> None:
    images = [(p, p.read_bytes()) for p in png_paths]
    header = struct.pack("<HHH", 0, 1, len(images))
    entries = b""
    blobs = b""
    offset = 6 + 16 * len(images)
    for path, data in images:
        w, h = png_size(path)
        w_byte = 0 if w >= 256 else w
        h_byte = 0 if h >= 256 else h
        entries += struct.pack(
            "<BBBBHHII",
            w_byte,
            h_byte,
            0,
            0,
            1,
            32,
            len(data),
            offset,
        )
        blobs += data
        offset += len(data)
    out.write_bytes(header + entries + blobs)


def main() -> None:
    if not ICNS.is_file():
        raise SystemExit(f"App icon not found: {ICNS}")

    tmp = SCRIPT_DIR / ".favicon-tmp"
    tmp.mkdir(exist_ok=True)
    sizes = {
        "favicon-16.png": 16,
        "favicon-32.png": 32,
        "favicon.png": 32,
        "favicon-192.png": 192,
        "apple-touch-icon.png": 180,
    }
    for name, px in sizes.items():
        out = SCRIPT_DIR / name if name != "favicon-16.png" and name != "favicon-32.png" else tmp / name
        subprocess.run(
            ["sips", "-s", "format", "png", str(ICNS), "--out", str(out), "-z", str(px), str(px)],
            check=True,
            stdout=subprocess.DEVNULL,
        )

    write_ico([tmp / "favicon-16.png", tmp / "favicon-32.png"], SCRIPT_DIR / "favicon.ico")
    for f in tmp.iterdir():
        f.unlink()
    tmp.rmdir()
    print(f"Wrote favicons in {SCRIPT_DIR}")


if __name__ == "__main__":
    main()