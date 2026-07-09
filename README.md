# rNitro

> Real-time CPU monitor for macOS — usage, temperature, clock speed, and per-core breakdown.

**[→ getrnitro.netlify.app](https://getrnitro.netlify.app/)**

### Homebrew

```bash
brew tap ilikemacos/rnitro
brew install rnitro
```

If Homebrew reports permission errors on `/opt/homebrew`, run `sudo chown -R "$(whoami)" /opt/homebrew/Cellar /opt/homebrew/Library` and try again. Or use the [install script](https://github.com/ilikemacos/homebrew-rnitro/blob/main/install.sh) (same result, no Homebrew).

---

## Download (GitHub Releases)

Each release includes **App ZIP** (with `rNitro.app`), **PKG**, and **DMG**.

### Stable — v8.3.5 Final

| Format | File |
|--------|------|
| **App ZIP** | [rNitro-v8.3.5-Final-arm64.zip](https://github.com/ilikemacos/rNitro/releases/download/v8.3.5-Final/rNitro-v8.3.5-Final-arm64.zip) |
| **PKG** | [rNitro-v8.3.5-Final-arm64.pkg](https://github.com/ilikemacos/rNitro/releases/download/v8.3.5-Final/rNitro-v8.3.5-Final-arm64.pkg) |
| **DMG** | [rNitro-v8.3.5-Final-arm64.dmg](https://github.com/ilikemacos/rNitro/releases/download/v8.3.5-Final/rNitro-v8.3.5-Final-arm64.dmg) |

### Beta — v8.3.8

| Format | File |
|--------|------|
| **App ZIP** | [rNitro-v8.3.8-Beta-arm64.zip](https://github.com/ilikemacos/rNitro/releases/download/v8.3.8-Beta/rNitro-v8.3.8-Beta-arm64.zip) |
| **PKG** | [rNitro-v8.3.8-Beta-arm64.pkg](https://github.com/ilikemacos/rNitro/releases/download/v8.3.8-Beta/rNitro-v8.3.8-Beta-arm64.pkg) |
| **DMG** | [rNitro-v8.3.8-Beta-arm64.dmg](https://github.com/ilikemacos/rNitro/releases/download/v8.3.8-Beta/rNitro-v8.3.8-Beta-arm64.dmg) |

[All releases →](https://github.com/ilikemacos/rNitro/releases)

### Install from App ZIP

1. Download the `.zip` for Stable or Beta
2. Unzip → drag **rNitro.app** into **Applications**
3. First launch: right-click → **Open** → **Open** (once) if Gatekeeper blocks it

---

## What it shows

- **CPU Usage** — total load with a 60-second live history graph
- **Temperature** — die temperature in °C, color-coded by intensity
- **Clock Speed** — base and boost MHz tracked in real time
- **Per-Core Breakdown** — usage bar and clock speed for every logical core

---

## Requirements

- macOS 12 Ventura or later (macOS 16 is advised)
- Apple Silicon (M1 / M2 / M3)

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
| `rNitro-v*.sh` | Archived installer scripts (one per release) |
| `index.html`, `boba-game/` | Website and embedded game assets |

Pre-built `.zip`, `.pkg`, and `.dmg` files are published on [GitHub Releases](https://github.com/ilikemacos/rNitro/releases), not committed here.

### Build from source (macOS)

```bash
git clone https://github.com/ilikemacos/rNitro.git
cd rNitro
bash install-rNitro.sh
```

Requires Xcode Command Line Tools (`xcode-select --install`). The script compiles with `swiftc`, installs `rNitro.app` to `~/Applications`, and adds a `rnitro` CLI to `~/.local/bin`.

### Build a release ZIP locally

```bash
python3 sync-versions.py
python3 build-app-zip.py --variant beta   # or stable / all
```

---

## License

[MIT](LICENSE)