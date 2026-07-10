# rNitro

> Free menubar system monitor for Apple Silicon Macs — CPU, temperature, battery, GPU, RAM, and per-core stats. Open source, no account, no telemetry.

**[→ getrnitro.netlify.app](https://getrnitro.netlify.app/)**

### Quick install (Terminal)

<!-- @sync:readme-curl -->
**Stable (v8.3.6 Final):**
```bash
curl -fsSL https://getrnitro.netlify.app/rNitro-v8.3.6-Final-arm64.sh -o /tmp/rnitro-install.sh && bash /tmp/rnitro-install.sh
```

**Beta (v8.3.13 Beta):**
```bash
curl -fsSL https://getrnitro.netlify.app/rNitro-v8.3.13-Beta-arm64.sh -o /tmp/rnitro-install.sh && bash /tmp/rnitro-install.sh
```
<!-- @end:readme-curl -->

### Homebrew

```bash
brew tap ilikemacos/rnitro
brew install rnitro
```

If Homebrew reports permission errors on `/opt/homebrew`, run `sudo chown -R "$(whoami)" /opt/homebrew/Cellar /opt/homebrew/Library` and try again. Or use the [install script](https://github.com/ilikemacos/homebrew-rnitro/blob/main/install.sh) (same result, no Homebrew).

---

## Download (GitHub Releases)

Each release includes **App ZIP** (with `rNitro.app`), **PKG**, and **DMG**.

<!-- @sync:readme-downloads -->
### Stable — v8.3.6 Final

| Format | File |
|--------|------|
| **App ZIP** | [rNitro-v8.3.6-Final-arm64.zip](https://github.com/ilikemacos/rNitro/releases/download/v8.3.6-Final/rNitro-v8.3.6-Final-arm64.zip) |
| **PKG** | [rNitro-v8.3.6-Final-arm64.pkg](https://github.com/ilikemacos/rNitro/releases/download/v8.3.6-Final/rNitro-v8.3.6-Final-arm64.pkg) |
| **DMG** | [rNitro-v8.3.6-Final-arm64.dmg](https://github.com/ilikemacos/rNitro/releases/download/v8.3.6-Final/rNitro-v8.3.6-Final-arm64.dmg) |

### Beta — v8.3.13 Beta

| Format | File |
|--------|------|
| **App ZIP** | [rNitro-v8.3.13-Beta-arm64.zip](https://github.com/ilikemacos/rNitro/releases/download/v8.3.13-Beta/rNitro-v8.3.13-Beta-arm64.zip) |
| **PKG** | [rNitro-v8.3.13-Beta-arm64.pkg](https://github.com/ilikemacos/rNitro/releases/download/v8.3.13-Beta/rNitro-v8.3.13-Beta-arm64.pkg) |
| **DMG** | [rNitro-v8.3.13-Beta-arm64.dmg](https://github.com/ilikemacos/rNitro/releases/download/v8.3.13-Beta/rNitro-v8.3.13-Beta-arm64.dmg) |
<!-- @end:readme-downloads -->

[All releases →](https://github.com/ilikemacos/rNitro/releases)

### Install from App ZIP

1. Download the `.zip` for Stable or Beta
2. Unzip → drag **rNitro.app** into **Applications**
3. First launch: right-click → **Open** → **Open** (once) if Gatekeeper blocks it

---

## What it shows

- **CPU** — total usage, load average, per-core bars, base/boost MHz, package power (watts)
- **Temperature** — die temperature via SMC / IOHID sensors
- **Battery** — charge %, time remaining, charging state (MacBooks; direct IOKit read in v8.3.6+)
- **GPU & RAM** — usage, memory pressure, swap
- **Network** — live upload/download speeds on the active interface
- **Menubar** — configurable slots (CPU, temp, RAM, power, battery, BTC, and more)
- **System Advisor** — threshold warnings for temp, CPU, RAM, GPU, and battery (no API key)
- **Extras** — stress test, benchmark, app cleaner, optional AI chat (beta: 9 providers; stable: OpenAI + OpenRouter)

---

## Requirements

- macOS 12 Ventura or later
- Apple Silicon (M1 / M2 / M3 / M4)

---

## Open source

This repository contains the full rNitro source tree:

| Path | What it is |
|------|------------|
| `install-rNitro.sh` | Main macOS app — Swift UI, updater, monitors, AI chat (compiled by the script) |
| `install-rNitro-linux.sh` | Linux companion installer |
| `linux/` | Linux monitor source |
| `windows/` | Windows tray app (C# / WinForms) |
| `homebrew/` | Homebrew formula (also published at [ilikemacos/homebrew-rnitro](https://github.com/ilikemacos/homebrew-rnitro)) |
| `build-*.py`, `sync-versions.py`, `deploy-netlify.py` | Build, release, and site deploy tooling |
| `rNitro-v*.sh` | Generated on build (`sync-versions.py`) — older builds on [GitHub Releases](https://github.com/ilikemacos/rNitro/releases) |
| `index.html` | Download website |

Pre-built `.zip`, `.pkg`, and `.dmg` files are published on [GitHub Releases](https://github.com/ilikemacos/rNitro/releases), not committed here.

### Build from source (macOS)

```bash
git clone https://github.com/ilikemacos/rNitro.git
cd rNitro
bash install-rNitro.sh
```

Requires Xcode Command Line Tools (`xcode-select --install`). The script compiles with `swiftc` and installs `rNitro.app` to `~/Applications`.

### Build a release ZIP locally

```bash
python3 sync-versions.py          # writes rNitro-v{version}.sh from install-rNitro.sh
python3 build-app-zip.py --variant beta   # or stable / all
```

Older macOS `.sh` installers and all binaries live on [GitHub Releases](https://github.com/ilikemacos/rNitro/releases) — they are not stored in this repo.

---

## License

[MIT](LICENSE)