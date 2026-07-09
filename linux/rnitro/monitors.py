from __future__ import annotations

import os
import re
import subprocess
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path

try:
    import psutil  # type: ignore
except ImportError:
    psutil = None  # type: ignore


@dataclass
class MonitorSnapshot:
    cpu_percent: float = 0.0
    cpu_name: str = "CPU"
    load_avg: tuple[float, float, float] = (0.0, 0.0, 0.0)
    core_count: int = 0
    mem_used_gb: float = 0.0
    mem_total_gb: float = 0.0
    mem_percent: float = 0.0
    swap_gb: float = 0.0
    disk_used_gb: float = 0.0
    disk_total_gb: float = 0.0
    disk_percent: float = 0.0
    disk_read_mbps: float = 0.0
    disk_write_mbps: float = 0.0
    net_down_mbps: float = 0.0
    net_up_mbps: float = 0.0
    net_iface: str = ""
    net_ip: str = ""
    battery_present: bool = False
    battery_percent: int = 0
    battery_status: str = "N/A"
    gpu_percent: float = 0.0
    gpu_name: str = "N/A"
    sensors: list[tuple[str, str]] = field(default_factory=list)
    cpu_history: list[float] = field(default_factory=list)
    mem_history: list[float] = field(default_factory=list)
    power_note: str = ""


class _ProcFallback:
    """Lightweight /proc reader when psutil is unavailable."""

    def __init__(self) -> None:
        self._prev_cpu: tuple[int, int] | None = None
        self._prev_disk: tuple[int, int] | None = None
        self._prev_net: tuple[int, int] | None = None
        self._prev_ts = 0.0

    def cpu_percent(self) -> float:
        try:
            line = Path("/proc/stat").read_text(encoding="utf-8").splitlines()[0]
            parts = [int(x) for x in line.split()[1:]]
            idle = parts[3] + (parts[4] if len(parts) > 4 else 0)
            total = sum(parts)
            if self._prev_cpu:
                di = idle - self._prev_cpu[1]
                dt = total - self._prev_cpu[0]
                pct = 100.0 * (1.0 - di / dt) if dt else 0.0
            else:
                pct = 0.0
            self._prev_cpu = (total, idle)
            return max(0.0, min(100.0, pct))
        except (OSError, ValueError, IndexError):
            return 0.0

    def cpu_count(self) -> int:
        try:
            return os.cpu_count() or 1
        except OSError:
            return 1

    def memory(self) -> tuple[float, float, float, float]:
        mem_total = mem_avail = swap_used = 0
        try:
            for line in Path("/proc/meminfo").read_text(encoding="utf-8").splitlines():
                if line.startswith("MemTotal:"):
                    mem_total = int(line.split()[1]) * 1024
                elif line.startswith("MemAvailable:"):
                    mem_avail = int(line.split()[1]) * 1024
                elif line.startswith("SwapTotal:"):
                    swap_total = int(line.split()[1]) * 1024
                elif line.startswith("SwapFree:"):
                    swap_free = int(line.split()[1]) * 1024
                    swap_used = max(0, swap_total - swap_free)
        except OSError:
            return 0.0, 0.0, 0.0, 0.0
        used = max(0, mem_total - mem_avail)
        pct = (used / mem_total * 100.0) if mem_total else 0.0
        return used / (1024 ** 3), mem_total / (1024 ** 3), pct, swap_used / (1024 ** 3)

    def disk_usage(self) -> tuple[float, float, float]:
        try:
            st = os.statvfs("/")
            total = st.f_frsize * st.f_blocks
            free = st.f_frsize * st.f_bavail
            used = total - free
            pct = (used / total * 100.0) if total else 0.0
            return used / (1024 ** 3), total / (1024 ** 3), pct
        except OSError:
            return 0.0, 0.0, 0.0

    def disk_io_mbps(self, now: float) -> tuple[float, float]:
        try:
            parts = Path("/proc/diskstats").read_text(encoding="utf-8").splitlines()
            read_sectors = write_sectors = 0
            for line in parts:
                cols = line.split()
                if len(cols) < 14:
                    continue
                if cols[2] in ("loop0", "ram0"):
                    continue
                read_sectors += int(cols[5])
                write_sectors += int(cols[9])
            read_b = read_sectors * 512
            write_b = write_sectors * 512
            if self._prev_disk and self._prev_ts:
                dt = max(now - self._prev_ts, 0.001)
                r = (read_b - self._prev_disk[0]) / dt / (1024 * 1024)
                w = (write_b - self._prev_disk[1]) / dt / (1024 * 1024)
            else:
                r = w = 0.0
            self._prev_disk = (read_b, write_b)
            return max(0.0, r), max(0.0, w)
        except (OSError, ValueError):
            return 0.0, 0.0

    def net_io_mbps(self, now: float) -> tuple[float, float, str, str]:
        iface = ip = ""
        try:
            rx = tx = 0
            for line in Path("/proc/net/dev").read_text(encoding="utf-8").splitlines()[2:]:
                if ":" not in line:
                    continue
                name, rest = line.split(":", 1)
                name = name.strip()
                if name == "lo":
                    continue
                cols = rest.split()
                rx += int(cols[0])
                tx += int(cols[8])
                if not iface:
                    iface = name
            if iface:
                ip = _iface_ipv4(iface)
            if self._prev_net and self._prev_ts:
                dt = max(now - self._prev_ts, 0.001)
                down = (rx - self._prev_net[0]) / dt / (1024 * 1024)
                up = (tx - self._prev_net[1]) / dt / (1024 * 1024)
            else:
                down = up = 0.0
            self._prev_net = (rx, tx)
            return max(0.0, down), max(0.0, up), iface, ip
        except (OSError, ValueError):
            return 0.0, 0.0, "", ""


def _iface_ipv4(iface: str) -> str:
    try:
        out = subprocess.check_output(["ip", "-4", "addr", "show", iface], text=True, timeout=2)
        for line in out.splitlines():
            line = line.strip()
            if line.startswith("inet "):
                return line.split()[1].split("/")[0]
    except (subprocess.SubprocessError, FileNotFoundError):
        pass
    return ""


class SystemMonitor:
    def __init__(self, history_len: int = 60, poll_interval: float = 1.0) -> None:
        self.history_len = history_len
        self.poll_interval = poll_interval
        self.snapshot = MonitorSnapshot()
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None
        self._fallback = _ProcFallback()
        self._last_disk = None
        self._last_net = None
        self._last_disk_ts = 0.0
        self._last_net_ts = 0.0
        self.using_psutil = psutil is not None

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return
        self._stop.clear()
        self._thread = threading.Thread(target=self._loop, daemon=True, name="rnitro-monitor")
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()

    def _loop(self) -> None:
        if psutil:
            psutil.cpu_percent(interval=None)
        while not self._stop.is_set():
            self.refresh()
            self._stop.wait(self.poll_interval)

    def refresh(self) -> None:
        snap = MonitorSnapshot()
        now = time.time()

        if psutil:
            snap.cpu_percent = psutil.cpu_percent(interval=None)
            snap.core_count = psutil.cpu_count(logical=True) or 0
            try:
                snap.load_avg = os.getloadavg()
            except (AttributeError, OSError):
                pass
            vm = psutil.virtual_memory()
            snap.mem_used_gb = vm.used / (1024 ** 3)
            snap.mem_total_gb = vm.total / (1024 ** 3)
            snap.mem_percent = vm.percent
            swap = psutil.swap_memory()
            snap.swap_gb = swap.used / (1024 ** 3)
            root = psutil.disk_usage("/")
            snap.disk_used_gb = root.used / (1024 ** 3)
            snap.disk_total_gb = root.total / (1024 ** 3)
            snap.disk_percent = root.percent
            dio = psutil.disk_io_counters()
            if dio and self._last_disk and self._last_disk_ts:
                dt = max(now - self._last_disk_ts, 0.001)
                snap.disk_read_mbps = (dio.read_bytes - self._last_disk.read_bytes) / dt / (1024 * 1024)
                snap.disk_write_mbps = (dio.write_bytes - self._last_disk.write_bytes) / dt / (1024 * 1024)
            if dio:
                self._last_disk = dio
                self._last_disk_ts = now
            nio = psutil.net_io_counters(pernic=False)
            if nio and self._last_net and self._last_net_ts:
                dt = max(now - self._last_net_ts, 0.001)
                snap.net_down_mbps = (nio.bytes_recv - self._last_net.bytes_recv) / dt / (1024 * 1024)
                snap.net_up_mbps = (nio.bytes_sent - self._last_net.bytes_sent) / dt / (1024 * 1024)
            if nio:
                self._last_net = nio
                self._last_net_ts = now
            addrs = psutil.net_if_addrs()
            stats = psutil.net_if_stats()
            for iface, st in stats.items():
                if st.isup and iface != "lo":
                    snap.net_iface = iface
                    for addr in addrs.get(iface, []):
                        if getattr(addr.family, "name", "") == "AF_INET":
                            snap.net_ip = addr.address
                            break
                    break
        else:
            fb = self._fallback
            snap.cpu_percent = fb.cpu_percent()
            snap.core_count = fb.cpu_count()
            try:
                snap.load_avg = os.getloadavg()
            except (AttributeError, OSError):
                pass
            used, total, pct, swap = fb.memory()
            snap.mem_used_gb, snap.mem_total_gb, snap.mem_percent, snap.swap_gb = used, total, pct, swap
            du, dt, dp = fb.disk_usage()
            snap.disk_used_gb, snap.disk_total_gb, snap.disk_percent = du, dt, dp
            snap.disk_read_mbps, snap.disk_write_mbps = fb.disk_io_mbps(now)
            down, up, iface, ip = fb.net_io_mbps(now)
            snap.net_down_mbps, snap.net_up_mbps = down, up
            snap.net_iface, snap.net_ip = iface, ip
            fb._prev_ts = now

        snap.cpu_name = _cpu_name()
        snap.sensors = _read_sensors()
        snap.battery_present, snap.battery_percent, snap.battery_status = _read_battery()
        snap.gpu_percent, snap.gpu_name = _read_gpu()
        snap.power_note = "Desktop / AC power" if not snap.battery_present else ""
        self.snapshot.cpu_history = (self.snapshot.cpu_history + [snap.cpu_percent])[-self.history_len :]
        self.snapshot.mem_history = (self.snapshot.mem_history + [snap.mem_percent])[-self.history_len :]
        self.snapshot = snap


def _cpu_name() -> str:
    try:
        for line in Path("/proc/cpuinfo").read_text(encoding="utf-8", errors="ignore").splitlines():
            if line.lower().startswith("model name"):
                return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return "Linux CPU"


def _read_battery() -> tuple[bool, int, str]:
    base = Path("/sys/class/power_supply")
    if not base.is_dir():
        return False, 0, "N/A"
    for bat in sorted(base.iterdir()):
        type_file = bat / "type"
        if not type_file.is_file():
            continue
        if type_file.read_text(encoding="utf-8").strip().lower() != "battery":
            continue
        cap = bat / "capacity"
        status = bat / "status"
        pct = int(cap.read_text(encoding="utf-8").strip()) if cap.is_file() else 0
        st = status.read_text(encoding="utf-8").strip() if status.is_file() else "Unknown"
        return True, pct, st
    return False, 0, "N/A"


def _read_gpu() -> tuple[float, str]:
    try:
        out = subprocess.check_output(
            ["nvidia-smi", "--query-gpu=utilization.gpu,name", "--format=csv,noheader,nounits"],
            text=True,
            timeout=2,
            stderr=subprocess.DEVNULL,
        ).strip()
        if out:
            util, name = out.split(",", 1)
            return float(util.strip()), name.strip()
    except (subprocess.SubprocessError, ValueError, FileNotFoundError):
        pass
    return 0.0, "N/A (nvidia-smi not found)"


def _read_sensors() -> list[tuple[str, str]]:
    try:
        out = subprocess.check_output(["sensors", "-u"], text=True, timeout=3, stderr=subprocess.DEVNULL)
    except (subprocess.SubprocessError, FileNotFoundError):
        return []
    entries: list[tuple[str, str]] = []
    chip = ""
    for line in out.splitlines():
        if line.endswith(":") and not line.startswith(" "):
            chip = line.rstrip(":")
            continue
        m = re.match(r"\s+temp\d+_input:\s+([\d.]+)", line)
        if m and chip:
            c = float(m.group(1))
            entries.append((f"{chip}", f"{c:.0f} °C"))
    return entries[:12]