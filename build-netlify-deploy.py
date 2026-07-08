#!/usr/bin/env python3
"""Stage a Netlify-ready site folder (HTML + download files at root)."""
from __future__ import annotations

import json
import os
import shutil
import zipfile
from pathlib import Path

import full_release as fr
import previous_versions as pv
import versions as v

SITE = Path(__file__).resolve().parent
OUT_DIR = SITE / "netlify-deploy"
ZIP_NAME = "rNitro-WEBSITE.zip"
NETLIFY_ZIP_NAME = "rNitro-NETLIFY-UPLOAD.zip"


def netlify_files(data: dict, *, include_bundle_zip: bool = False, website_zip: bool = False) -> list[str]:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    win = v.windows_release(data)
    files = list(fr.WEBSITE_FILES) + [
        stable["pkg"],
        beta["pkg"],
        stable["dmg"],
        beta["dmg"],
        stable["zip"],
        beta["zip"],
        v.macos_apps_release(data)["zip"],
        stable["sh"],
        beta["sh"],
        win["exe"],
        win["ps1"],
        "install-rNitro-windows.ps1",
    ]
    if not website_zip:
        files.append(beta["source_sh"])
    if include_bundle_zip:
        files.append(v.full_release(data)["zip"])
    archive = data.get("archive") or pv.build_archive(data)
    for name in pv.deploy_files(archive, website=website_zip):
        if name not in files:
            files.append(name)
    return files


def stage(data: dict, *, include_bundle_zip: bool | None = None) -> Path:
    netlify_state = None
    if OUT_DIR.exists():
        state_file = OUT_DIR / ".netlify" / "state.json"
        if state_file.is_file():
            netlify_state = state_file.read_text(encoding="utf-8")
        shutil.rmtree(OUT_DIR)
    OUT_DIR.mkdir()
    if netlify_state is not None:
        netlify_dir = OUT_DIR / ".netlify"
        netlify_dir.mkdir(parents=True, exist_ok=True)
        (netlify_dir / "state.json").write_text(netlify_state, encoding="utf-8")

    functions_src = SITE / "netlify" / "functions"
    if functions_src.is_dir():
        functions_dst = OUT_DIR / "netlify" / "functions"
        if functions_dst.exists():
            shutil.rmtree(functions_dst.parent)
        shutil.copytree(functions_src.parent, OUT_DIR / "netlify")
        print("  + netlify/functions/")

    netlify_toml = OUT_DIR / "netlify.toml"
    netlify_toml.write_text(
        "# Static site — index.html + downloads at root (no SPA rewrite)\n"
        "[build]\n"
        "  publish = \".\"\n"
        "  functions = \"netlify/functions\"\n"
        "\n"
        "[[headers]]\n"
        "  for = \"/*.ttf\"\n"
        "  [headers.values]\n"
        "    Content-Type = \"font/ttf\"\n"
        "    Access-Control-Allow-Origin = \"*\"\n"
        "\n"
        "[[headers]]\n"
        "  for = \"/*.otf\"\n"
        "  [headers.values]\n"
        "    Content-Type = \"font/otf\"\n"
        "    Access-Control-Allow-Origin = \"*\"\n"
        "\n"
        "[[headers]]\n"
        "  for = \"/*.pkg\"\n"
        "  [headers.values]\n"
        "    Content-Type = \"application/octet-stream\"\n"
        "\n"
        "[[headers]]\n"
        "  for = \"/*.zip\"\n"
        "  [headers.values]\n"
        "    Content-Type = \"application/zip\"\n"
        "\n"
        "[[headers]]\n"
        "  for = \"/*.dmg\"\n"
        "  [headers.values]\n"
        "    Content-Type = \"application/x-apple-diskimage\"\n",
        encoding="utf-8",
    )

    _redirects = OUT_DIR / "_redirects"
    _redirects.write_text("", encoding="utf-8")

    stable = v.stable_release(data)
    beta = v.beta_release(data)
    apps = v.macos_apps_release(data)
    howto = OUT_DIR / "HOW-TO.txt"
    howto.write_text(
        f"""rNitro Website — everything in one zip
========================================

1. Unzip rNitro-WEBSITE.zip anywhere (e.g. Desktop).
2. Double-click OPEN-WEBSITE.command — starts a local web server and opens the site.

This single archive includes BOTH current macOS builds:

  Stable — {stable["id"]}
    {stable["pkg"]}, {stable["dmg"]}, {stable["sh"]}, {stable["zip"]}

  Beta — {beta["id"]}
    {beta["pkg"]}, {beta["dmg"]}, {beta["sh"]}, {beta["zip"]}

  Both apps in one file — {apps["zip"]}
    rNitro-Stable.app + rNitro-Beta.app (extract, pick one, drag to Applications)

Also: Windows builds, older macOS .sh installers (see "Previous versions" on the page),
Varela Round font, and terms. All files sit next to index.html — no Netlify required.

To stop the local server, double-click STOP-WEBSITE.command.
""",
        encoding="utf-8",
    )

    open_cmd = OUT_DIR / "OPEN-WEBSITE.command"
    open_cmd.write_text(
        "#!/bin/bash\n"
        'cd "$(dirname "$0")"\n'
        "PORT=8765\n"
        'PIDFILE=".website-server.pid"\n'
        'if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then\n'
        '  open "http://127.0.0.1:$PORT/"\n'
        "  exit 0\n"
        "fi\n"
        'python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &\n'
        'echo $! > "$PIDFILE"\n'
        "sleep 0.5\n"
        'open "http://127.0.0.1:$PORT/"\n',
        encoding="utf-8",
    )
    open_cmd.chmod(0o755)

    stop_cmd = OUT_DIR / "STOP-WEBSITE.command"
    stop_cmd.write_text(
        "#!/bin/bash\n"
        'cd "$(dirname "$0")"\n'
        'PIDFILE=".website-server.pid"\n'
        'if [[ -f "$PIDFILE" ]]; then\n'
        '  kill "$(cat "$PIDFILE")" 2>/dev/null\n'
        '  rm -f "$PIDFILE"\n'
        "fi\n",
        encoding="utf-8",
    )
    stop_cmd.chmod(0o755)

    netlify_readme = OUT_DIR / "NETLIFY-UPLOAD.txt"
    netlify_readme.write_text(
        f"""UPLOAD THIS ZIP TO NETLIFY
==========================

The zip is correct — index.html is at the ROOT (not inside a subfolder).

Steps:
1. Log in at https://app.netlify.com/
2. Go to https://app.netlify.com/drop
3. Drag rNitro-NETLIFY-UPLOAD.zip onto the page (or drag the unzipped folder)
4. Wait for "Site is live" — Netlify shows a random URL like something-123.netlify.app
5. CRITICAL: Site configuration → Domain management → Change site name → type: getrnitro
   Live URL: https://getrnitro.netlify.app/

Note: rnitro.netlify.app is broken on Netlify's DNS (orphaned subdomain). Use getrnitro.

Or run (after netlify login):
  cd ~/rnitro-site-work/rnitro-site && python3 deploy-netlify.py

AI support chat (optional):
  Read CHAT-API-SETUP.txt — add GROQ_API_KEY (or similar) in Netlify env vars.
""",
        encoding="utf-8",
    )

    if include_bundle_zip is None:
        include_bundle_zip = (SITE / v.full_release(data)["zip"]).is_file()
    for name in netlify_files(data, website_zip=True, include_bundle_zip=include_bundle_zip):
        src = SITE / name
        if not src.is_file():
            raise FileNotFoundError(f"Missing deploy file: {src}")
        shutil.copy2(src, OUT_DIR / name)
        print(f"  + {name}")

    _inject_file_manifest(OUT_DIR)

    return OUT_DIR


def _inject_file_manifest(out_dir: Path) -> None:
    """Embed the list of shipped files so JS can hide broken download buttons."""
    index = out_dir / "index.html"
    if not index.is_file():
        return
    names = sorted(
        p.name for p in out_dir.iterdir() if p.is_file() and not p.name.startswith(".")
    )
    entries = ", ".join(json.dumps(n) for n in names)
    marker = "  const RNITRO_FILES = window.RNITRO_FILES || null;"
    inject = f"  const RNITRO_FILES = new Set([{entries}]);"
    text = index.read_text(encoding="utf-8")
    if marker not in text:
        raise ValueError("index.html missing RNITRO_FILES marker")
    index.write_text(text.replace(marker, inject, 1), encoding="utf-8")


def write_zip(data: dict) -> Path:
    stage(data)
    zip_path = SITE / ZIP_NAME
    if zip_path.exists():
        zip_path.unlink()
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for root, _, files in os.walk(OUT_DIR):
            for fname in files:
                full = Path(root) / fname
                arc = full.relative_to(OUT_DIR).as_posix()
                # PKG/DMG/ZIP are already compressed — store to save CPU and avoid bloat.
                if fname.endswith((".pkg", ".dmg", ".zip", ".exe")):
                    zf.write(full, arcname=arc, compress_type=zipfile.ZIP_STORED)
                else:
                    zf.write(full, arcname=arc)
    return zip_path


def main() -> None:
    data = v.load()
    print("Staging Netlify deploy...")
    zip_path = write_zip(data)
    netlify_zip = SITE / NETLIFY_ZIP_NAME
    if netlify_zip.exists():
        netlify_zip.unlink()
    shutil.copy2(zip_path, netlify_zip)
    for name in (ZIP_NAME, NETLIFY_ZIP_NAME):
        dest = Path.home() / "Downloads" / name
        if dest.exists():
            dest.unlink()
        shutil.copy2(zip_path if name == ZIP_NAME else netlify_zip, dest)
        print(f"Copied to {dest}")
    print(f"\nCreated {zip_path}")
    print(f"Netlify upload: {netlify_zip}")
    print(f"Size: {zip_path.stat().st_size:,} bytes")
    print("Netlify manual: read NETLIFY-UPLOAD.txt in the zip (site name: getrnitro).")
    print("Netlify auto:   npx netlify login && python3 deploy-netlify.py")


if __name__ == "__main__":
    main()