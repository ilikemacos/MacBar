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
    if name in ("js-versions", "chat-whats-new"):
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


def js_versions_object(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    win = v.windows_release(data)
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
        },
        "windows": {
            "id": win["id"],
            "exe": win["exe"],
            "ps1": win["ps1"],
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


def nav_badge(data: dict) -> str:
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    return f'  <div class="nav-badge">{stable["label"]} · {beta["label"]} · macOS</div>'


def hero_stable_card(data: dict) -> str:
    s = v.stable_release(data)
    other = other_downloads_panel(
        "hero-stable-other",
        f"""            <button type="button" class="btn btn-secondary" onclick="requestDownload('{s["pkg"]}')">{sized_label("PKG installer", s["pkg"])}</button>
            <button type="button" class="btn btn-secondary" onclick="requestDownload('{s["dmg"]}')">{sized_label("DMG disk image", s["dmg"])}</button>
            <button type="button" class="btn btn-sh btn-sh-green" onclick="requestDownload('{s["sh"]}')">{sized_label("Shell installer (.sh)", s["sh"])}</button>
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
            <button class="btn btn-secondary" onclick="copyCmd('beta')">⎘ Copy bash command</button>""",
        note="<strong>Beta notice:</strong> Experimental AI — Terms required. <strong>.sh</strong> = full source compile on your Mac if you don't trust pre-built PKGs.",
    )
    return f"""    <div style="width:100%; background:var(--card); border:1px solid var(--orange); border-radius:12px; padding:20px; text-align:center;">
      <div style="font-family:var(--mono); font-size:16px; font-weight:700; color:var(--orange); margin-bottom:4px;">{b["id"]}</div>
      <div style="font-size:16px; color:var(--muted); margin-bottom:0;">Beta — stable features plus AI chat API: Gemini, OpenAI, Anthropic, Groq, DeepSeek, OpenRouter, LM Studio, Ollama, and Hermes.</div>
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


def hero_dl_note(data: dict) -> str:
    return """    <p style="color:var(--muted); font-size:15px; font-family:var(--mono); text-align:center; max-width:560px; margin-top:12px; line-height:1.55;">
      New here? Use the green <strong style="color:var(--green);">Recommended Download</strong> (App ZIP) above. Expand <strong style="color:var(--text);">Other download options</strong> for PKG, DMG, or shell installers.
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
    return """        <h3>Or use the .sh installer (if you don't trust the PKG)</h3>
        <p>If you're unsure about a pre-built PKG, download the highlighted <strong>.sh</strong> file instead. It contains the full app source — read it first, then compile locally. Stable:</p>"""


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
      <div class="feature-desc">Available in {b["id"]} — Chat tab with Gemini, OpenAI, Anthropic, Groq, DeepSeek, OpenRouter, LM Studio, Ollama, and Hermes (Keychain for cloud keys; local providers need no key).</div>
    </div>"""


def install_sh_commands(data: dict) -> str:
    s = v.stable_release(data)
    b = v.beta_release(data)
    return f"""        <div style="margin-top:10px; background:var(--card2); border:1px solid var(--border); border-radius:8px; padding:12px 16px; font-family:var(--mono); font-size:16px; color:var(--green);">
          bash ~/Downloads/{s["sh"]}
        </div>
        <p style="margin-top:8px;">Beta: <code>bash ~/Downloads/{b["sh"]}</code>. Installs to <code>~/Applications/rNitro.app</code> — takes ~30 seconds. Self-verifies its SHA-256 checksum before running.</p>"""


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
      <p>Beta macOS build — {s["short"]} features plus AI chat API (Gemini, OpenAI, Anthropic, Groq, DeepSeek, OpenRouter, LM Studio, Ollama, Hermes).</p>
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
    archive = data.get("archive") or []
    rows = []
    for row in archive:
        ch = row["channel"]
        ch_color = "var(--green)" if ch == "stable" else "var(--orange)"
        ch_label = "Stable" if ch == "stable" else "Beta"
        short_hash = row["sh_hash"][:16] + "…"
        rows.append(
            f"""      <tr>
        <td style="color:var(--text); font-weight:600;">{row["id"]}</td>
        <td><span class="prev-channel" style="color:{ch_color}; border-color:{ch_color};">{ch_label}</span></td>
        <td>{_archive_link(row.get("sh"), ".sh")}</td>
        <td>{_archive_link(row.get("pkg"), "PKG")}</td>
        <td>{_archive_link(row.get("dmg"), "DMG")}</td>
        <td class="prev-hash" title="{row["sh_hash"]}">{short_hash}</td>
      </tr>"""
        )
    body = "\n".join(rows) if rows else '      <tr><td colspan="6" style="color:var(--muted);">No archive builds staged.</td></tr>'
    return f"""  <div id="prev-versions-panel" class="prev-versions-panel" style="margin-top:16px;">
    <button type="button" class="prev-versions-toggle" onclick="togglePreviousVersions()" aria-expanded="false">
      <span>Previous versions</span>
      <span class="prev-versions-chevron" aria-hidden="true">▸</span>
    </button>
    <p class="prev-versions-note">Older builds for rollback or compatibility — use if a newer release misbehaves on your Mac.</p>
    <div class="prev-versions-body">
      <div class="prev-versions-scroll">
        <table class="prev-versions-table">
          <thead>
            <tr>
              <th>Version</th><th>Channel</th><th>.sh</th><th>PKG</th><th>DMG</th><th>SHA-256 (.sh)</th>
            </tr>
          </thead>
          <tbody>
{body}
          </tbody>
        </table>
      </div>
    </div>
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
        "nav-badge": nav_badge(data),
        "hero-stable": hero_stable_card(data),
        "hero-beta": hero_beta_card(data),
        "hero-more": hero_more_downloads(data),
        "hero-windows": hero_windows_buttons(data),
        "feature-ai-chat": feature_ai_chat(data),
        "install-sh-commands": install_sh_commands(data),
        "hero-dl-note": hero_dl_note(data),
        "install-step-pkg": install_step_pkg(data),
        "install-step-sh": install_step_sh(data),
        "download-stable": download_card_stable(data),
        "download-beta": download_card_beta(data),
        "download-more": download_more_section(data),
        "download-previous": download_previous_section(data),
        "download-windows": download_card_windows(data),
        "stable-beta-compare": stable_beta_compare_section(changelog, data),
        "whats-new": whats_new_section(changelog),
        "changelog": changelog_section(changelog),
        "chat-whats-new": chat_whats_new_kb(data, changelog),
        "js-versions": js_versions_object(data),
    }
    for name, content in regions.items():
        html = sync_region(html, name, content)
    INDEX.write_text(html, encoding="utf-8")
    print(f"Updated {INDEX.name}")


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

    print("\nDone. version.json:")
    print(f"  latest: {data['latest']}")
    print(f"  beta:   {data['beta']}")
    print(f"  stable SHA: {data['hashes']['stable_sh'][:16]}…")
    print(f"  beta SHA:   {data['hashes']['beta_sh'][:16]}…")


if __name__ == "__main__":
    main()