#!/usr/bin/env python3
"""Deprecated wrapper — use sync-versions.py instead."""
import subprocess
import sys
from pathlib import Path

script = Path(__file__).resolve().parent / "sync-versions.py"
raise SystemExit(subprocess.call([sys.executable, str(script), *sys.argv[1:]]))