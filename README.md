# rNitro

> Free menu bar system monitor for Apple Silicon Macs — CPU, temperature, battery, GPU, RAM, and network. Open source. No account. No telemetry.

**[Download](https://getrnitro.netlify.app/)** · **[chopstickshq.com/rnitro](https://chopstickshq.com/rnitro/)** · **[CLI](https://getrnitro.netlify.app/cli.html)** · **[Linux](https://getrnitro.netlify.app/linux.html)** · **[Windows](https://getrnitro.netlify.app/windows.html)** · **[Privacy](https://getrnitro.netlify.app/privacy.html)** · **[Releases](https://github.com/ilikemacos/rNitro/releases)**

> Same product site at **[getrnitro.netlify.app](https://getrnitro.netlify.app/)** and **[chopstickshq.com/rnitro](https://chopstickshq.com/rnitro/)** (HQ hub: [chopstickshq.com](https://chopstickshq.com/)).

[![Stable](https://img.shields.io/badge/stable-v1.2.9%20Final-00ff80)](https://github.com/ilikemacos/rNitro/releases/tag/v1.2.9-Final)
[![Beta](https://img.shields.io/badge/beta-v1.2.14-ff8c1a)](https://github.com/ilikemacos/rNitro/releases/tag/v1.2.14)
[![Experimental](https://img.shields.io/badge/experimental-v1.3.18--Exp-9b7bff)](https://github.com/ilikemacos/rNitro/releases/tag/v1.3.18-Experimental)

### Which channel?

| Channel | Version | Best for |
|---------|---------|----------|
| **Stable** | v1.2.9 Final | Daily monitoring; AI: OpenAI + OpenRouter |
| **Beta** | v1.2.14 | Lab tools + every AI provider |
| **Experimental** | v1.3.18 Exp | Newest features (unstable playground) |

Full feature matrix: [chopstickshq.com/rnitro](https://chopstickshq.com/rnitro/)

---

## Display modes

**Experimental (v1.3.18+)** and the **website** share the same display-mode config.

| Mode | Look |
|------|------|
| **System** | Follows macOS light/dark |
| **Light** | Classic light chrome |
| **Dark** | Classic dark chrome |
| **OLED** | Pure black (AMOLED-friendly) |
| **IPS** | Deep navy-black, richer midtones |
| **LCD** | Elevated blacks, softer contrast |
| **Mini LED** | Near-black with punchy highlights |

- **App:** Settings → Appearance → **Display mode** (menu picker). Stored as `rnitro.appearanceMode`.
- **Website:** nav **display mode** dropdown + **◐ Mode** cycle button. Stored in `localStorage` as `rnitro.siteTheme`.

---

## Install (macOS)

Prefer **App ZIP** from [Releases](https://github.com/ilikemacos/rNitro/releases) or the site (after accepting Terms).

| Format | Notes |
|--------|--------|
| **ZIP** | Unzip → drag `rNitro.app` to Applications / `~/Applications` |
| **PKG** | Double-click installer |
| **DMG** | Open image → drag app to Applications |
| **.sh** | Compiles from readable source on your Mac |

**Experimental ZIP (latest):**  
[rNitro-v1.3.18-Experimental.zip](https://github.com/ilikemacos/rNitro/releases/download/v1.3.18-Experimental/rNitro-v1.3.18-Experimental.zip)

First launch: if Gatekeeper blocks, right-click → **Open** → **Open**. Builds are ad-hoc signed (Apple notarization planned).

---

## Features (high level)

- Menu bar stats: CPU, temp, battery %, GPU, RAM, network
- Battery from local OS sources (IOPS / IOKit / pmset)
- Appearance: fonts (Google Fonts OFL catalog), size, language, monitor UI style
- **Display modes** (Exp): System / Light / Dark / OLED / IPS / LCD / Mini LED
- Beta/Exp: AI chat (bring your own API keys), Lab tools, Experimental extras
- CLI companion and limited Linux / Windows builds on the site

---

## Privacy

No accounts, no built-in telemetry. API keys (Chat) stay in Keychain when you use them. See [Privacy](https://getrnitro.netlify.app/privacy.html) and [Terms](https://getrnitro.netlify.app/terms.html).

---

## Links

| | |
|--|--|
| Product site | https://getrnitro.netlify.app/ |
| HQ / downloads | https://chopstickshq.com/rnitro/ |
| Releases | https://github.com/ilikemacos/rNitro/releases |
| Issues | https://github.com/ilikemacos/rNitro/issues |

---

## License

See repository / installer license notices. UI fonts: Google Fonts under the SIL Open Font License.
