from __future__ import annotations

import json
import shutil
import tarfile
import tempfile
import urllib.request
from pathlib import Path

from . import CURRENT_VERSION, SITE_URL, UPDATE_URL


def check_update() -> tuple[str | None, dict]:
    """Return (remote_linux_version_or_none, full_version_json)."""
    with urllib.request.urlopen(UPDATE_URL, timeout=8) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    remote = data.get("linux", "")
    if remote and remote != CURRENT_VERSION:
        return remote, data
    return None, data


def download_and_apply(remote_version: str, install_root: Path) -> str | None:
    tar_name = f"rNitro-{remote_version}.tar.gz"
    url = f"{SITE_URL}/{tar_name}"
    try:
        with urllib.request.urlopen(url, timeout=120) as resp:
            blob = resp.read()
    except Exception as exc:
        return f"Download failed: {exc}"
    if len(blob) < 10_000:
        return "Downloaded package too small."
    tmp = Path(tempfile.mkdtemp(prefix="rnitro-update-"))
    try:
        archive = tmp / tar_name
        archive.write_bytes(blob)
        extract = tmp / "extract"
        extract.mkdir()
        with tarfile.open(archive, "r:gz") as tf:
            try:
                tf.extractall(extract, filter="data")
            except TypeError:
                tf.extractall(extract)
        src = extract / "linux"
        if not src.is_dir():
            return "Invalid update package (missing linux/)."
        dst_pkg = install_root / "linux"
        if dst_pkg.exists():
            shutil.rmtree(dst_pkg)
        shutil.copytree(src, dst_pkg)
        script = extract / "install-rNitro-linux.sh"
        if script.is_file():
            target = install_root.parent / script.name
            shutil.copy2(script, target)
            target.chmod(0o755)
    except Exception as exc:
        return f"Extract failed: {exc}"
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    return None