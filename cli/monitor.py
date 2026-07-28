"""System metrics for rNitro terminal UI (macOS + Linux)."""

from __future__ import annotations

import os
import platform
import re
import socket
import subprocess
import sys
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path

try:
    import psutil  # type: ignore
except ImportError:
    psutil = None  # type: ignore

HISTORY_LEN = 60


@dataclass
class ProcessRow:
    pid: int
    name: str
    cpu: float
    mem_mb: float


@dataclass
class Snapshot:
    hostname: str = ""
    uptime_s: float = 0.0
    load: tuple[float, float, float] = (0.0, 0.0, 0.0)
    cpu_percent: float = 0.0
    core_count: int = 0
    cpu_name: str = "CPU"
    mem_used_gb: float = 0.0
    mem_total_gb: float = 0.0
    mem_percent: float = 0.0
    swap_gb: float = 0.0
    disk_used_gb: float = 0.0
    disk_total_gb: float = 0.0
    disk_percent: float = 0.0
    disk_read_mbps: float = 0.0
    disk_write_mbps: float = 0.0
    net_iface: str = ""
    net_ip: str = ""
    net_down_mbps: float = 0.0
    net_up_mbps: float = 0.0
    battery_pct: int | None = None
    battery_status: str = ""
    temp_c: float | None = None
    top_cpu: list[ProcessRow] = field(default_factory=list)
    top_mem: list[ProcessRow] = field(default_factory=list)
    cpu_history: list[float] = field(default_factory=list)
    mem_history: list[float] = field(default_factory=list)


def _run(cmd: list[str], timeout: float = 3.0) -> str:
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL, timeout=timeout)
    except (subprocess.SubprocessError, FileNotFoundError):
        return ""


def _sysctl(name: str) -> str:
    return _run(["sysctl", "-n", name]).strip()


def _display_name_from_command(command: str) -> str:
    cmd = command.strip()
    if not cmd:
        return "?"
    app = re.search(r"/([^/]+)\.app/", cmd)
    if app:
        return app.group(1)[:20]
    token = cmd.split()[0]
    return (Path(token).name or "?")[:20]


class MetricsEngine:
    def __init__(self, poll_interval: float = 1.0) -> None:
        self.poll_interval = poll_interval
        self.snapshot = Snapshot(hostname=socket.gethostname())
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None
        self._last_disk: object | None = None
        self._last_disk_ts = 0.0
        self._last_net: object | None = None
        self._last_net_ts = 0.0
        self._proc_cpu_cache: dict[int, tuple[float, float]] = {}
        self._darwin_vm_pagesize = 4096
        if sys.platform == "darwin":
            try:
                self._darwin_vm_pagesize = int(_sysctl("vm.pagesize"))
            except ValueError:
                pass
            if psutil:
                psutil.cpu_percent(interval=None)

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return
        self._stop.clear()
        self._thread = threading.Thread(target=self._loop, daemon=True, name="rnitro-cli-monitor")
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()

    def _loop(self) -> None:
        while not self._stop.is_set():
            self.refresh()
            self._stop.wait(self.poll_interval)

    def refresh(self) -> None:
        snap = Snapshot(hostname=socket.gethostname())
        now = time.time()
        if psutil:
            self._refresh_psutil(snap, now)
        elif sys.platform == "darwin":
            self._refresh_darwin(snap, now)
        else:
            self._refresh_linux_proc(snap, now)
        self._append_history(snap)
        self.snapshot = snap

    def _append_history(self, snap: Snapshot) -> None:
        prev = self.snapshot
        cpu_h = list(prev.cpu_history)
        mem_h = list(prev.mem_history)
        cpu_h.append(snap.cpu_percent)
        mem_h.append(snap.mem_percent)
        snap.cpu_history = cpu_h[-HISTORY_LEN:]
        snap.mem_history = mem_h[-HISTORY_LEN:]

    def _refresh_psutil(self, snap: Snapshot, now: float) -> None:
        snap.cpu_percent = psutil.cpu_percent(interval=None)
        snap.core_count = psutil.cpu_count(logical=True) or 0
        try:
            snap.cpu_name = platform.processor() or "CPU"
        except Exception:
            snap.cpu_name = "CPU"
        try:
            snap.load = os.getloadavg()
        except (AttributeError, OSError):
            pass
        snap.uptime_s = max(0.0, now - psutil.boot_time())

        vm = psutil.virtual_memory()
        snap.mem_used_gb = vm.used / (1024**3)
        snap.mem_total_gb = vm.total / (1024**3)
        snap.mem_percent = vm.percent
        snap.swap_gb = psutil.swap_memory().used / (1024**3)

        root = psutil.disk_usage("/")
        snap.disk_used_gb = root.used / (1024**3)
        snap.disk_total_gb = root.total / (1024**3)
        snap.disk_percent = root.percent

        dio = psutil.disk_io_counters()
        if dio and self._last_disk and self._last_disk_ts:
            dt = max(now - self._last_disk_ts, 0.001)
            snap.disk_read_mbps = (dio.read_bytes - self._last_disk.read_bytes) / dt / (1024**2)
            snap.disk_write_mbps = (dio.write_bytes - self._last_disk.write_bytes) / dt / (1024**2)
        if dio:
            self._last_disk = dio
            self._last_disk_ts = now

        nio = psutil.net_io_counters(pernic=False)
        if nio and self._last_net and self._last_net_ts:
            dt = max(now - self._last_net_ts, 0.001)
            snap.net_down_mbps = (nio.bytes_recv - self._last_net.bytes_recv) / dt / (1024**2)
            snap.net_up_mbps = (nio.bytes_sent - self._last_net.bytes_sent) / dt / (1024**2)
        if nio:
            self._last_net = nio
            self._last_net_ts = now

        addrs = psutil.net_if_addrs()
        stats = psutil.net_if_stats()
        for iface, st in sorted(stats.items()):
            if not st.isup or iface in ("lo", "lo0", "gif0", "stf0"):
                continue
            snap.net_iface = iface
            for addr in addrs.get(iface, []):
                fam = getattr(addr.family, "name", str(addr.family))
                if fam in ("AF_INET", "2"):
                    snap.net_ip = addr.address
                    break
            if snap.net_ip:
                break

        if sys.platform == "darwin":
            self._darwin_battery(snap)
        elif hasattr(psutil, "sensors_battery"):
            bat = psutil.sensors_battery()
            if bat:
                snap.battery_pct = int(bat.percent)
                snap.battery_status = "charging" if bat.power_plugged else "on battery"

        snap.top_cpu, snap.top_mem = self._top_processes_psutil()

    def _top_processes_psutil(self, n: int = 8) -> tuple[list[ProcessRow], list[ProcessRow]]:
        rows: list[ProcessRow] = []
        for proc in psutil.process_iter(["pid", "name", "cpu_percent", "memory_info"]):
            try:
                info = proc.info
                pid = int(info["pid"])
                name = (info.get("name") or "?")[:20]
                cpu = float(info.get("cpu_percent") or 0.0)
                mem_info = info.get("memory_info")
                mem_mb = (mem_info.rss / (1024**2)) if mem_info else 0.0
                rows.append(ProcessRow(pid=pid, name=name, cpu=cpu, mem_mb=mem_mb))
            except (psutil.NoSuchProcess, psutil.AccessDenied, TypeError, ValueError):
                continue
        by_cpu = sorted(rows, key=lambda r: r.cpu, reverse=True)[:n]
        by_mem = sorted(rows, key=lambda r: r.mem_mb, reverse=True)[:n]
        return by_cpu, by_mem

    def _refresh_darwin(self, snap: Snapshot, now: float) -> None:
        snap.core_count = int(_sysctl("hw.logicalcpu") or "0") or (os.cpu_count() or 1)
        snap.cpu_name = _sysctl("machdep.cpu.brand_string") or _sysctl("hw.model") or "Apple Silicon"
        try:
            snap.load = os.getloadavg()
        except OSError:
            pass

        boot = _sysctl("kern.boottime")
        m = re.search(r"sec\s*=\s*(\d+)", boot)
        if m:
            snap.uptime_s = max(0.0, now - int(m.group(1)))

        snap.cpu_percent = self._darwin_cpu_percent()

        page = self._darwin_vm_pagesize
        mem_total = int(_sysctl("hw.memsize") or "0")
        snap.mem_total_gb = mem_total / (1024**3)
        pages: dict[str, int] = {}
        for line in _run(["vm_stat"]).splitlines():
            if ":" not in line:
                continue
            key, val = line.split(":", 1)
            num = re.sub(r"[^\d]", "", val)
            if num:
                pages[key.strip()] = int(num)
        free = pages.get("Pages free", 0) + pages.get("Pages speculative", 0)
        inactive = pages.get("Pages inactive", 0)
        wired = pages.get("Pages wired down", 0) * page
        compressed = pages.get("Pages occupied by compressor", 0) * page
        used = mem_total - free * page - inactive * page
        snap.mem_used_gb = max(0.0, used / (1024**3))
        snap.mem_percent = (used / mem_total * 100.0) if mem_total else 0.0
        swap_used = pages.get("Swapouts", 0)  # rough; macOS swap is opaque
        snap.swap_gb = max(0.0, (wired + compressed) / (1024**3) * 0.01)

        df = _run(["df", "-g", "/"]).splitlines()
        if len(df) >= 2:
            cols = df[1].split()
            if len(cols) >= 4:
                total_g = float(cols[1])
                used_g = float(cols[2])
                snap.disk_total_gb = total_g
                snap.disk_used_gb = used_g
                snap.disk_percent = (used_g / total_g * 100.0) if total_g else 0.0

        iostat = _run(["iostat", "-d", "-c", "2", "-n", "0"])
        lines = [ln for ln in iostat.splitlines() if ln.strip() and not ln.startswith(" ") is False]
        # last data line after header blocks
        data_lines = [ln for ln in iostat.splitlines() if re.match(r"^\s*\d", ln)]
        if len(data_lines) >= 2:
            cols = data_lines[-1].split()
            if len(cols) >= 3:
                try:
                    snap.disk_read_mbps = float(cols[-2]) / 1024.0
                    snap.disk_write_mbps = float(cols[-1]) / 1024.0
                except ValueError:
                    pass

        snap.net_iface, snap.net_ip, snap.net_down_mbps, snap.net_up_mbps = self._darwin_net_io()

        self._darwin_battery(snap)
        snap.top_cpu, snap.top_mem = self._top_processes_ps()

    def _darwin_cpu_percent(self) -> float:
        out = _run(["top", "-l", "1", "-n", "0", "-s", "0"])
        for line in out.splitlines():
            if "CPU usage" in line:
                m = re.search(r"([\d.]+)% idle", line)
                if m:
                    return max(0.0, min(100.0, 100.0 - float(m.group(1))))
        return 0.0

    def _darwin_net_io(self) -> tuple[str, str, float, float]:
        out = _run(["netstat", "-ibn"])
        iface = ip = ""
        best_rx = best_tx = 0
        for line in out.splitlines():
            parts = line.split()
            if len(parts) < 10:
                continue
            name = parts[0]
            if name in ("Name", "lo0", "gif0", "stf0"):
                continue
            try:
                rx = int(parts[6])
                tx = int(parts[9])
            except ValueError:
                continue
            if rx + tx > best_rx + best_tx:
                best_rx, best_tx = rx, tx
                iface = name
                for p in parts:
                    if re.match(r"^\d+\.\d+\.\d+\.\d+$", p):
                        ip = p
                        break
        down = up = 0.0
        if self._last_net and self._last_net_ts:
            dt = max(time.time() - self._last_net_ts, 0.001)
            down = max(0.0, (best_rx - self._last_net[0]) / dt / (1024**2))
            up = max(0.0, (best_tx - self._last_net[1]) / dt / (1024**2))
        self._last_net = (best_rx, best_tx)
        self._last_net_ts = time.time()
        return iface, ip, down, up

    def _darwin_battery(self, snap: Snapshot) -> None:
        out = _run(["pmset", "-g", "batt"])
        m = re.search(r"(\d+)%;\s*(\w+)", out)
        if m:
            snap.battery_pct = int(m.group(1))
            snap.battery_status = m.group(2).lower()

    def _top_processes_ps(self, n: int = 8) -> tuple[list[ProcessRow], list[ProcessRow]]:
        out = _run(["ps", "-axo", "pid=,%cpu=,rss=,command="])
        rows: list[ProcessRow] = []
        for line in out.splitlines():
            line = line.strip()
            if not line:
                continue
            m = re.match(r"(\d+)\s+([\d.]+)\s+(\d+)\s+(.+)", line)
            if not m:
                continue
            pid, cpu, rss, command = m.groups()
            rows.append(
                ProcessRow(
                    pid=int(pid),
                    name=_display_name_from_command(command),
                    cpu=float(cpu),
                    mem_mb=int(rss) / 1024.0,
                )
            )
        return (
            sorted(rows, key=lambda r: r.cpu, reverse=True)[:n],
            sorted(rows, key=lambda r: r.mem_mb, reverse=True)[:n],
        )

    def _refresh_linux_proc(self, snap: Snapshot, now: float) -> None:
        # Minimal /proc fallback when psutil missing on Linux
        snap.core_count = os.cpu_count() or 1
        try:
            snap.load = os.getloadavg()
        except OSError:
            pass
        try:
            uptime = float(Path("/proc/uptime").read_text().split()[0])
            snap.uptime_s = uptime
        except OSError:
            pass
        try:
            line = Path("/proc/stat").read_text().splitlines()[0]
            parts = [int(x) for x in line.split()[1:]]
            idle = parts[3] + (parts[4] if len(parts) > 4 else 0)
            total = sum(parts)
            if not hasattr(self, "_linux_cpu_prev"):
                self._linux_cpu_prev = (total, idle)
            pt, pi = self._linux_cpu_prev
            dt = total - pt
            if dt:
                snap.cpu_percent = 100.0 * (1.0 - (idle - pi) / dt)
            self._linux_cpu_prev = (total, idle)
        except (OSError, ValueError, IndexError):
            snap.cpu_percent = 0.0
        snap.top_cpu, snap.top_mem = self._top_processes_ps()