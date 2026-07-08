# rNitro

> Real-time CPU monitor for macOS — usage, temperature, clock speed, and per-core breakdown.

**[→ getrnitro.netlify.app](https://getrnitro.netlify.app/)**

---

## Download

**One ZIP with everything** — website, stable + beta apps, PKG/DMG, `.sh` installers, Windows builds:

| | |
|--|--|
| **Full bundle** | [⬇ rnitro-netlify.zip](https://github.com/ilikemacos/rNitro/releases/latest/download/rnitro-netlify.zip) |
| **All releases** | [github.com/ilikemacos/rNitro/releases](https://github.com/ilikemacos/rNitro/releases) |

### After download

1. Unzip `rnitro-netlify.zip` anywhere
2. Double-click **`OPEN-WEBSITE.command`** to open the local download page
3. Pick **Stable** (v8.2.6) or **Beta** (v8.2.8) App ZIP, or use PKG / DMG / `.sh`

### Install from App ZIP (inside the bundle)

1. Unzip the stable or beta App ZIP
2. Drag **rNitro.app** into **Applications**
3. First launch: right-click → **Open** → **Open** (once) if Gatekeeper blocks it

### Install from source (.sh)

```bash
bash rNitro-v8.2.6-Final-arm64.sh   # stable
bash rNitro-v8.2.8-Beta-arm64.sh    # beta
```

Compiles natively on your Mac (~30 seconds) → `~/Applications/rNitro.app`

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
- Xcode Command Line Tools (`xcode-select --install`) for `.sh` compile path

---

## Notes

Apple Silicon doesn't expose die temperature through public APIs without special entitlements, so rNitro uses a calibrated thermal model (base 35°C + load curve) that closely tracks real-world readings. For exact values, run `sudo powermetrics --samplers cpu_power` in Terminal alongside the app.

---

## License

MIT