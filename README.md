# MacBar

**Free open-source macOS menu bar system monitor** — CPU, temperature, battery, GPU, RAM, network.  
No account · no telemetry · no subscription.

Formerly **rNitro**. Installs as **MacBar.app**.

**Canonical site:** [https://chopstickshq.com/macbar/](https://chopstickshq.com/macbar/)  
**Hub:** [https://chopstickshq.com/](https://chopstickshq.com/) · **Releases:** [GitHub Releases](https://github.com/ilikemacos/MacBar/releases)

[![Download](https://img.shields.io/badge/download-v1.5.8-00ff80)](https://chopstickshq.com/macbar/)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111111)](https://chopstickshq.com/macbar/)
[![License: MIT](https://img.shields.io/badge/license-MIT-6b6b8a)](https://github.com/ilikemacos/MacBar/blob/main/LICENSE)

**Search keywords:** free macOS menu bar monitor · Apple Silicon CPU/temp · MacBook battery % · open-source iStat/Stats alternative · no telemetry · menubar system monitor

---

## Install (macOS 14+)

**Recommended — Terminal** (skips Gatekeeper; Apple Silicon):

```bash
printf "\n[######--------------] 1/3 Download\n" && curl --progress-bar -fL https://chopstickshq.com/macbar/MacBar-v1.5.8.zip -o /tmp/macbar.zip && printf "\n[############--------] 2/3 Unzip\n" && rm -rf /tmp/macbar-app && mkdir -p /tmp/macbar-app && unzip -qo /tmp/macbar.zip -d /tmp/macbar-app && printf "[####################] 3/3 Install\n" && mkdir -p ~/Applications && rm -rf ~/Applications/MacBar.app && ditto /tmp/macbar-app/MacBar.app ~/Applications/MacBar.app && xattr -cr ~/Applications/MacBar.app && printf "✓ Done → ~/Applications/MacBar.app\n"
```

Or:

1. Download the **App ZIP** from [chopstickshq.com/macbar](https://chopstickshq.com/macbar/) (accept Terms on the site) or [Releases](https://github.com/ilikemacos/MacBar/releases).
2. Unzip → drag **MacBar.app** to **Applications** (or `~/Applications`).
3. First launch: if macOS blocks it, **right-click MacBar.app → Open → Open**.

Builds are ad-hoc signed (not Apple-notarized yet). Prefer Terminal install or the App ZIP from the site.

**Intel Macs:** last Intel updates through **v1.2.5-Beta**. Apple Silicon continues to receive updates.

---

## Why MacBar

- **Free** alternative to paid menu bar monitors (not affiliated with iStat Menus or Stats)
- **Local-first** — sensors via macOS APIs (IOPS / IOKit / pmset)
- **No account, no product telemetry**
- **Optional AI chat** with *your* API keys in Keychain, plus cs.AI on supported builds
- **Open source** — this repo and the site installers

---

## Features

- Menu bar: CPU, temp, battery %, GPU, RAM, network
- Battery % aligned with the macOS menu bar
- Monitor UI: Modern · Legacy · New style
- Display modes: System / Light / Dark / OLED / IPS / LCD / Mini LED
- Lab tools, Advisor, App cleaner, and Chat on current macOS builds
- Lightweight sampling so MacBar stays out of top CPU processes

**Requires:** macOS **14.0+** (Sonoma) · universal binary when available

---

## Docs & guides

| Guide | Link |
|-------|------|
| Product site | [chopstickshq.com/macbar](https://chopstickshq.com/macbar/) |
| Privacy | [privacy.html](https://chopstickshq.com/macbar/privacy.html) |
| Terms | [terms.html](https://chopstickshq.com/macbar/terms.html) |
| FAQ | [faq.html](https://chopstickshq.com/macbar/faq.html) |

---

## Chopsticks HQ

| Product | URL |
|---------|-----|
| **HQ hub** | https://chopstickshq.com/ |
| **MacBar** | https://chopstickshq.com/macbar/ |
| **cs.AI** | https://chopstickshq.com/chopsticks-ai/ |
| **Fathom** | https://chopstickshq.com/fathom/ |

---

## Support

- Issues: [github.com/ilikemacos/MacBar/issues](https://github.com/ilikemacos/MacBar/issues)
- Site: [chopstickshq.com/macbar](https://chopstickshq.com/macbar/)

---

## License

MIT — see [LICENSE](LICENSE). UI fonts: Google Fonts under the SIL Open Font License where bundled.
