from __future__ import annotations

import os
import re
import shutil
import subprocess
import threading
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class Leftover:
    path: str
    label: str
    bytes: int = 0


@dataclass
class InstalledApp:
    app_id: str
    name: str
    exec_path: str
    desktop_path: str
    icon: str = ""
    last_used: float | None = None
    app_bytes: int | None = None
    leftovers: list[Leftover] = field(default_factory=list)
    leftovers_loaded: bool = False


class AppCleaner:
    def __init__(self) -> None:
        self.apps: list[InstalledApp] = []
        self.is_scanning = False
        self.is_enriching = False
        self.last_error: str | None = None

    def scan(self, on_done: callable | None = None) -> None:
        def work() -> None:
            self.is_scanning = True
            self.last_error = None
            try:
                self.apps = _list_desktop_apps()
            except Exception as exc:
                self.last_error = str(exc)
                self.apps = []
            self.is_scanning = False
            self._enrich_sizes(on_done)

        threading.Thread(target=work, daemon=True, name="rnitro-cleaner-scan").start()

    def _enrich_sizes(self, on_done: callable | None = None) -> None:
        def work() -> None:
            self.is_enriching = True
            for app in self.apps:
                if app.exec_path and os.path.isfile(app.exec_path):
                    app.app_bytes = _du_bytes(app.exec_path)
                elif app.exec_path and os.path.isdir(app.exec_path):
                    app.app_bytes = _du_bytes(app.exec_path)
            self.is_enriching = False
            if on_done:
                on_done()

        threading.Thread(target=work, daemon=True, name="rnitro-cleaner-size").start()

    def load_leftovers(self, app: InstalledApp, on_done: callable | None = None) -> None:
        def work() -> None:
            app.leftovers = _find_leftovers(app)
            app.leftovers_loaded = True
            if on_done:
                on_done()

        threading.Thread(target=work, daemon=True, name="rnitro-cleaner-leftovers").start()

    def remove(self, app: InstalledApp, leftover_paths: list[str]) -> str | None:
        paths = list(leftover_paths)
        if app.desktop_path and os.path.exists(app.desktop_path):
            if str(Path(app.desktop_path).parent) == str(Path.home() / ".local/share/applications"):
                paths.append(app.desktop_path)
        for p in paths:
            try:
                if os.path.isdir(p):
                    shutil.rmtree(p)
                elif os.path.isfile(p) or os.path.islink(p):
                    os.remove(p)
            except OSError as exc:
                return str(exc)
        self.apps = [a for a in self.apps if a.app_id != app.app_id]
        return None


def _desktop_dirs() -> list[Path]:
    dirs = [Path("/usr/share/applications"), Path.home() / ".local/share/applications"]
    extra = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    for base in extra:
        p = Path(base.strip()) / "applications"
        if p.is_dir() and p not in dirs:
            dirs.append(p)
    return [d for d in dirs if d.is_dir()]


def _list_desktop_apps() -> list[InstalledApp]:
    apps: dict[str, InstalledApp] = {}
    for d in _desktop_dirs():
        for f in sorted(d.glob("*.desktop")):
            if f.name.startswith("rNitro") or f.name.startswith("rnitro"):
                continue
            try:
                text = f.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            if "Type=Application" not in text:
                continue
            if _parse_key(text, "NoDisplay") == "true":
                continue
            if _parse_key(text, "Hidden") == "true":
                continue
            name = _parse_key(text, "Name") or f.stem
            exec_line = _parse_key(text, "Exec") or ""
            exec_path = _normalize_exec(exec_line)
            icon = _parse_key(text, "Icon") or ""
            app_id = f.stem
            if app_id in apps:
                continue
            apps[app_id] = InstalledApp(
                app_id=app_id,
                name=name,
                exec_path=exec_path,
                desktop_path=str(f),
                icon=icon,
                last_used=_mtime(exec_path) if exec_path else _mtime(str(f)),
            )
    out = list(apps.values())
    out.sort(key=lambda a: a.last_used or 0, reverse=True)
    return out


def _normalize_exec(exec_line: str) -> str:
    if not exec_line:
        return ""
    line = exec_line.split("%", 1)[0].strip()
    parts = line.split()
    if not parts:
        return ""
    cmd = parts[0]
    if cmd.startswith("/"):
        return cmd
    which = shutil.which(cmd)
    return which or cmd


def _parse_key(text: str, key: str) -> str | None:
    for line in text.splitlines():
        if line.startswith(f"{key}="):
            return line.split("=", 1)[1].strip()
    return None


def _mtime(path: str) -> float | None:
    try:
        return os.path.getmtime(path)
    except OSError:
        return None


def _du_bytes(path: str) -> int:
    try:
        out = subprocess.check_output(["du", "-sk", path], text=True, timeout=30, stderr=subprocess.DEVNULL)
        return int(out.split()[0]) * 1024
    except (subprocess.SubprocessError, ValueError):
        total = 0
        if os.path.isfile(path):
            try:
                return os.path.getsize(path)
            except OSError:
                return 0
        for root, _dirs, files in os.walk(path):
            for name in files:
                try:
                    total += os.path.getsize(os.path.join(root, name))
                except OSError:
                    pass
        return total


def _slug_variants(name: str, app_id: str) -> list[str]:
    variants = {app_id, name, name.replace(" ", ""), name.lower(), name.lower().replace(" ", "-")}
    variants.add(re.sub(r"[^a-zA-Z0-9]+", "", name))
    variants.add(re.sub(r"[^a-zA-Z0-9]+", "-", name.lower()).strip("-"))
    return [v for v in variants if v]


def _find_leftovers(app: InstalledApp) -> list[Leftover]:
    home = Path.home()
    bases = [
        ("Local share", home / ".local/share"),
        ("Config", home / ".config"),
        ("Cache", home / ".cache"),
    ]
    out: list[Leftover] = []
    seen: set[str] = set()
    for label, base in bases:
        if not base.is_dir():
            continue
        for slug in _slug_variants(app.name, app.app_id):
            path = base / slug
            key = str(path)
            if key in seen or not path.exists():
                continue
            seen.add(key)
            out.append(Leftover(key, label, _du_bytes(key)))
    return out


def fmt_bytes(n: int | None) -> str:
    if n is None:
        return "…"
    if n < 1024:
        return f"{n} B"
    if n < 1024 ** 2:
        return f"{n / 1024:.1f} KB"
    if n < 1024 ** 3:
        return f"{n / (1024 ** 2):.1f} MB"
    return f"{n / (1024 ** 3):.2f} GB"