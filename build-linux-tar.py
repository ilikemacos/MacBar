#!/usr/bin/env python3
"""Package Linux rNitro app into release tarball."""
from __future__ import annotations

import io
import tarfile
from pathlib import Path

SITE = Path(__file__).resolve().parent
TAR_NAME = "rNitro-v0.1-Linux-Beta-Pre-release-x64.tar.gz"


def main() -> None:
    linux_dir = SITE / "linux"
    installer = SITE / "install-rNitro-linux.sh"
    readme = SITE / "linux" / "README.txt"
    out = SITE / TAR_NAME

    if not linux_dir.is_dir():
        raise SystemExit(f"Missing {linux_dir}")
    if not installer.is_file():
        raise SystemExit(f"Missing {installer}")

    if out.is_file():
        out.unlink()

    with tarfile.open(out, "w:gz") as tf:
        tf.add(linux_dir, arcname="linux")
        tf.add(installer, arcname=installer.name)
        if readme.is_file():
            tf.add(readme, arcname="linux/README.txt")
        else:
            info = tarfile.TarInfo(name="linux/README.txt")
            body = (
                "rNitro Linux v0.1 Beta Pre-release\n"
                "==================================\n\n"
                "Extract and run:\n"
                "  bash install-rNitro-linux.sh\n\n"
                "Requires Python 3.10+, GTK 4, libadwaita, python3-gi.\n"
                "Optional: psutil, lm-sensors, nvidia-smi, Ayatana AppIndicator.\n"
            ).encode("utf-8")
            info.size = len(body)
            tf.addfile(info, io.BytesIO(body))

    print(f"Created {out} ({out.stat().st_size / 1024:.0f} KB)")


if __name__ == "__main__":
    main()