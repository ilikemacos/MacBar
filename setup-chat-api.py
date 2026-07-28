#!/usr/bin/env python3
"""Set Netlify env var for AI support chat from chat-api-key.local (gitignored)."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

SITE = Path(__file__).resolve().parent
KEY_FILE = SITE / "chat-api-key.local"
NETLIFY = SITE / "node_modules" / ".bin" / "netlify"
DEPLOY_DIR = SITE / "netlify-deploy"
SITE_ID = "6325a0ae-2158-4e20-bfa5-db5cb9d34e7a"

VAR_NAMES = ("GROQ_API_KEY", "OPENROUTER_API_KEY", "GEMINI_API_KEY")


def parse_local_file() -> tuple[str, str] | None:
    if not KEY_FILE.is_file():
        return None
    for line in KEY_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            key, _, value = line.partition("=")
            key, value = key.strip(), value.strip().strip('"').strip("'")
            if key in VAR_NAMES and value:
                return key, value
        elif line.startswith("gsk_"):
            return "GROQ_API_KEY", line
        elif line.startswith("sk-or-"):
            return "OPENROUTER_API_KEY", line
        elif line.startswith("AIza"):
            return "GEMINI_API_KEY", line
    return None


def main() -> None:
    parsed = parse_local_file()
    if not parsed:
        print(f"Create {KEY_FILE.name} with one line, e.g.:")
        print("  GROQ_API_KEY=gsk_your_key_here")
        print("Get a free Grok key: https://console.groq.com/")
        raise SystemExit(1)

    var_name, value = parsed
    if not NETLIFY.is_file():
        raise SystemExit("Netlify CLI missing. Run: npm install netlify-cli --save-dev")

    DEPLOY_DIR.mkdir(parents=True, exist_ok=True)
    cmd = [
        str(NETLIFY),
        "env:set",
        var_name,
        value,
        "--context",
        "production",
        "--context",
        "deploy-preview",
        "--secret",
        "--force",
    ]
    print(f"Setting {var_name} on getrnitro (value hidden)...")
    subprocess.run(cmd, cwd=DEPLOY_DIR, check=True)
    print("Done. Redeploy: python3 deploy-netlify.py")


if __name__ == "__main__":
    main()