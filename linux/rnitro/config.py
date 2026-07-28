from __future__ import annotations

import json
from pathlib import Path

CONFIG_DIR = Path.home() / ".config" / "rnitro"
CONFIG_FILE = CONFIG_DIR / "settings.json"

DEFAULTS: dict = {
    "show_network": True,
    "show_weather": False,
    "chat_provider": "openrouter",
    "chat_model": "",
    "advisor_proactive": True,
    "temp_warning": 75,
    "temp_critical": 90,
    "cpu_warning": 85,
    "ram_warning": 85,
    "gpu_warning": 85,
    "disk_warning": 90,
    "battery_low": 15,
    "api_keys": {},
    "autostart": False,
    "poll_interval": 1.0,
}


def load() -> dict:
    if not CONFIG_FILE.is_file():
        return dict(DEFAULTS)
    try:
        data = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
        out = dict(DEFAULTS)
        if isinstance(data.get("api_keys"), dict):
            out["api_keys"] = data["api_keys"]
        for key, value in data.items():
            if key != "api_keys":
                out[key] = value
        return out
    except (OSError, json.JSONDecodeError):
        return dict(DEFAULTS)


def save(data: dict) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    merged = dict(DEFAULTS)
    merged.update(data)
    if "api_keys" not in merged or not isinstance(merged["api_keys"], dict):
        merged["api_keys"] = {}
    CONFIG_FILE.write_text(json.dumps(merged, indent=2) + "\n", encoding="utf-8")


def get_api_key(cfg: dict, provider: str) -> str:
    keys = cfg.get("api_keys") or {}
    return str(keys.get(provider, "")).strip()