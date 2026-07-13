#!/usr/bin/env python3
"""Generate standalone download pages: cli.html, linux.html, windows.html."""
from __future__ import annotations

import json
from pathlib import Path

import versions as v

SITE = v.SITE
SITE_URL = "https://getrnitro.netlify.app"

# Shared look-and-feel (matches main site tokens)
_CSS = """
  @font-face {
    font-family: 'Varela Round';
    src: url('VarelaRound.ttf') format('truetype');
    font-weight: 400; font-style: normal; font-display: swap;
  }
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  :root {
    --bg: #0A0A0F; --bg2: #0F0F18; --card: #13131E; --card2: #1A1A28;
    --border: #2A2A40; --cyan: #00D9FF; --green: #00FF80; --orange: #FF8C1A;
    --text: #E8E8F0; --muted: #6B6B8A;
    --mono: ui-monospace, Menlo, monospace;
    --sans: 'Varela Round', -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
  }
  html, body { font-family: var(--sans); background: var(--bg); color: var(--text); min-height: 100vh; }
  a { color: var(--cyan); }
  code { font-family: var(--mono); font-size: 0.92em; color: var(--cyan); }
  .wrap { max-width: 720px; margin: 0 auto; padding: 28px 16px 64px; }
  .nav { display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; margin-bottom: 28px; }
  .nav a {
    display: inline-block; padding: 6px 16px; border-radius: 20px; border: 1px solid var(--border);
    text-decoration: none; color: var(--text); font-family: var(--mono); font-size: 14px; font-weight: 500;
  }
  .nav a:hover { border-color: var(--cyan); }
  .nav a.active { color: #000; font-weight: 600; }
  .eyebrow { font-family: var(--mono); font-size: 12px; letter-spacing: 0.04em; margin-bottom: 8px; }
  h1 { font-size: 32px; font-weight: 700; margin: 0 0 10px; line-height: 1.2; }
  h1 span { color: var(--cyan); }
  .lead { color: var(--muted); font-size: 16px; line-height: 1.65; margin-bottom: 20px; max-width: 640px; }
  .desc {
    background: var(--card); border: 1px solid var(--border); border-radius: 12px;
    padding: 18px 20px; margin-bottom: 22px; line-height: 1.65; font-size: 15px;
  }
  .desc h2 { font-family: var(--mono); font-size: 13px; color: var(--muted); margin: 0 0 10px; text-transform: uppercase; letter-spacing: 0.04em; }
  .desc ul { margin: 8px 0 0 1.15em; color: var(--text); }
  .desc li { margin-bottom: 6px; color: var(--muted); }
  .desc li strong { color: var(--text); }
  .btn {
    display: inline-block; padding: 10px 16px; border-radius: 8px; border: 1px solid var(--border);
    background: var(--card2); color: var(--text); font-family: var(--mono); font-size: 14px;
    cursor: pointer; text-decoration: none;
  }
  .btn:hover { border-color: var(--cyan); }
  .btn-primary { border: none; font-weight: 600; }
  .btn-secondary { background: transparent; }
  .btn-recommended { width: 100%; padding: 14px 18px !important; font-size: 16px !important; }
  .dl-recommended {
    background: var(--card2); border: 1px solid rgba(0,255,136,0.4); border-radius: 12px;
    padding: 16px 18px; margin-top: 14px; text-align: left;
  }
  .dl-recommended-badge {
    display: inline-block; font-family: var(--mono); font-size: 11px; padding: 2px 8px;
    border-radius: 12px; border: 1px solid; margin-bottom: 8px;
  }
  .dl-recommended-title { font-family: var(--mono); font-size: 18px; font-weight: 700; margin: 0 0 6px; }
  .dl-recommended-steps { font-size: 13px; color: var(--muted); line-height: 1.55; margin: 0 0 12px; }
  .dl-other-panel { margin-top: 12px; text-align: left; }
  .prev-versions-toggle {
    width: 100%; display: flex; justify-content: space-between; align-items: center;
    background: transparent; border: 1px solid var(--border); border-radius: 8px;
    color: var(--muted); padding: 10px 12px; font-family: var(--mono); font-size: 13px; cursor: pointer;
  }
  .prev-versions-body { display: none; padding-top: 10px; }
  .dl-other-panel.is-open .prev-versions-body { display: block; }
  .dl-other-grid { display: flex; flex-wrap: wrap; gap: 8px; }
  .dl-other-note { font-size: 13px; color: var(--muted); margin-top: 10px; line-height: 1.5; }
  .platform-banner {
    font-size: 14px; border-radius: 8px; padding: 10px 12px; margin-bottom: 12px; line-height: 1.5; text-align: left;
  }
  .platform-banner--deprecated {
    color: var(--orange); background: rgba(255,140,26,0.08); border: 1px solid rgba(255,140,26,0.35);
  }
  .footer { margin-top: 36px; text-align: center; font-family: var(--mono); font-size: 13px; color: var(--muted); }
  .footer a { margin: 0 8px; }
  #toast {
    position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%) translateY(20px);
    background: var(--card); border: 1px solid var(--green); color: var(--green);
    padding: 10px 18px; border-radius: 8px; font-family: var(--mono); font-size: 13px;
    opacity: 0; pointer-events: none; transition: 0.2s; z-index: 9999;
  }
  #toast.show { opacity: 1; transform: translateX(-50%) translateY(0); }
  .tc-overlay {
    display: none; position: fixed; inset: 0; z-index: 10000; background: rgba(10,10,15,0.92);
    align-items: center; justify-content: center; padding: 20px;
  }
  .tc-overlay.open { display: flex; }
  .tc-box {
    background: var(--card); border: 1px solid var(--border); border-radius: 12px;
    max-width: 480px; width: 100%; padding: 22px; text-align: left;
  }
  .tc-box h2 { font-size: 18px; margin-bottom: 8px; }
  .tc-box p { color: var(--muted); font-size: 14px; line-height: 1.55; margin-bottom: 14px; }
  .tc-actions { display: flex; gap: 10px; flex-wrap: wrap; }
"""


def _nav(active: str) -> str:
    items = [
        ("mac", "/", "🍎 macOS", "var(--green)"),
        ("cli", "/cli.html", "⌨️ CLI", "#a78bfa"),
        ("linux", "/linux.html", "🐧 Linux", "#e8a838"),
        ("win", "/windows.html", "🪟 Windows", "var(--cyan)"),
    ]
    links = []
    for key, href, label, accent in items:
        if key == active:
            links.append(
                f'<a class="active" href="{href}" style="background:{accent}; border-color:{accent}; color:#000;">{label}</a>'
            )
        else:
            links.append(f'<a href="{href}">{label}</a>')
    return f'<nav class="nav" aria-label="Platform">{chr(10).join(links)}</nav>'


def _terms_overlay() -> str:
    return """
<div id="tc-overlay" class="tc-overlay" role="dialog" aria-modal="true">
  <div class="tc-box">
    <h2 id="tc-title">Terms &amp; Conditions</h2>
    <p>By downloading you agree to the <a href="terms-and-conditions.txt" target="_blank" rel="noopener">rNitro Terms</a>. Software is provided as-is. Beta features may be unstable.</p>
    <p id="tc-download-file" style="font-family:var(--mono); font-size:12px; color:var(--cyan);"></p>
    <div class="tc-actions">
      <button type="button" class="btn btn-primary" style="background:var(--green); color:#000;" id="tc-agree-btn">Agree &amp; download</button>
      <button type="button" class="btn btn-secondary" id="tc-cancel-btn">Cancel</button>
    </div>
  </div>
</div>
<div id="toast"></div>
"""


def _download_js(data: dict) -> str:
    # Minimal version payload for download helpers
    stable = v.stable_release(data)
    beta = v.beta_release(data)
    win = v.windows_release(data)
    linux = v.linux_release(data)
    cli = v.cli_release(data)
    payload = {
        "stable": {"id": stable["id"], "sh": stable["sh"], "curlInstall": f"curl -fsSL {SITE_URL}/{stable['sh']} -o /tmp/rnitro-install.sh && bash /tmp/rnitro-install.sh"},
        "beta": {"id": beta["id"], "sh": beta["sh"], "curlInstall": f"curl -fsSL {SITE_URL}/{beta['sh']} -o /tmp/rnitro-install.sh && bash /tmp/rnitro-install.sh"},
        "windows": {"id": win["id"], "exe": win["exe"], "ps1": win["ps1"]},
        "linux": {"id": linux["id"], "tar": linux["tar"], "sh": linux["sh"]},
        "cli": {
            "id": cli["id"],
            "tar": cli["tar"],
            "curlInstall": (
                f"curl -fsSL {SITE_URL}/{cli['tar']} -o /tmp/rnitro-cli.tar.gz && "
                "mkdir -p /tmp/rnitro-cli && tar xzf /tmp/rnitro-cli.tar.gz -C /tmp/rnitro-cli && "
                "bash /tmp/rnitro-cli/install-cli.sh"
            ),
        },
    }
    versions_js = json.dumps(payload, indent=2)
    return f"""
<script>
  const RNITRO_VERSIONS = {versions_js};
  let pendingDownload = null;
  const TERMS_KEY = 'rnitro_terms_ok';

  function toast(msg) {{
    const el = document.getElementById('toast');
    if (!el) return;
    el.textContent = msg;
    el.classList.add('show');
    setTimeout(() => el.classList.remove('show'), 2500);
  }}

  function toggleOtherDownloads(panelId) {{
    const panel = document.getElementById(panelId);
    if (!panel) return;
    const open = panel.classList.toggle('is-open');
    const btn = panel.querySelector('.prev-versions-toggle');
    if (btn) btn.setAttribute('aria-expanded', open ? 'true' : 'false');
  }}

  function requestDownload(url) {{
    if (!url) return;
    try {{
      if (sessionStorage.getItem(TERMS_KEY) === '1') {{
        window.location.href = url;
        return;
      }}
    }} catch (e) {{ /* private mode */ }}
    pendingDownload = url;
    const name = url.split('/').pop();
    const label = document.getElementById('tc-download-file');
    if (label) label.textContent = name;
    document.getElementById('tc-overlay')?.classList.add('open');
  }}

  document.getElementById('tc-agree-btn')?.addEventListener('click', () => {{
    try {{ sessionStorage.setItem(TERMS_KEY, '1'); }} catch (e) {{}}
    document.getElementById('tc-overlay')?.classList.remove('open');
    if (pendingDownload) {{
      const u = pendingDownload;
      pendingDownload = null;
      window.location.href = u;
    }}
  }});
  document.getElementById('tc-cancel-btn')?.addEventListener('click', () => {{
    pendingDownload = null;
    document.getElementById('tc-overlay')?.classList.remove('open');
  }});

  function copyText(cmd, okMsg) {{
    navigator.clipboard.writeText(cmd).then(() => toast(okMsg || '✓ Copied'));
  }}
  function copyCliInstall() {{
    copyText(RNITRO_VERSIONS.cli?.curlInstall || '', '✓ CLI install command copied');
  }}
  function copyLinuxCmd() {{
    const sh = RNITRO_VERSIONS.linux?.sh || 'install-rNitro-linux.sh';
    copyText('bash ~/' + 'Downloads/' + sh, '✓ Bash command copied');
  }}
  function copyWinCmd() {{
    const ps1 = RNITRO_VERSIONS.windows?.ps1 || '';
    copyText('powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\\\\Downloads\\\\' + ps1, '✓ PowerShell command copied');
  }}
</script>
"""


def _page(
    *,
    data: dict,
    slug: str,
    active: str,
    title: str,
    description: str,
    eyebrow: str,
    accent: str,
    lead: str,
    desc_html: str,
    download_html: str,
) -> str:
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title}</title>
<meta name="description" content="{description}">
<link rel="canonical" href="{SITE_URL}/{slug}">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{description}">
<meta property="og:url" content="{SITE_URL}/{slug}">
<meta property="og:image" content="{SITE_URL}/screenshots/hero-monitor.png">
<link rel="icon" href="favicon.ico" sizes="any">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
<style>{_CSS}</style>
</head>
<body>
  <div class="wrap">
    {_nav(active)}
    <p class="eyebrow" style="color:{accent};">{eyebrow}</p>
    <h1>{title.split("—")[0].strip() if "—" in title else title}</h1>
    <p class="lead">{lead}</p>
    <div class="desc">
{desc_html}
    </div>
    <div style="max-width:640px; margin:0 auto;">
{download_html}
    </div>
    <div class="footer">
      <a href="/">macOS downloads</a>
      <a href="/privacy.html">Privacy</a>
      <a href="https://github.com/ilikemacos/rNitro/releases">GitHub Releases</a>
    </div>
  </div>
  {_terms_overlay()}
  {_download_js(data)}
</body>
</html>
"""


def _sv():
    """Load sync-versions.py (hyphenated filename) without circular import issues."""
    from importlib import util

    path = SITE / "sync-versions.py"
    spec = util.spec_from_file_location("rnitro_sync_versions", path)
    mod = util.module_from_spec(spec)
    assert spec.loader
    spec.loader.exec_module(mod)
    return mod


def build_cli_page(data: dict) -> str:
    sv = _sv()

    cli = v.cli_release(data)
    download = sv.hero_cli_card(data)
    desc = f"""      <h2>About rNitro CLI</h2>
      <p><strong>rNitro CLI ({cli["version"]})</strong> is a terminal dashboard in the spirit of btop — for when you want the same rNitro metrics over SSH or without a menu bar.</p>
      <ul>
        <li><strong>Live stats</strong> — CPU, memory, disk I/O, network, battery, and top processes</li>
        <li><strong>Where it runs</strong> — macOS and Linux, Python 3, no GUI required</li>
        <li><strong>Keys</strong> — <code>q</code> quit · <code>r</code> refresh · <code>rnitro --once</code> for one-shot JSON</li>
        <li><strong>Install</strong> — tarball + <code>install-cli.sh</code>, or the one-line curl install below</li>
      </ul>
      <p style="margin-top:12px; color:var(--muted);">Prefer the menu bar app? Go back to <a href="/">macOS downloads</a>.</p>"""
    return _page(
        data=data,
        slug="cli.html",
        active="cli",
        title="rNitro CLI — Terminal system monitor",
        description="rNitro CLI: btop-style terminal monitor for macOS and Linux. Live CPU, RAM, disk, network, battery, and top processes. Free, open source.",
        eyebrow="Terminal · macOS + Linux · Python 3",
        accent="#a78bfa",
        lead="A lightweight TUI for the same rNitro-style metrics — perfect for SSH, headless boxes, and keyboard-driven workflows.",
        desc_html=desc,
        download_html=download,
    )


def build_linux_page(data: dict) -> str:
    sv = _sv()

    lin = v.linux_release(data)
    download = sv.hero_linux_buttons(data)
    desc = f"""      <h2>About rNitro for Linux</h2>
      <p><strong>{lin["label"]}</strong> is a GTK 4 + libadwaita desktop companion to the macOS app — Monitor, Advisor, Chat, and App Cleaner on x86_64 Linux.</p>
      <ul>
        <li><strong>Status</strong> — pre-release; expect rough edges and platform gaps vs macOS</li>
        <li><strong>Requirements</strong> — Python 3.10+, GTK 4, libadwaita (and usually <code>python3-gi</code> / <code>lm-sensors</code>)</li>
        <li><strong>Install path</strong> — <code>~/.local/share/rnitro</code> with a desktop entry after running the installer</li>
        <li><strong>Metrics</strong> — Apple-only sensors (SMC, Mac Low Power Mode) show as N/A on Linux</li>
      </ul>
      <p style="margin-top:12px; color:var(--muted);">Also on <a href="{v.github_release_page_url(lin["id"])}">GitHub Releases</a>. For the polished daily driver, use <a href="/">macOS</a>.</p>"""
    return _page(
        data=data,
        slug="linux.html",
        active="linux",
        title="rNitro for Linux — GTK system monitor",
        description="rNitro Linux pre-release: GTK4 system monitor with Advisor, Chat, and Cleaner for Ubuntu, Fedora, and Debian. Free, open source.",
        eyebrow="Linux x86_64 · Pre-release · GTK 4",
        accent="#e8a838",
        lead="Desktop monitor for Linux with tabs that mirror the macOS beta feature set — still early, best for testers and power users.",
        desc_html=desc,
        download_html=download,
    )


def build_windows_page(data: dict) -> str:
    sv = _sv()

    win = v.windows_release(data)
    download = sv.hero_windows_buttons(data)
    desc = f"""      <h2>About rNitro for Windows</h2>
      <p><strong>Windows is no longer actively developed.</strong> The last tray build (<code>{win["id"]}</code>) remains available so existing users can still download it.</p>
      <ul>
        <li><strong>What it does</strong> — system tray icon with CPU %, temperature, RAM, optional BTC, and short history graphs</li>
        <li><strong>EXE</strong> — needs <a href="https://dotnet.microsoft.com/download/dotnet/8.0">.NET 8 Desktop Runtime (x64)</a></li>
        <li><strong>PowerShell installer</strong> — compiles with built-in <code>csc.exe</code> (no Visual Studio SDK)</li>
        <li><strong>Install path</strong> — typically <code>%LOCALAPPDATA%\\rNitro</code></li>
      </ul>
      <p style="margin-top:12px; color:var(--muted);">For new installs we recommend <a href="/">macOS</a> or <a href="/linux.html">Linux</a>.</p>"""
    return _page(
        data=data,
        slug="windows.html",
        active="win",
        title="rNitro for Windows — tray monitor (legacy)",
        description="rNitro Windows legacy tray monitor (last build). CPU, temperature, RAM. Deprecated — macOS and Linux recommended for new installs.",
        eyebrow="Windows 10/11 · Legacy · Deprecated",
        accent="var(--cyan)",
        lead="Final Windows tray build kept for download only. No new features or active support — use macOS or Linux for current rNitro.",
        desc_html=desc,
        download_html=download,
    )


def write_platform_pages(data: dict | None = None) -> None:
    data = data or v.load()
    pages = {
        "cli.html": build_cli_page(data),
        "linux.html": build_linux_page(data),
        "windows.html": build_windows_page(data),
    }
    for name, html in pages.items():
        path = SITE / name
        path.write_text(html, encoding="utf-8")
        print(f"Updated {name}")


if __name__ == "__main__":
    write_platform_pages()
