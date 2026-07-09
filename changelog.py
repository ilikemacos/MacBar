#!/usr/bin/env python3
"""Load changelog.json — single source for What's New, changelog, and chat hints."""
from __future__ import annotations

import json
from pathlib import Path

SITE = Path(__file__).resolve().parent
CHANGELOG_FILE = SITE / "changelog.json"

ACCENT_COLORS = {
    "green": ("var(--green)", "rgba(0,255,136,0.35)"),
    "orange": ("var(--orange)", "rgba(255,140,26,0.35)"),
    "cyan": ("var(--cyan)", "rgba(0,217,255,0.35)"),
}


def load() -> dict:
    if not CHANGELOG_FILE.is_file():
        raise SystemExit(f"Missing {CHANGELOG_FILE.name} — run bootstrap or create it.")
    return json.loads(CHANGELOG_FILE.read_text(encoding="utf-8"))


def whats_new_answer(data: dict | None = None) -> str:
    data = data or load()
    lines: list[str] = []
    for card in data.get("whats_new", []):
        title = card.get("title", "")
        lines.append(f"{title} highlights:")
        for item in card.get("items", []):
            if isinstance(item, dict):
                lines.append(f"• {item.get('strong', '')}{item.get('text', '')}")
            else:
                lines.append(f"• {item}")
        lines.append("")
    return "\n".join(lines).strip()