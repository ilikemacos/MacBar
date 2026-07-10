#!/usr/bin/env python3
"""Sync version.json across index.html, installers, and build scripts."""
from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

import changelog as cl
import previous_versions as pv
import versions as v

SITE = v.SITE
INDEX = SITE / "index.html"
ARCHIVES_HTML = SITE / "archives.html"
README = SITE / "README.md"
MAKE_STABLE = SITE / "make-v6-nochat.sh.py"


def fmt_size(num_bytes: int) -> str:
    if num_bytes >= 1_048_576:
        return f"{num_bytes / 1_048_576:.1f} MB"
    if num_bytes >= 1024:
        return f"{num_bytes / 1024:.0f} KB"
    return f"{num_bytes} B"


def file_size_label(filename: str | None) -> str:
    if not filename:
        return ""
    path = SITE / filename
    if not path.is_file():
        return ""
    return f" · {fmt_size(path.stat().st_size)}"


def sized_label(text: str, filename: str | None) -> str:
    return f"{text}{file_size_label(filename)}"


def recommended_zip_block(
    zip_file: str,
    *,
    accent: str,
    accent_rgb: str,
    btn_style: str = "",
) -> str:
    size = file_size_label(zip_file)
    return f"""      <div class="dl-recommended" style="border-color:rgba({accent_rgb},0.4);">
        <div class="dl-recommended-badge" style="color:{accent}; border-color:rgba({accent_rgb},0.45); background:rgba({accent_rgb},0.1);">Recommended Download</div>
        <div class="dl-recommended-title" style="color:{accent};">App ZIP</div>
        <p class="dl-recommended-steps">Unzip → drag <code>rNitro.app</code> to Applications → right-click <strong>Open</strong> once if macOS blocks it. No admin password needed.</p>
        <button type="button" class="btn btn-primary btn-recommended" style="{btn_style}" onclick="requestDownload('{zip_file}')">⬇ Download App ZIP{size}</button>
      </div>"""


def other_downloads_panel(
    panel_id: str,
    inner_html: str,
    *,
    note: str = "",
) -> str:
    note_block = f'<div class="dl-other-note">{note}</div>' if note else ""
    return f"""      <div id="{panel_id}" class="dl-other-panel prev-versions-panel" style="margin-top:12px;">
        <button type="button" class="prev-versions-toggle" onclick="toggleOtherDownloads('{panel_id}')" aria-expanded="false">
          <span>Other download options</span>
          <span class="prev-versions-chevron" aria-hidden="true">▸</span>
        </button>
        <div class="dl-other-body prev-versions-body">
          <div class="dl-other-grid">
{inner_html}
          </div>
          {note_block}
        </div>
      </div>"""


def sync_region(html: str, name: str, content: str) -> str:
    if name in ("js-versions", "chat-whats-new", "chat-kb-platform"):
        start = f"// @sync:{name}\n"
        end_token = f"// @end:{name}"
    else:
        start = f"<!-- @sync:{name} -->\n"
        end_token = f"<!-- @end:{name} -->"
    start_idx = html.find(start)
    if start_idx == -1:
        raise SystemExit(f"sync region @{name} start marker not found in index.html")
    content_start = start_idx + len(start)
    end_idx = html.find(end_token, content_start)
    if end_idx == -1:
        raise SystemExit(f"sync region @{name} end marker not found in index.html")
    line_start = html.rfind("\n", content_start, end_idx) + 1
    return html[:content_start] + content.rstrip() + "\n" + html[line_start:]


WINDOWS_DEPRECATION_BANNER = """      <div class="platform-banner platform-banner--deprecated">
        Windows is no longer actively supported. Existing builds remain available for download.
      </div>"""


def js_versions_object(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    win = v.windows_release(data)
    linux = v.linux_release(data)
    payload = {
        "stable": {
            "id": stable["id"],
            "label": stable["label"],
            "short": stable["short"],
            "sh": stable["sh"],
            "pkg": stable["pkg"],
            "dmg": stable["dmg"],
            "zip": stable["zip"],
            "hash": data["hashes"]["stable_sh"],
            "curlInstall": curl_install_cmd(stable["sh"]),
        },
        "beta": {
            "id": beta["id"],
            "label": beta["label"],
            "short": beta["short"],
            "sh": beta["sh"],
            "pkg": beta["pkg"],
            "dmg": beta["dmg"],
            "zip": beta["zip"],
            "hash": data["hashes"]["beta_sh"],
            "curlInstall": curl_install_cmd(beta["sh"]),
        },
        "windows": {
            "id": win["id"],
            "exe": win["exe"],
            "ps1": win["ps1"],
        },
        "linux": {
            "id": linux["id"],
            "label": linux["label"],
            "short": linux["short"],
            "tar": linux["tar"],
            "sh": linux["sh"],
            "githubUrl": v.github_release_page_url(linux["id"]),
        },
        "macos_apps": {
            "label": v.macos_apps_release(data)["label"],
            "zip": v.macos_apps_release(data)["zip"],
        },
        "full": {
            "label": v.full_release(data)["label"],
            "zip": v.full_release(data)["zip"],
        },
    }
    body = json.dumps(payload, indent=2)
    indented = "\n".join("  " + line if line else line for line in body.splitlines())
    return f"  const RNITRO_VERSIONS = {indented};"


def nav_right(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    linux = v.linux_release(data)
    return f"""  <div class="nav-right">
    <a class="nav-link" href="/archives">Archives</a>
    <div class="nav-badge">{stable["label"]} · {beta["label"]} · Linux {linux["short"]}</div>
  </div>"""


def hero_stable_card(data: dict) -> str:
    s = v.stable_release(data)
    other = other_downloads_panel(
        "hero-stable-other",
        f"""            <button type="button" class="btn btn-secondary" onclick="requestDownload('{s["pkg"]}')">{sized_label("PKG installer", s["pkg"])}</button>
            <button type="button" class="btn btn-secondary" onclick="requestDownload('{s["dmg"]}')">{sized_label("DMG disk image", s["dmg"])}</button>
            <button type="button" class="btn btn-sh btn-sh-green" onclick="requestDownload('{s["sh"]}')">{sized_label("Shell installer (.sh)", s["sh"])}</button>
            <button class="btn btn-secondary" onclick="copyCurlCmd('stable')">⎘ Copy curl install</button>
            <button class="btn btn-secondary" onclick="copyCmd('stable')">⎘ Copy bash command</button>""",
        note="<strong>PKG</strong> needs admin password. <strong>DMG</strong> — drag to Applications. <strong>.sh</strong> compiles from readable source (~30s). PKG may trigger a macOS security prompt — use System Settings → Privacy &amp; Security → Open.",
    )
    return f"""    <div style="width:100%; background:var(--card); border:1px solid var(--green); border-radius:12px; padding:20px; text-align:center;">
      <div style="font-family:var(--mono); font-size:16px; font-weight:700; color:var(--green); margin-bottom:4px;">{s["id"]}</div>
      <div style="font-size:16px; color:var(--muted); margin-bottom:0;">Stable — CPU monitor, benchmark, and AI chat with <strong>OpenAI (GPT)</strong> and <strong>OpenRouter</strong> only.</div>
{recommended_zip_block(s["zip"], accent="var(--green)", accent_rgb="0,255,136")}
{other}
    </div>"""


def hero_beta_card(data: dict) -> str:
    b = v.beta_release(data)
    other = other_downloads_panel(
        "hero-beta-other",
        f"""            <button type="button" class="btn btn-secondary" onclick="requestDownload('{b["pkg"]}')">{sized_label("PKG installer", b["pkg"])}</button>
            <button type="button" class="btn btn-secondary" onclick="requestDownload('{b["dmg"]}')">{sized_label("DMG disk image", b["dmg"])}</button>
            <button type="button" class="btn btn-sh btn-sh-orange" onclick="requestDownload('{b["sh"]}')">{sized_label("Shell installer (.sh)", b["sh"])}</button>
            <button class="btn btn-secondary" onclick="copyCurlCmd('beta')">⎘ Copy curl install</button>
            <button class="btn btn-secondary" onclick="copyCmd('beta')">⎘ Copy bash command</button>""",
        note="<strong>Beta notice:</strong> Experimental AI — Terms required. <strong>curl</strong> or <strong>.sh</strong> compiles full source on your Mac if you don't trust pre-built PKGs.",
    )
    return f"""    <div style="width:100%; background:var(--card); border:1px solid var(--orange); border-radius:12px; padding:20px; text-align:center;">
      <div style="font-family:var(--mono); font-size:16px; font-weight:700; color:var(--orange); margin-bottom:4px;">{b["id"]}</div>
      <div style="font-size:16px; color:var(--muted); margin-bottom:0;">Beta — stable features plus AI chat API: Gemini, OpenAI, Anthropic, Grok, DeepSeek, OpenRouter, LM Studio, Ollama, and Hermes.</div>
      <p style="font-size:16px; color:var(--orange); background:rgba(255,140,26,0.08); border:1px solid rgba(255,140,26,0.35); border-radius:8px; padding:10px 12px; margin-top:12px; line-height:1.5; text-align:left;">
        <strong>Beta notice:</strong> Experimental AI features — report issues via Support. You must agree to Terms &amp; Conditions before download.
      </p>
{recommended_zip_block(b["zip"], accent="var(--orange)", accent_rgb="255,140,26", btn_style="background:var(--orange); color:#000;")}
{other}
    </div>"""


def pkg_gatekeeper_warning() -> str:
    return """      <p style="font-size:16px; color:#ffcc66; background:rgba(255,180,40,0.1); border:1px solid rgba(255,180,40,0.45); border-radius:8px; padding:12px 14px; line-height:1.65; text-align:left;">
        <strong>⚠ macOS security prompt:</strong> When you open the PKG, macOS may say it can't verify the file. That's normal for indie apps. <strong>Don't click Move to Trash.</strong> Click <strong>Done</strong>, then go to <strong>System Settings → Privacy &amp; Security</strong> and press <strong>Open</strong> at the bottom.
      </p>"""


def hero_macos_apps_card(data: dict) -> str:
    apps = v.macos_apps_release(data)
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    return f"""    <div style="width:100%; background:var(--card); border:1px solid #9b7bff; border-radius:12px; padding:20px; text-align:center;">
      <div style="font-family:var(--mono); font-size:16px; font-weight:700; color:#b8a0ff; margin-bottom:4px;">{apps["label"]}</div>
      <div style="font-size:16px; color:var(--muted); margin-bottom:14px;">One ZIP with both macOS apps — <strong>rNitro-Stable.app</strong> ({stable["short"]}) and <strong>rNitro-Beta.app</strong> ({beta["short"]}). Extract, pick one, drag it to Applications.</div>
      <div class="btn-group" style="margin-bottom:0;">
        <button type="button" class="btn btn-primary" style="background:#9b7bff; color:#000;" onclick="requestDownload('{apps["zip"]}')">⬇ Download macOS Apps ZIP</button>
      </div>
      <p class="sh-trust-note" style="margin-top:12px; border-color:rgba(155,123,255,0.35); background:rgba(155,123,255,0.06);"><strong style="color:#b8a0ff;">No PKG needed.</strong> Includes README and Terms. Install only one app at a time — rename to <code>rNitro.app</code> if you like.</p>
    </div>"""


def hero_more_downloads(data: dict) -> str:
    full = v.full_release(data)
    apps = v.macos_apps_release(data)
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    inner = f"""            <button type="button" class="btn btn-secondary" style="background:#9b7bff; color:#000;" onclick="requestDownload('{apps["zip"]}')">{sized_label("macOS Apps ZIP (Stable + Beta)", apps["zip"])}</button>
            <button type="button" class="btn btn-secondary" data-dl-full-zip style="background:var(--cyan); color:#000;" onclick="requestDownload('{full["zip"]}')">{sized_label("Full Release ZIP", full["zip"])}</button>"""
    return other_downloads_panel(
        "hero-more-downloads",
        inner,
        note=f"<strong>macOS Apps ZIP</strong> — rNitro-Stable.app ({stable['short']}) + rNitro-Beta.app ({beta['short']}). <strong>Full Release</strong> — entire website + all builds for developers.",
    )


def download_card_full(data: dict) -> str:
    full = v.full_release(data)
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    return f"""  <div class="download-card" style="margin-top:16px; border-color:var(--cyan);">
    <div class="download-meta">
      <h2>rNitro {full["label"]}</h2>
      <p>Complete bundle — website, {stable["id"]} + {beta["id"]} PKGs, DMGs, macOS Apps ZIP, source installers, Windows builds, Terms, favicons, and <code>do_release.py</code> pipeline.</p>
      <div class="req">
        <span class="req-tag" style="border-color:var(--cyan); color:var(--cyan);">All-in-one</span>
        <span class="req-tag">Website</span>
        <span class="req-tag">Build scripts</span>
        <span class="req-tag">Free</span>
      </div>
    </div>
    <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
      <button type="button" class="btn btn-primary" data-dl-full-zip style="white-space:nowrap; background:var(--cyan); color:#000;" onclick="requestDownload('{full["zip"]}')">⬇ Download Full Release ZIP</button>
    </div>
    <p class="sh-trust-note" style="margin-top:14px; max-width:100%; border-color:rgba(0,217,255,0.35); background:rgba(0,217,255,0.06);"><strong style="color:var(--cyan);">Release pipeline:</strong> <code>python3 do_release.py sync</code> · <code>quick</code> · <code>full</code></p>
  </div>"""


SITE_URL = "https://getrnitro.netlify.app"


def curl_install_cmd(sh_name: str) -> str:
    """One-liner: download .sh to disk then run (installer blocks curl|bash)."""
    return f"curl -fsSL {SITE_URL}/{sh_name} -o /tmp/rnitro-install.sh && bash /tmp/rnitro-install.sh"


def hero_head(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    linux = v.linux_release(data)
    desc = (
        f"rNitro — free menu bar system monitor for Apple Silicon Macs "
        f"({stable['short']} Stable / {beta['short']} Beta). CPU, temperature, MacBook battery %, "
        f"GPU, RAM. Linux {linux['short']} pre-release. No account, no telemetry."
    )
    og_image = f"{SITE_URL}/apple-touch-icon.png"
    ld_json = json.dumps(
        {
            "@context": "https://schema.org",
            "@type": "SoftwareApplication",
            "name": "rNitro",
            "operatingSystem": "macOS, Linux, Windows",
            "applicationCategory": "UtilitiesApplication",
            "softwareVersion": beta["short"],
            "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
            "downloadUrl": SITE_URL,
        },
        ensure_ascii=False,
    )
    return f"""<title>rNitro — CPU Monitor for macOS, Linux &amp; Windows</title>
<meta name="description" content="{desc}">
<link rel="canonical" href="{SITE_URL}/">
<meta property="og:type" content="website">
<meta property="og:title" content="rNitro — Menu Bar System Monitor">
<meta property="og:description" content="{desc}">
<meta property="og:url" content="{SITE_URL}/">
<meta property="og:image" content="{og_image}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="rNitro — Menu Bar System Monitor">
<meta name="twitter:description" content="{desc}">
<meta name="twitter:image" content="{og_image}">
<script type="application/ld+json">{ld_json}</script>"""


def hero_copy(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    linux = v.linux_release(data)
    return f"""  <p class="hero-eyebrow">System Monitor</p>
  <h1 class="hero-title"><span>rNitro</span></h1>
  <p class="hero-credit">Made by <strong>chopsticks</strong></p>
  <p class="hero-sub">Real-time CPU, temperature, and per-core stats for <strong>macOS</strong> ({stable["short"]} Stable + {beta["short"]} Beta), <strong>Linux</strong> ({linux["short"]} pre-release), and legacy <strong>Windows</strong> (deprecated — downloads remain).</p>"""


def platform_tabs() -> str:
    return """  <div role="tablist" aria-label="Download platform" style="display:flex; gap:8px; justify-content:center; margin-bottom:16px;">
    <button id="tab-mac" role="tab" aria-selected="true" aria-controls="dl-mac" onclick="setTab('mac')"
      style="padding:6px 18px; border-radius:20px; border:1px solid var(--green); background:var(--green); color:#000; font-family:var(--mono); font-size:16px; font-weight:500; cursor:pointer;">
      🍎 macOS
    </button>
    <button id="tab-linux" role="tab" aria-selected="false" aria-controls="dl-linux" onclick="setTab('linux')"
      style="padding:6px 18px; border-radius:20px; border:1px solid var(--border); background:transparent; color:var(--text); font-family:var(--mono); font-size:16px; font-weight:500; cursor:pointer;">
      🐧 Linux
    </button>
    <button id="tab-win" role="tab" aria-selected="false" aria-controls="dl-win" onclick="setTab('win')"
      style="padding:6px 18px; border-radius:20px; border:1px solid var(--border); background:transparent; color:var(--text); font-family:var(--mono); font-size:16px; font-weight:500; cursor:pointer;">
      🪟 Windows
    </button>
  </div>"""


def steps_linux(data: dict) -> str:
    lin = v.linux_release(data)
    linux_gh = v.github_release_page_url(lin["id"])
    return f"""  <div id="steps-linux" class="steps" style="display:none;">
    <div class="step">
      <div class="step-num">1</div>
      <div class="step-content">
        <h3>Install dependencies</h3>
        <p>Ubuntu/Debian: <code>sudo apt install python3-gi python3-venv gir1.2-adw-1 gir1.2-gtk-4.0 lm-sensors</code>. Fedora: <code>sudo dnf install python3-gobject gtk4 libadwaita</code>.</p>
      </div>
    </div>
    <div class="step">
      <div class="step-num">2</div>
      <div class="step-content">
        <h3>Download and install</h3>
        <p>Switch to the <strong>Linux</strong> tab, download <code>{lin["tar"]}</code> or <code>{lin["sh"]}</code>, extract if needed, and run <code>bash {lin["sh"]}</code>. Also on <a href="{linux_gh}" style="color:var(--cyan);">GitHub Releases</a>. Installs to <code>~/.local/share/rnitro</code> with a desktop entry.</p>
      </div>
    </div>
    <div class="step">
      <div class="step-num">3</div>
      <div class="step-content">
        <h3>Use rNitro</h3>
        <p>Launch from your app menu or the system tray. Monitor, Advisor, Chat, and Cleaner tabs mirror the macOS beta feature set (platform-specific metrics where applicable).</p>
      </div>
    </div>
  </div>"""


def steps_win(data: dict) -> str:
    win = v.windows_release(data)
    return f"""  <div id="steps-win" class="steps" style="display:none;">
    <p style="font-size:15px; color:var(--orange); background:rgba(255,140,26,0.08); border:1px solid rgba(255,140,26,0.35); border-radius:8px; padding:10px 12px; margin-bottom:16px; line-height:1.55;">
      <strong>Windows is no longer actively supported.</strong> The last build ({win["id"]}) remains available for download below.
    </p>
    <div class="step">
      <div class="step-num">1</div>
      <div class="step-content">
        <h3>Download the EXE (easiest)</h3>
        <p>Switch to the <strong>Windows</strong> tab and download <strong>{win["exe"]}</strong>. If Windows asks for a runtime, install the <a href="https://dotnet.microsoft.com/download/dotnet/8.0" style="color:var(--cyan);">.NET 8 Desktop Runtime (x64)</a> first, then run the EXE again.</p>
      </div>
    </div>
    <div class="step">
      <div class="step-num">2</div>
      <div class="step-content">
        <h3>Or compile from source</h3>
        <p>Download <code>{win["ps1"]}</code>, open <strong>PowerShell</strong>, and run:</p>
        <div style="margin-top:10px; background:var(--card2); border:1px solid var(--border); border-radius:8px; padding:12px 16px; font-family:var(--mono); font-size:16px; color:var(--green);">
          powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\\Downloads\\{win["ps1"]}
        </div>
        <p style="margin-top:8px;">Compiles with <code>csc.exe</code> (built into Windows 10/11) and installs to <code>%LOCALAPPDATA%\\rNitro</code> — ~15 seconds. No SDK required.</p>
      </div>
    </div>
    <div class="step">
      <div class="step-num">3</div>
      <div class="step-content">
        <h3>Use rNitro</h3>
        <p>rNitro runs in the <strong>system tray</strong> (bottom-right). Click the icon for live CPU%, temperature, RAM, BTC price, and 60-second history graphs. Right-click the tray icon to quit.</p>
        <p style="margin-top:8px;">For new installs we recommend <strong>macOS</strong> or the <strong>Linux</strong> tab instead.</p>
      </div>
    </div>
  </div>"""


def hero_dl_note(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    linux = v.linux_release(data)
    gh = v.github_releases_url()
    linux_gh = v.github_release_page_url(linux["id"])
    return f"""    <p style="color:var(--muted); font-size:15px; font-family:var(--mono); text-align:center; max-width:640px; margin-top:12px; line-height:1.55;">
      New here? Use the green <strong style="color:var(--green);">Recommended Download</strong> (App ZIP) above. Same macOS builds on <a href="{gh}" style="color:var(--cyan);">GitHub Releases</a> — {stable["short"]} Final and {beta["short"]} Beta (ZIP, PKG, DMG). Linux {linux["short"]} pre-release is on the <strong style="color:#e8a838;">Linux</strong> tab and <a href="{linux_gh}" style="color:var(--cyan);">GitHub</a>. Expand <strong style="color:var(--text);">Other download options</strong> for PKG, DMG, or shell installers. Older DMG builds: <a href="/archives" style="color:var(--cyan);">rNitro Archives</a>.
    </p>"""


def install_step_pkg(data: dict) -> str:
    return f"""        <h3>Download the PKG, DMG, or App ZIP</h3>
        <p>Choose <strong>Stable</strong> (green, OpenAI + OpenRouter) or <strong>Beta</strong> (orange, all AI APIs). Agree to the Terms &amp; Conditions, then pick a format:</p>
        <ul style="margin:10px 0 0 18px; line-height:1.7; color:var(--muted);">
          <li><strong>PKG</strong> — double-click; installs to Applications (admin password).</li>
          <li><strong>DMG</strong> — open the disk image and drag <code>rNitro.app</code> to Applications.</li>
          <li><strong>Apps ZIP</strong> — one file with both Stable and Beta <code>.app</code> bundles.</li>
        </ul>
        <div style="margin-top:12px;">
{pkg_gatekeeper_warning()}
        </div>"""


def install_step_sh(data: dict) -> str:
    return """        <h3>Or install from Terminal with curl</h3>
        <p>No browser download needed — paste a one-liner in Terminal. It fetches the <strong>.sh</strong> installer (readable source), saves it to <code>/tmp</code>, then runs it. Stable:</p>"""


def hero_linux_buttons(data: dict) -> str:
    lin = v.linux_release(data)
    tar_size = file_size_label(lin["tar"])
    sh_size = file_size_label(lin["sh"])
    return f"""    <div style="width:100%; background:var(--card); border:1px solid #e8a838; border-radius:12px; padding:20px; text-align:center;">
      <div style="font-family:var(--mono); font-size:16px; font-weight:700; color:#e8a838; margin-bottom:4px;">{lin["id"]}</div>
      <div style="font-size:16px; color:var(--muted); margin-bottom:0;">Linux Beta — Monitor, Advisor, Chat, and App Cleaner with GTK4 + system tray. Pre-release for x86_64.</div>
      <p style="font-size:16px; color:#e8a838; background:rgba(232,168,56,0.08); border:1px solid rgba(232,168,56,0.35); border-radius:8px; padding:10px 12px; margin-top:12px; line-height:1.5; text-align:left;">
        <strong>Pre-release:</strong> Requires Python 3.10+, GTK 4, and libadwaita. Apple-only metrics (SMC, Low Power Mode) show as N/A.
      </p>
      <div class="dl-recommended" style="border-color:rgba(232,168,56,0.4); margin-top:14px;">
        <div class="dl-recommended-badge" style="color:#e8a838; border-color:rgba(232,168,56,0.45); background:rgba(232,168,56,0.1);">Recommended Download</div>
        <div class="dl-recommended-title" style="color:#e8a838;">Linux tarball</div>
        <p class="dl-recommended-steps">Extract → run <code>install-rNitro-linux.sh</code> → launches from <code>~/.local/share/rnitro</code> with a desktop entry.</p>
        <button type="button" class="btn btn-primary btn-recommended" style="background:#e8a838; color:#000;" onclick="requestDownload('{lin["tar"]}')">⬇ Download tarball{tar_size}</button>
      </div>
      <div id="hero-linux-other" class="dl-other-panel prev-versions-panel" style="margin-top:12px;">
        <button type="button" class="prev-versions-toggle" onclick="toggleOtherDownloads('hero-linux-other')" aria-expanded="false">
          <span>Other download options</span>
          <span class="prev-versions-chevron" aria-hidden="true">▸</span>
        </button>
        <div class="dl-other-body prev-versions-body">
          <div class="dl-other-grid">
            <button type="button" class="btn btn-secondary" onclick="requestDownload('{lin["sh"]}')">{sized_label("Shell installer (.sh)", lin["sh"])}</button>
            <button class="btn btn-secondary" onclick="copyLinuxCmd()">⎘ Copy bash command</button>
          </div>
          <div class="dl-other-note">Installer checks dependencies (python3-gi, GTK 4, libadwaita) and sets up a venv automatically. Also on <a href="{v.github_release_page_url(lin["id"])}" style="color:var(--cyan);">GitHub Releases</a>.</div>
        </div>
      </div>
    </div>"""


def download_card_linux(data: dict) -> str:
    lin = v.linux_release(data)
    tar_size = file_size_label(lin["tar"])
    return f"""  <div id="card-linux" class="download-card" style="display:none;">
    <div class="download-meta">
      <h2>rNitro {lin["id"]}</h2>
      <p>GTK4 + libadwaita desktop app — Monitor, Advisor, AI Chat, and App Cleaner for Linux x86_64.</p>
      <div class="req">
        <span class="req-tag" style="border-color:#e8a838; color:#e8a838;">Pre-release</span>
        <span class="req-tag">Ubuntu / Fedora / Debian</span>
        <span class="req-tag">Python 3.10+</span>
        <span class="req-tag">GTK 4</span>
        <span class="req-tag">Free</span>
      </div>
    </div>
    <div class="dl-recommended" style="border-color:rgba(232,168,56,0.4);">
      <div class="dl-recommended-badge" style="color:#e8a838; border-color:rgba(232,168,56,0.45); background:rgba(232,168,56,0.1);">Recommended Download</div>
      <div class="dl-recommended-title" style="color:#e8a838;">Linux tarball</div>
      <p class="dl-recommended-steps">Extract and run <code>install-rNitro-linux.sh</code>, or download the installer script alone.</p>
      <button type="button" class="btn btn-primary btn-recommended" style="background:#e8a838; color:#000;" onclick="requestDownload('{lin["tar"]}')">⬇ Download tarball{tar_size}</button>
    </div>
    <div id="dl-linux-other" class="dl-other-panel prev-versions-panel" style="margin-top:12px;">
      <button type="button" class="prev-versions-toggle" onclick="toggleOtherDownloads('dl-linux-other')" aria-expanded="false">
        <span>Other download options</span>
        <span class="prev-versions-chevron" aria-hidden="true">▸</span>
      </button>
      <div class="dl-other-body prev-versions-body">
        <div class="dl-other-grid">
          <button type="button" class="btn btn-secondary" onclick="requestDownload('{lin["sh"]}')">{sized_label("Shell installer (.sh)", lin["sh"])}</button>
        </div>
      </div>
    </div>
  </div>"""


def hero_windows_buttons(data: dict) -> str:
    w = v.windows_release(data)
    other = other_downloads_panel(
        "hero-win-other",
        f"""            <button type="button" class="btn btn-secondary" onclick="requestDownload('{w["ps1"]}')">{sized_label("PowerShell installer (.ps1)", w["ps1"])}</button>
            <button class="btn btn-secondary" onclick="copyWinCmd()">⎘ Copy PowerShell command</button>""",
        note="The .ps1 compiles from source with built-in csc.exe — no SDK needed.",
    )
    exe_size = file_size_label(w["exe"])
    return f"""    <div style="width:100%; background:var(--card); border:1px solid var(--cyan); border-radius:12px; padding:20px; text-align:center;">
{WINDOWS_DEPRECATION_BANNER}
      <div style="font-family:var(--mono); font-size:16px; font-weight:700; color:var(--cyan); margin-bottom:4px;">{w["id"]}</div>
      <div style="font-size:16px; color:var(--muted); margin-bottom:0;">Windows 10/11 tray monitor — CPU, temp, RAM, and BTC stats.</div>
      <div class="dl-recommended" style="border-color:rgba(0,217,255,0.4); margin-top:14px;">
        <div class="dl-recommended-badge" style="color:var(--cyan); border-color:rgba(0,217,255,0.45); background:rgba(0,217,255,0.1);">Recommended Download</div>
        <div class="dl-recommended-title" style="color:var(--cyan);">Windows EXE</div>
        <p class="dl-recommended-steps">Double-click to run. Install <a href="https://dotnet.microsoft.com/download/dotnet/8.0" style="color:var(--cyan);">.NET 8 Desktop Runtime x64</a> first if Windows prompts you.</p>
        <button type="button" class="btn btn-primary btn-recommended" style="background:var(--cyan); color:#000;" onclick="requestDownload('{w["exe"]}')">⬇ Download EXE{exe_size}</button>
      </div>
{other}
    </div>"""


def feature_ai_chat(data: dict) -> str:
    b = v.beta_release(data)
    return f"""    <div class="feature">
      <span class="feature-icon">💬</span>
      <div class="feature-title">AI Chat <span style="color:var(--orange); font-size:16px;">({b["label"]})</span></div>
      <div class="feature-desc">Available in {b["id"]} — Chat tab with Gemini, OpenAI, Anthropic, Grok, DeepSeek, OpenRouter, LM Studio, Ollama, and Hermes (Keychain for cloud keys; local providers need no key).</div>
    </div>"""


def install_sh_commands(data: dict) -> str:
    s = v.stable_release(data)
    b = v.beta_release(data)
    stable_curl = curl_install_cmd(s["sh"])
    beta_curl = curl_install_cmd(b["sh"])
    return f"""        <p style="margin-top:8px; color:var(--muted); line-height:1.6;">Paste in <strong>Terminal</strong> (Apple Silicon Mac, Xcode CLT required). The script is saved to disk first — <code>curl | bash</code> is blocked on purpose.</p>
        <div style="margin-top:10px; background:var(--card2); border:1px solid var(--border); border-radius:8px; padding:12px 16px; font-family:var(--mono); font-size:14px; color:var(--green); word-break:break-all; text-align:left;">
          {stable_curl}
        </div>
        <p style="margin-top:10px; color:var(--muted);">Beta ({b["short"]}):</p>
        <div style="margin-top:6px; background:var(--card2); border:1px solid rgba(255,140,26,0.35); border-radius:8px; padding:12px 16px; font-family:var(--mono); font-size:14px; color:var(--orange); word-break:break-all; text-align:left;">
          {beta_curl}
        </div>
        <p style="margin-top:8px;">Installs to <code>~/Applications/rNitro.app</code> in ~30 seconds. Self-verifies its SHA-256 checksum before running.</p>"""


def hero_curl_install(data: dict) -> str:
    s = v.stable_release(data)
    b = v.beta_release(data)
    stable_curl = curl_install_cmd(s["sh"])
    beta_curl = curl_install_cmd(b["sh"])
    return f"""  <div style="width:100%; max-width:720px; margin:0 auto 20px; background:var(--card); border:1px solid var(--border); border-radius:12px; padding:16px 18px; text-align:left;">
    <div style="font-family:var(--mono); font-size:13px; font-weight:700; color:var(--cyan); margin-bottom:8px; letter-spacing:0.04em;">TERMINAL INSTALL · macOS</div>
    <p style="font-size:15px; color:var(--muted); margin:0 0 12px; line-height:1.55;">Paste one line into Terminal — downloads the installer, then compiles and installs rNitro (~30s). Requires <a href="https://developer.apple.com/xcode/resources/" style="color:var(--cyan);">Xcode Command Line Tools</a>.</p>
    <div style="font-size:13px; color:var(--green); margin-bottom:4px;">Stable ({s["short"]})</div>
    <div style="background:var(--card2); border:1px solid rgba(0,255,136,0.25); border-radius:8px; padding:11px 14px; font-family:var(--mono); font-size:13px; color:var(--green); word-break:break-all; line-height:1.45;">
      {stable_curl}
    </div>
    <div style="margin-top:10px; display:flex; gap:8px; flex-wrap:wrap;">
      <button type="button" class="btn btn-secondary" onclick="copyCurlCmd('stable')">⎘ Copy stable curl</button>
    </div>
    <div style="font-size:13px; color:var(--orange); margin:14px 0 4px;">Beta ({b["short"]}) — all AI providers</div>
    <div style="background:var(--card2); border:1px solid rgba(255,140,26,0.3); border-radius:8px; padding:11px 14px; font-family:var(--mono); font-size:13px; color:var(--orange); word-break:break-all; line-height:1.45;">
      {beta_curl}
    </div>
    <div style="margin-top:10px; display:flex; gap:8px; flex-wrap:wrap;">
      <button type="button" class="btn btn-secondary" onclick="copyCurlCmd('beta')">⎘ Copy beta curl</button>
    </div>
  </div>"""


def download_card_stable(data: dict) -> str:
    s = v.stable_release(data)
    h = data["hashes"]["stable_sh"]
    other = other_downloads_panel(
        "dl-stable-other",
        f"""            <button type="button" class="btn btn-secondary" onclick="requestDownload('{s["pkg"]}')">{sized_label("PKG installer", s["pkg"])}</button>
            <button type="button" class="btn btn-secondary" onclick="requestDownload('{s["dmg"]}')">{sized_label("DMG disk image", s["dmg"])}</button>
            <button type="button" class="btn btn-sh btn-sh-green" onclick="requestDownload('{s["sh"]}')">{sized_label("Shell installer (.sh)", s["sh"])}</button>""",
        note="<strong>Don't trust the PKG?</strong> The .sh compiles from readable source on your Mac.",
    )
    return f"""  <div class="download-card" style="border-color:var(--green);">
    <div class="download-meta">
      <h2>rNitro {s["id"]}</h2>
      <p>Stable macOS build — monitor, benchmark, and AI chat (OpenAI GPT + OpenRouter only).</p>
      <div class="req">
        <span class="req-tag">macOS 12+</span>
        <span class="req-tag">Apple Silicon</span>
        <span class="req-tag">Xcode CLT (.sh)</span>
        <span class="req-tag">Free</span>
      </div>
      <div style="margin-top:16px; font-family:var(--mono); font-size:16px; color:var(--muted);">
        SHA-256 (.sh):
        <span id="sha-hash-stable" style="color:var(--green); word-break:break-all;">{h}</span>
        <button onclick="copyHash('stable')" style="background:none; border:1px solid var(--border); color:var(--muted); border-radius:4px; padding:2px 8px; margin-left:8px; cursor:pointer; font-family:var(--mono); font-size:16px;">⎘ copy</button>
      </div>
    </div>
{recommended_zip_block(s["zip"], accent="var(--green)", accent_rgb="0,255,136")}
{other}
  </div>"""


def download_card_beta(data: dict) -> str:
    b = v.beta_release(data)
    s = v.stable_release(data)
    h = data["hashes"]["beta_sh"]
    other = other_downloads_panel(
        "dl-beta-other",
        f"""            <button type="button" class="btn btn-secondary" onclick="requestDownload('{b["pkg"]}')">{sized_label("PKG installer", b["pkg"])}</button>
            <button type="button" class="btn btn-secondary" onclick="requestDownload('{b["dmg"]}')">{sized_label("DMG disk image", b["dmg"])}</button>
            <button type="button" class="btn btn-sh btn-sh-orange" onclick="requestDownload('{b["sh"]}')">{sized_label("Shell installer (.sh)", b["sh"])}</button>""",
        note="<strong>Skeptical of the PKG?</strong> Use the .sh — full-source compile, verified checksum.",
    )
    return f"""  <div class="download-card" style="margin-top:16px; border-color:var(--orange);">
    <div class="download-meta">
      <h2>rNitro {b["id"]}</h2>
      <p>Beta macOS build — {s["short"]} features plus AI chat API (Gemini, OpenAI, Anthropic, Grok, DeepSeek, OpenRouter, LM Studio, Ollama, Hermes).</p>
      <p style="font-family:var(--mono); font-size:16px; color:var(--orange); background:rgba(255,140,26,0.08); border:1px solid rgba(255,140,26,0.35); border-radius:8px; padding:10px 12px; margin-top:12px; line-height:1.6;">
        <strong>Beta notice:</strong> Experimental AI features — Terms &amp; Conditions required before download.
      </p>
      <div class="req">
        <span class="req-tag" style="border-color:var(--orange); color:var(--orange);">Beta</span>
        <span class="req-tag">macOS 12+</span>
        <span class="req-tag">Apple Silicon</span>
        <span class="req-tag">AI Chat API</span>
        <span class="req-tag">Free</span>
      </div>
      <div style="margin-top:16px; font-family:var(--mono); font-size:16px; color:var(--muted);">
        SHA-256 (.sh):
        <span id="sha-hash-beta" style="color:var(--orange); word-break:break-all;">{h}</span>
        <button onclick="copyHash('beta')" style="background:none; border:1px solid var(--border); color:var(--muted); border-radius:4px; padding:2px 8px; margin-left:8px; cursor:pointer; font-family:var(--mono); font-size:16px;">⎘ copy</button>
      </div>
    </div>
{recommended_zip_block(b["zip"], accent="var(--orange)", accent_rgb="255,140,26", btn_style="background:var(--orange); color:#000;")}
{other}
  </div>"""


def _archive_link(fname: str | None, label: str) -> str:
    if not fname:
        return '<span style="color:var(--muted)">—</span>'
    return f'<button type="button" class="prev-dl-link" onclick="requestDownload(\'{fname}\')">{label}</button>'


def download_previous_section(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    return f"""  <div style="margin-top:16px; text-align:center;">
    <p style="color:var(--muted); font-size:14px; font-family:var(--mono); line-height:1.6;">
      Need an older build? Shell installers for v8.3.9–v8.3.11 are in <strong style="color:var(--text);">Other download options</strong> above.
      All hosted <strong style="color:var(--text);">DMG</strong> disk images (current + archive) are on
      <a href="/archives" style="color:var(--cyan);">rNitro Archives</a> — {stable["short"]} Final, {beta["short"]} Beta, and older releases.
    </p>
  </div>"""


def download_card_macos_apps(data: dict) -> str:
    apps = v.macos_apps_release(data)
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    return f"""  <div class="download-card" style="margin-top:16px; border-color:#9b7bff;">
    <div class="download-meta">
      <h2>rNitro {apps["label"]}</h2>
      <p>Both macOS builds in one archive — <code>rNitro-Stable.app</code> ({stable["id"]}) and <code>rNitro-Beta.app</code> ({beta["id"]}). Extract, choose one, drag to Applications.</p>
      <div class="req">
        <span class="req-tag" style="border-color:#9b7bff; color:#b8a0ff;">Stable + Beta</span>
        <span class="req-tag">macOS 12+</span>
        <span class="req-tag">Apple Silicon</span>
        <span class="req-tag">No admin password</span>
      </div>
    </div>
    <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
      <button type="button" class="btn btn-primary" style="white-space:nowrap; background:#9b7bff; color:#000;" onclick="requestDownload('{apps["zip"]}')">⬇ Download macOS Apps ZIP</button>
    </div>
    <p class="sh-trust-note" style="margin-top:14px; max-width:100%; border-color:rgba(155,123,255,0.35); background:rgba(155,123,255,0.06);"><strong style="color:#b8a0ff;">Tip:</strong> install only one at a time. Right-click → Open on first launch if macOS blocks the app.</p>
  </div>"""


def download_more_section(data: dict) -> str:
    full = v.full_release(data)
    apps = v.macos_apps_release(data)
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    inner = f"""            <button type="button" class="btn btn-secondary" style="background:#9b7bff; color:#000;" onclick="requestDownload('{apps["zip"]}')">{sized_label("macOS Apps ZIP (Stable + Beta)", apps["zip"])}</button>
            <button type="button" class="btn btn-secondary" data-dl-full-zip style="background:var(--cyan); color:#000;" onclick="requestDownload('{full["zip"]}')">{sized_label("Full Release ZIP", full["zip"])}</button>"""
    return other_downloads_panel(
        "dl-more-downloads",
        inner,
        note=f"Apps ZIP includes rNitro-Stable.app ({stable['id']}) and rNitro-Beta.app ({beta['id']}). Full Release has the entire site + all builds.",
    )


def download_card_windows(data: dict) -> str:
    w = v.windows_release(data)
    other = other_downloads_panel(
        "dl-win-other",
        f"""            <button type="button" class="btn btn-secondary" onclick="requestDownload('{w["ps1"]}')">{sized_label("PowerShell installer (.ps1)", w["ps1"])}</button>""",
        note="PS1 compiles locally — no SDK required.",
    )
    exe_size = file_size_label(w["exe"])
    return f"""  <div id="card-win" class="download-card" style="display:none;">
{WINDOWS_DEPRECATION_BANNER}
    <div class="download-meta">
      <h2>rNitro {w["id"]}</h2>
      <p>Pre-built EXE · PowerShell source installer · system tray monitor for Windows 10/11 x64</p>
      <div class="req">
        <span class="req-tag">Windows 10/11</span>
        <span class="req-tag">x86/x64</span>
        <span class="req-tag">.NET 8 Runtime (EXE)</span>
        <span class="req-tag">Free</span>
      </div>
    </div>
    <div class="dl-recommended" style="border-color:rgba(0,217,255,0.4);">
      <div class="dl-recommended-badge" style="color:var(--cyan); border-color:rgba(0,217,255,0.45); background:rgba(0,217,255,0.1);">Recommended Download</div>
      <div class="dl-recommended-title" style="color:var(--cyan);">Windows EXE</div>
      <p class="dl-recommended-steps">Double-click to run. Needs <a href="https://dotnet.microsoft.com/download/dotnet/8.0" style="color:var(--cyan);">.NET 8 Desktop Runtime x64</a> if prompted.</p>
      <button type="button" class="btn btn-primary btn-recommended" style="background:var(--cyan); color:#000;" onclick="requestDownload('{w["exe"]}')">⬇ Download EXE{exe_size}</button>
    </div>
{other}
  </div>"""


def whats_new_section(changelog: dict) -> str:
    cards = []
    for card in changelog.get("whats_new", []):
        accent = card.get("accent", "green")
        color, border = cl.ACCENT_COLORS.get(accent, cl.ACCENT_COLORS["green"])
        items_html = []
        for item in card.get("items", []):
            if isinstance(item, dict):
                items_html.append(
                    f"            <li><strong>{item.get('strong', '')}</strong>{item.get('text', '')}</li>"
                )
            else:
                items_html.append(f"            <li>{item}</li>")
        cards.append(
            f"""        <div class="whats-new-card" style="border-color:{border};">
          <h3 style="color:{color};">{card.get('title', '')}</h3>
          <ul>
{chr(10).join(items_html)}
          </ul>
        </div>"""
        )
    grid = "\n".join(cards) if cards else ""
    return f"""  <div id="whats-new-panel" class="whats-new-panel prev-versions-panel is-open">
    <button type="button" class="prev-versions-toggle" onclick="toggleWhatsNew()" aria-expanded="true">
      <span>What's new</span>
      <span class="prev-versions-chevron" aria-hidden="true">▸</span>
    </button>
    <p class="prev-versions-note">Latest stable and beta highlights — see the full changelog below for older releases.</p>
    <div class="whats-new-body prev-versions-body">
      <div class="whats-new-grid">
{grid}
      </div>
    </div>
  </div>"""


def changelog_section(changelog: dict) -> str:
    blocks = []
    for rel in changelog.get("releases", []):
        title = rel.get("title", "")
        body = rel.get("body_html", "")
        blocks.append(
            f"""    <div class="feature">
      <div class="feature-title">{title}</div>
      <div class="feature-desc" style="margin-top:8px; line-height:1.7;">
        {body}
      </div>
    </div>"""
        )
    body = "\n".join(blocks) if blocks else '    <p style="color:var(--muted);">No changelog entries.</p>'
    return f"""  <div class="features" style="grid-template-columns:1fr;">
{body}
  </div>"""


def _status_pill(label: str, kind: str) -> str:
    return f'<span class="status-pill status-pill--{kind}">{label}</span>'


def how_it_works_section(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    win = v.windows_release(data)
    linux = v.linux_release(data)
    linux_gh = v.github_release_page_url(linux["id"])
    gh = v.github_releases_url()

    platform_rows = [
        (
            f'<strong style="color:var(--green);">macOS</strong> · Stable',
            stable["id"],
            _status_pill("Active", "active"),
            f'<code>{stable["zip"]}</code>',
            "<code>~/Applications/rNitro.app</code>",
            "In-app updater on launch",
            "CPU monitor, benchmark, stress test, System Advisor, App Cleaner; AI chat: OpenAI + OpenRouter only",
        ),
        (
            f'<strong style="color:var(--orange);">macOS</strong> · Beta',
            beta["id"],
            _status_pill("Experimental", "beta"),
            f'<code>{beta["zip"]}</code>',
            "<code>~/Applications/rNitro.app</code>",
            "In-app updater on launch",
            "Everything in Stable plus all AI providers, temp banners, AES-256 key storage, first-launch tips",
        ),
        (
            f'<strong style="color:#e8a838;">Linux</strong> · Pre-release',
            linux["id"],
            _status_pill("Pre-release", "prerelease"),
            f'<code>{linux["tar"]}</code> or <code>{linux["sh"]}</code>',
            "<code>~/.local/share/rnitro</code>",
            "Checks <code>version.json</code> on launch",
            "GTK4 app: Monitor, Advisor, Chat, Cleaner; x86_64; needs Python 3.10+, GTK 4, libadwaita",
        ),
        (
            f'<strong style="color:var(--cyan);">Windows</strong> · Legacy',
            win["id"],
            _status_pill("Deprecated", "deprecated"),
            f'<code>{win["exe"]}</code>',
            "<code>%LOCALAPPDATA%\\rNitro</code>",
            "Manual — check website or GitHub",
            "Tray monitor only (CPU, temp, RAM, BTC); no AI chat or Cleaner; .NET 8 runtime for EXE",
        ),
    ]

    def platform_tr(cells: tuple[str, ...]) -> str:
        tds = "".join(f"<td>{c}</td>" for c in cells)
        return f"          <tr>{tds}</tr>"

    format_rows = [
        (
            "<strong>App ZIP</strong> <span style=\"color:var(--green);\">(recommended)</span>",
            "macOS",
            "Pre-built <code>rNitro.app</code> — unzip and drag to Applications",
            "Right-click → Open once if Gatekeeper blocks it",
            "Fastest path; no admin password",
        ),
        (
            "<strong>PKG</strong>",
            "macOS",
            "Installer package → Applications",
            "System Settings → Privacy &amp; Security → Open if blocked",
            "One double-click install; needs admin password",
        ),
        (
            "<strong>DMG</strong>",
            "macOS",
            "Disk image — drag app to Applications",
            "Same as App ZIP on first open",
            "Familiar Mac workflow",
        ),
        (
            "<strong>.sh</strong> shell installer",
            "macOS",
            "Full Swift source compiled locally with <code>swiftc</code>",
            "No prebuilt binary downloaded — you read the script first",
            "Maximum trust; ~30s compile on your Mac",
        ),
        (
            "<strong>Tarball + .sh</strong>",
            "Linux",
            "Python/GTK source tree + <code>install-rNitro-linux.sh</code>",
            "Installer checks deps and sets up a venv",
            "Pre-release; also on <a href=\"" + linux_gh + "\" style=\"color:var(--cyan);\">GitHub</a>",
        ),
        (
            "<strong>EXE / .ps1</strong>",
            "Windows",
            "Pre-built tray app or PowerShell compile via <code>csc.exe</code>",
            ".NET 8 Desktop Runtime for EXE",
            "Legacy only — macOS or Linux recommended for new installs",
        ),
    ]

    flow_rows = [
        ("Pick your platform tab", "macOS, Linux, or Windows — the site auto-detects your OS"),
        ("Accept Terms &amp; Conditions", "Required once per browser session before any download"),
        ("Download recommended file", "Green/orange/cyan/gold cards on each tab — sizes shown on buttons"),
        ("Install", "Follow the <strong>How to install</strong> steps below for your tab"),
        ("Updates", "macOS: in-app prompt → download ZIP → replace app. Linux: checks same <code>version.json</code>. Windows: manual."),
        ("GitHub mirror", f"All current builds also on <a href=\"{gh}\" style=\"color:var(--cyan);\">GitHub Releases</a>"),
    ]

    platform_body = "\n".join(platform_tr(r) for r in platform_rows)
    format_body = "\n".join(platform_tr(r) for r in format_rows)
    flow_body = "\n".join(
        f'          <tr><td>{step}</td><td>{detail}</td></tr>' for step, detail in flow_rows
    )

    return f"""  <div class="channel-compare" style="margin-bottom:14px;">
    <h2 style="font-family:var(--mono); font-size:18px; font-weight:700; margin:0 0 8px;">Platforms &amp; channels at a glance</h2>
    <p style="color:var(--muted); font-size:15px; line-height:1.6; margin:0 0 14px;">One place to see what each build is, where it installs, and how updates work. New here? <strong style="color:var(--green);">macOS Stable App ZIP</strong> for daily monitoring, or <strong style="color:var(--orange);">macOS Beta App ZIP</strong> if you want every AI provider.</p>
    <div class="channel-compare-scroll">
      <table class="channel-compare-table how-it-works-table">
        <thead>
          <tr>
            <th>Platform</th>
            <th>Version</th>
            <th>Status</th>
            <th>Recommended download</th>
            <th>Install location</th>
            <th>Updates</th>
            <th>What you get</th>
          </tr>
        </thead>
        <tbody>
{platform_body}
        </tbody>
      </table>
    </div>
    <div class="how-it-works-subtitle">Download formats</div>
    <div class="channel-compare-scroll">
      <table class="channel-compare-table how-it-works-table">
        <thead>
          <tr>
            <th>Format</th>
            <th>Platform</th>
            <th>What it is</th>
            <th>Gatekeeper / runtime</th>
            <th>When to use</th>
          </tr>
        </thead>
        <tbody>
{format_body}
        </tbody>
      </table>
    </div>
    <div class="how-it-works-subtitle">End-to-end flow</div>
    <div class="channel-compare-scroll">
      <table class="channel-compare-table" style="min-width:520px;">
        <thead>
          <tr>
            <th>Step</th>
            <th>What happens</th>
          </tr>
        </thead>
        <tbody>
{flow_body}
        </tbody>
      </table>
    </div>
  </div>"""


def stable_beta_compare_section(changelog: dict, data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    meta = changelog.get("compare", {})
    title = meta.get("title", "Stable vs Beta")
    subtitle = meta.get(
        "subtitle",
        f"Stable ({stable['label']}) for everyday use; Beta ({beta['label']}) for all AI providers.",
    )
    rows_html = []
    for row in meta.get("rows", []):
        rows_html.append(
            f"""          <tr>
            <td>{row.get('feature', '')}</td>
            <td style="color:var(--green);">{row.get('stable', '')}</td>
            <td style="color:var(--orange);">{row.get('beta', '')}</td>
          </tr>"""
        )
    return f"""  <div class="channel-compare">
    <h2 style="font-family:var(--mono); font-size:18px; font-weight:700; margin:0 0 8px;">{title}</h2>
    <p style="color:var(--muted); font-size:15px; line-height:1.6; margin:0 0 14px;">{subtitle}</p>
    <div class="channel-compare-scroll">
      <table class="channel-compare-table">
        <thead>
          <tr>
            <th></th>
            <th style="color:var(--green);">{stable['label']}</th>
            <th style="color:var(--orange);">{beta['label']}</th>
          </tr>
        </thead>
        <tbody>
{chr(10).join(rows_html)}
        </tbody>
      </table>
    </div>
  </div>"""


def chat_kb_platform(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    linux = v.linux_release(data)
    linux_gh = v.github_release_page_url(linux["id"])
    return f"""    {{ label: 'How does everything work?', kws: ['how it works', 'how everything', 'which download', 'what should i download', 'platforms', 'channels', 'overview', 'table'],
      a: "On macOS Beta, open the main window and pick the **How it works** tab — same overview as the website. On the site, scroll to **How everything works** for tables covering macOS Stable ({stable['short']}), macOS Beta ({beta['short']}), Linux ({linux['short']}), and deprecated Windows. Recommended: green Stable App ZIP for daily use, orange Beta App ZIP for all AI providers. Terms required once per session before download." }},
    {{ label: 'Does it work on Windows?', kws: ['windows', 'win10', 'win11', 'pc'],
      a: `Windows is no longer actively supported. The last build (${{RNITRO_VERSIONS.windows.id}}) remains on the Windows tab — download the .exe (needs .NET 8 Desktop Runtime) or the .ps1 installer. For new installs we recommend macOS or Linux.` }},
    {{ label: 'Linux install?', kws: ['linux', 'ubuntu', 'fedora', 'debian', 'gtk', 'tarball'],
      a: `Linux pre-release (${{RNITRO_VERSIONS.linux.id}}): switch to the Linux tab, download the tarball or install-rNitro-linux.sh, then run bash install-rNitro-linux.sh. Requires Python 3.10+, GTK 4, and libadwaita. Also on GitHub: {linux_gh}` }},
    {{ label: 'How do updates work?', kws: ['update', 'new version', 'upgrade'],
      a: "macOS: rNitro checks getrnitro.netlify.app on launch. If a newer Final or Beta build exists, you get a choice: Install Final (stable) or Install Beta — then it downloads the ZIP in-app and restarts. Linux v0.1 checks the same version.json for Linux updates." }},"""


def chat_whats_new_kb(data: dict, changelog: dict) -> str:
    beta = v.beta_release(data)
    stable = v.stable_release(data)
    answer = cl.whats_new_answer(changelog).replace("`", "\\`")
    # JSON-safe for embedding in JS template literal
    answer_js = json.dumps(answer, ensure_ascii=False)
    kws = [
        "whats new",
        "what's new",
        beta["short"],
        stable["short"],
        "varela",
        "font",
        "changelog",
        "low power",
    ]
    kws_js = json.dumps(kws)
    return f"""    {{ label: "What's new in {beta['short']}?", kws: {kws_js},
      a: {answer_js} }},"""


def update_installer_versions(data: dict) -> None:
    beta = v.beta_release(data)
    installer = SITE / beta["source_sh"]
    text = installer.read_text(encoding="utf-8")
    text = re.sub(
        r'let CURRENT_VERSION = "v[^"]+"',
        f'let CURRENT_VERSION = "{beta["id"]}"',
        text,
        count=1,
    )
    installer.write_text(text, encoding="utf-8")


def regenerate_installers(data: dict, *, skip_stable: bool = False) -> None:
    beta = v.beta_release(data)
    stable = v.stable_release(data)

    if not skip_stable:
        subprocess.run([sys.executable, str(MAKE_STABLE)], cwd=SITE, check=True)

    src = SITE / beta["source_sh"]
    dst = SITE / beta["sh"]
    shutil.copy2(src, dst)
    dst.chmod(0o755)

    paths = [src, dst]
    if not skip_stable:
        paths.append(SITE / stable["sh"])
    for path in paths:
        v.update_expected_hash(path)
        print(f"  EXPECTED_HASH updated: {path.name}")


def sync_index(data: dict) -> None:
    changelog = cl.load()
    html = INDEX.read_text(encoding="utf-8")
    regions = {
        "hero-head": hero_head(data),
        "nav-right": nav_right(data),
        "hero-copy": hero_copy(data),
        "hero-curl-install": hero_curl_install(data),
        "platform-tabs": platform_tabs(),
        "hero-stable": hero_stable_card(data),
        "hero-beta": hero_beta_card(data),
        "hero-more": hero_more_downloads(data),
        "hero-windows": hero_windows_buttons(data),
        "hero-linux": hero_linux_buttons(data),
        "feature-ai-chat": feature_ai_chat(data),
        "how-it-works": how_it_works_section(data),
        "install-sh-commands": install_sh_commands(data),
        "hero-dl-note": hero_dl_note(data),
        "install-step-pkg": install_step_pkg(data),
        "install-step-sh": install_step_sh(data),
        "steps-linux": steps_linux(data),
        "steps-win": steps_win(data),
        "download-stable": download_card_stable(data),
        "download-beta": download_card_beta(data),
        "download-more": download_more_section(data),
        "download-previous": download_previous_section(data),
        "download-windows": download_card_windows(data),
        "download-linux": download_card_linux(data),
        "stable-beta-compare": stable_beta_compare_section(changelog, data),
        "whats-new": whats_new_section(changelog),
        "changelog": changelog_section(changelog),
        "chat-kb-platform": chat_kb_platform(data),
        "chat-whats-new": chat_whats_new_kb(data, changelog),
        "js-versions": js_versions_object(data),
    }
    for name, content in regions.items():
        html = sync_region(html, name, content)
    INDEX.write_text(html, encoding="utf-8")
    print(f"Updated {INDEX.name}")


def readme_release_table(rel: dict) -> str:
    tag = v.github_release_tag(rel["id"])
    rows = []
    for label, key in (("App ZIP", "zip"), ("PKG", "pkg"), ("DMG", "dmg")):
        name = rel[key]
        url = v.github_asset_url(rel["id"], name)
        rows.append(f"| **{label}** | [{name}]({url}) |")
    return "\n".join(rows)


def readme_downloads(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    return f"""### Stable — {stable["label"]}

| Format | File |
|--------|------|
{readme_release_table(stable)}

### Beta — {beta["label"]}

| Format | File |
|--------|------|
{readme_release_table(beta)}"""


def readme_curl(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    stable_curl = curl_install_cmd(stable["sh"])
    beta_curl = curl_install_cmd(beta["sh"])
    return f"""**Stable ({stable["label"]}):**
```bash
{stable_curl}
```

**Beta ({beta["label"]}):**
```bash
{beta_curl}
```"""


def _parse_release_id_from_dmg(name: str) -> str | None:
    m = re.match(r"^rNitro-(v[\w.-]+-arm64)\.dmg$", name)
    return m.group(1) if m else None


def _version_sort_key(release_id: str) -> tuple[int, int, int, int]:
    m = re.search(r"v(\d+)\.(\d+)\.(\d+)", release_id)
    if not m:
        return (0, 0, 0, 0)
    major, minor, patch = (int(x) for x in m.groups())
    is_beta = 1 if "Beta" in release_id else 0
    return (major, minor, patch, is_beta)


def dmg_archive_rows(data: dict) -> list[dict]:
    stable_id = v.stable_id(data)
    beta_id = v.beta_id(data)
    rows: list[dict] = []
    for path in sorted(SITE.glob("rNitro-v*-arm64.dmg"), key=lambda p: _version_sort_key(p.stem.removeprefix("rNitro-")), reverse=True):
        rid = _parse_release_id_from_dmg(path.name)
        if not rid:
            continue
        if "Beta" in rid:
            channel, ch_label, ch_color = "beta", "Beta", "var(--orange)"
        else:
            channel, ch_label, ch_color = "stable", "Stable", "var(--green)"
        badge = ""
        if rid == stable_id:
            badge = ' <span style="color:var(--green); font-size:11px;">(current stable)</span>'
        elif rid == beta_id:
            badge = ' <span style="color:var(--orange); font-size:11px;">(current beta)</span>'
        rows.append(
            {
                "id": rid,
                "channel": channel,
                "ch_label": ch_label,
                "ch_color": ch_color,
                "filename": path.name,
                "size": fmt_size(path.stat().st_size),
                "badge": badge,
            }
        )
    return rows


def generate_archives_html(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    rows = dmg_archive_rows(data)
    table_rows = []
    for row in rows:
        table_rows.append(
            f"""        <tr>
          <td style="color:var(--text); font-weight:600;">{row["id"]}{row["badge"]}</td>
          <td><span class="tag" style="color:{row["ch_color"]}; border-color:{row["ch_color"]};">{row["ch_label"]}</span></td>
          <td>{row["size"]}</td>
          <td><button type="button" class="dl-btn" onclick="requestDownload('{row["filename"]}')">Download DMG</button></td>
        </tr>"""
        )
    tbody = "\n".join(table_rows) if table_rows else '        <tr><td colspan="4" style="color:var(--muted);">No DMG files found.</td></tr>'
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>rNitro Archives — DMG Downloads</title>
<meta name="description" content="All hosted rNitro macOS DMG disk images — {stable["short"]} Stable, {beta["short"]} Beta, and older releases.">
<link rel="canonical" href="{SITE_URL}/archives.html">
<link rel="icon" href="favicon.ico" sizes="any">
<link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png">
<style>
  @font-face {{
    font-family: 'Varela Round';
    src: url('VarelaRound.ttf') format('truetype');
    font-weight: 400;
    font-style: normal;
    font-display: swap;
  }}
  *, *::before, *::after {{ box-sizing: border-box; margin: 0; padding: 0; }}
  :root {{
    --bg: #0A0A0F; --card: #13131E; --border: #2A2A40;
    --cyan: #00D9FF; --green: #00FF80; --orange: #FF8C1A;
    --text: #E8E8F0; --muted: #6B6B8A;
    --mono: ui-monospace, Menlo, monospace;
    --sans: 'Varela Round', -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
  }}
  body {{
    background: var(--bg); color: var(--text); font-family: var(--sans);
    font-size: 14px; min-height: 100vh; padding: 32px 16px 48px;
  }}
  .wrap {{ max-width: 820px; margin: 0 auto; }}
  h1 {{ font-size: 28px; margin-bottom: 6px; }}
  h1 span {{ color: var(--cyan); }}
  .sub {{ color: var(--muted); line-height: 1.6; margin-bottom: 24px; max-width: 640px; }}
  .back {{ display: inline-block; margin-bottom: 20px; color: var(--cyan); text-decoration: none; font-family: var(--mono); font-size: 13px; }}
  .back:hover {{ text-decoration: underline; }}
  .card {{
    background: var(--card); border: 1px solid var(--border); border-radius: 12px;
    padding: 20px; overflow-x: auto;
  }}
  table {{ width: 100%; border-collapse: collapse; font-family: var(--mono); font-size: 13px; }}
  th, td {{ padding: 10px 12px; text-align: left; border-bottom: 1px solid var(--border); }}
  th {{ color: var(--muted); font-weight: 500; font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em; }}
  .tag {{
    display: inline-block; padding: 2px 8px; border-radius: 12px; border: 1px solid;
    font-size: 11px; font-weight: 500;
  }}
  .dl-btn {{
    background: transparent; border: 1px solid var(--cyan); color: var(--cyan);
    border-radius: 8px; padding: 6px 12px; font-family: var(--mono); font-size: 12px;
    cursor: pointer;
  }}
  .dl-btn:hover {{ background: rgba(0,217,255,0.1); }}
  .note {{
    margin-top: 16px; color: var(--muted); font-size: 13px; line-height: 1.55;
    font-family: var(--mono);
  }}
</style>
</head>
<body>
<div class="wrap">
  <a class="back" href="index.html">← Main download page</a>
  <h1><span>rNitro</span> Archives</h1>
  <p class="sub">All hosted macOS <strong>DMG</strong> disk images. Open the DMG, drag <code>rNitro.app</code> to Applications, then right-click → <strong>Open</strong> once if Gatekeeper blocks it. For ZIP, PKG, or curl installers see the <a href="index.html" style="color:var(--cyan);">main page</a>.</p>
  <div class="card">
    <table>
      <thead>
        <tr><th>Version</th><th>Channel</th><th>Size</th><th>Download</th></tr>
      </thead>
      <tbody>
{tbody}
      </tbody>
    </table>
  </div>
  <p class="note">Current releases: {stable["label"]} (stable) · {beta["label"]} (beta). GitHub: <a href="{v.github_releases_url()}" style="color:var(--cyan);">ilikemacos/rNitro</a></p>
</div>
<script>
function requestDownload(filename) {{
  const a = document.createElement('a');
  a.href = filename;
  a.download = filename;
  a.rel = 'noopener';
  document.body.appendChild(a);
  a.click();
  a.remove();
}}
</script>
</body>
</html>"""


def sync_archives_html(data: dict) -> None:
    ARCHIVES_HTML.write_text(generate_archives_html(data), encoding="utf-8")
    print(f"Updated {ARCHIVES_HTML.name}")


def sync_readme(data: dict) -> None:
    if not README.is_file():
        print(f"Skipping {README.name} (not found)")
        return
    text = README.read_text(encoding="utf-8")
    for name, content in (
        ("readme-curl", readme_curl(data)),
        ("readme-downloads", readme_downloads(data)),
    ):
        text = sync_region(text, name, content)
    README.write_text(text, encoding="utf-8")
    print(f"Updated {README.name}")


def refresh_hashes(data: dict) -> dict:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    stable_path = SITE / stable["sh"]
    beta_path = SITE / beta["sh"]
    if not stable_path.is_file():
        raise SystemExit(f"Missing stable installer: {stable_path}")
    if not beta_path.is_file():
        raise SystemExit(f"Missing beta installer: {beta_path}")
    data["hashes"]["stable_sh"] = v.file_sha256(stable_path)
    data["hashes"]["beta_sh"] = v.file_sha256(beta_path)
    return data


def refresh_archive(data: dict) -> dict:
    data["archive"] = pv.build_archive(data)
    return data


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Sync rNitro versions from version.json")
    parser.add_argument(
        "--skip-installers",
        action="store_true",
        help="Only refresh hashes and index.html (do not regenerate .sh files)",
    )
    parser.add_argument(
        "--skip-stable-installer",
        action="store_true",
        help="Regenerate beta .sh only; keep existing stable .sh",
    )
    args = parser.parse_args()

    data = v.load()
    v.validate(data)

    if not args.skip_installers:
        print("Regenerating installers...")
        update_installer_versions(data)
        regenerate_installers(data, skip_stable=args.skip_stable_installer)

    data = refresh_hashes(data)
    data = refresh_archive(data)
    v.save(data)

    print("Syncing index.html...")
    sync_index(data)
    sync_archives_html(data)
    sync_readme(data)

    print("\nDone. version.json:")
    print(f"  latest: {data['latest']}")
    print(f"  beta:   {data['beta']}")
    print(f"  stable SHA: {data['hashes']['stable_sh'][:16]}…")
    print(f"  beta SHA:   {data['hashes']['beta_sh'][:16]}…")


if __name__ == "__main__":
    main()