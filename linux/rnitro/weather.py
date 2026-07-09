from __future__ import annotations

import json
import threading
import urllib.request
from dataclasses import dataclass
from typing import Callable


@dataclass
class WeatherSnapshot:
    temp_c: float
    condition: str
    city: str
    humidity: int | None = None


class WeatherService:
    def __init__(self) -> None:
        self.snapshot: WeatherSnapshot | None = None
        self.is_loading = False
        self.last_error: str | None = None

    def refresh(self, enabled: bool, on_done: Callable[[], None] | None = None) -> None:
        if not enabled:
            self.snapshot = None
            self.last_error = None
            return

        def work() -> None:
            self.is_loading = True
            self.last_error = None
            try:
                self.snapshot = _fetch()
            except Exception as exc:
                self.snapshot = None
                self.last_error = str(exc)
            self.is_loading = False
            if on_done:
                on_done()

        threading.Thread(target=work, daemon=True, name="rnitro-weather").start()


def _fetch() -> WeatherSnapshot:
    with urllib.request.urlopen("https://ipapi.co/json/", timeout=8) as resp:
        geo = json.loads(resp.read().decode("utf-8"))
    lat, lon = geo.get("latitude"), geo.get("longitude")
    city = geo.get("city") or geo.get("region") or "Unknown"
    url = (
        "https://api.open-meteo.com/v1/forecast?"
        f"latitude={lat}&longitude={lon}&current=temperature_2m,weather_code,relative_humidity_2m"
    )
    with urllib.request.urlopen(url, timeout=8) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    cur = data.get("current", {})
    code = int(cur.get("weather_code", 0))
    hum = cur.get("relative_humidity_2m")
    return WeatherSnapshot(
        temp_c=float(cur.get("temperature_2m", 0)),
        condition=_wmo_label(code),
        city=city,
        humidity=int(hum) if hum is not None else None,
    )


def _wmo_label(code: int) -> str:
    mapping = {
        0: "Clear",
        1: "Mainly clear",
        2: "Partly cloudy",
        3: "Overcast",
        45: "Fog",
        48: "Fog",
        51: "Drizzle",
        53: "Drizzle",
        55: "Drizzle",
        61: "Rain",
        63: "Rain",
        65: "Heavy rain",
        71: "Snow",
        73: "Snow",
        75: "Heavy snow",
        80: "Showers",
        95: "Thunderstorm",
    }
    return mapping.get(code, "Weather")