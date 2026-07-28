#!/usr/bin/env python3
"""Compute masked self-hash for install-rNitro.sh (EXPECTED_HASH)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import versions as v

data = v.load()
beta = v.beta_release(data)
installer = v.SITE / beta["source_sh"]
h = v.masked_installer_hash(installer)
out = v.SITE / ".computed-hash"
out.write_text(h + "\n", encoding="utf-8")
print(h)