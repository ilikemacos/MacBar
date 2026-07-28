from __future__ import annotations

from dataclasses import dataclass

from .monitors import MonitorSnapshot


@dataclass
class AdvisorThresholds:
    temp_warning: float = 75
    temp_critical: float = 90
    cpu_warning: float = 85
    ram_warning: float = 85
    gpu_warning: float = 85
    disk_warning: float = 90
    battery_low: float = 15
    proactive_enabled: bool = True


@dataclass
class AdvisorWarning:
    level: str
    category: str
    message: str


class SystemAdvisor:
    def __init__(self, thresholds: AdvisorThresholds | None = None) -> None:
        self.thresholds = thresholds or AdvisorThresholds()
        self.warnings: list[AdvisorWarning] = []

    def apply_config(self, cfg: dict) -> None:
        self.thresholds = AdvisorThresholds(
            temp_warning=float(cfg.get("temp_warning", 75)),
            temp_critical=float(cfg.get("temp_critical", 90)),
            cpu_warning=float(cfg.get("cpu_warning", 85)),
            ram_warning=float(cfg.get("ram_warning", 85)),
            gpu_warning=float(cfg.get("gpu_warning", 85)),
            disk_warning=float(cfg.get("disk_warning", 90)),
            battery_low=float(cfg.get("battery_low", 15)),
            proactive_enabled=bool(cfg.get("advisor_proactive", True)),
        )

    def evaluate(self, snap: MonitorSnapshot) -> list[AdvisorWarning]:
        out: list[AdvisorWarning] = []
        t = self.thresholds

        if snap.cpu_percent >= t.cpu_warning:
            out.append(AdvisorWarning("warn", "cpu", f"CPU usage high: {snap.cpu_percent:.0f}%"))
        if snap.mem_percent >= t.ram_warning:
            out.append(AdvisorWarning("warn", "ram", f"RAM usage high: {snap.mem_percent:.0f}%"))
        if snap.disk_percent >= t.disk_warning:
            out.append(AdvisorWarning("warn", "disk", f"Disk almost full: {snap.disk_percent:.0f}%"))
        if snap.gpu_percent >= t.gpu_warning:
            out.append(AdvisorWarning("warn", "gpu", f"GPU usage high: {snap.gpu_percent:.0f}%"))

        if snap.core_count and snap.load_avg[0] > snap.core_count * 1.5:
            out.append(
                AdvisorWarning(
                    "warn",
                    "load",
                    f"Load average elevated: {snap.load_avg[0]:.2f} ({snap.core_count} cores)",
                )
            )

        for label, value in snap.sensors:
            try:
                c = float(value.split()[0])
            except ValueError:
                continue
            if c >= t.temp_critical:
                out.append(AdvisorWarning("critical", "temp", f"Critical temperature: {label} {value}"))
            elif c >= t.temp_warning:
                out.append(AdvisorWarning("warn", "temp", f"High temperature: {label} {value}"))

        if snap.battery_present:
            if snap.battery_percent <= t.battery_low:
                out.append(AdvisorWarning("warn", "battery", f"Battery low: {snap.battery_percent}%"))
            if snap.battery_status.lower() in ("discharging", "not charging") and snap.battery_percent < 25:
                out.append(
                    AdvisorWarning("info", "battery", f"On battery power at {snap.battery_percent}%")
                )

        self.warnings = out
        return out