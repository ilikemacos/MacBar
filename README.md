# rNitro

> Real-time CPU monitor for macOS — usage, temperature, clock speed, and per-core breakdown.

**[→ getrnitro.netlify.app](https://getrnitro.netlify.app/)**

---

## Download (macOS App ZIP)

Pick **Stable** for everyday use, or **Beta** for all AI providers and experimental features.

| Channel | Version | Download |
|---------|---------|----------|
| **Stable (Final)** | v8.2.6 | [⬇ App ZIP](https://github.com/ilikemacos/rNitro/releases/latest/download/rNitro-v8.2.6-Final-arm64.zip) |
| **Beta** | v8.2.8 | [⬇ App ZIP](https://github.com/ilikemacos/rNitro/releases/download/v8.2.8-Beta/rNitro-v8.2.8-Beta-arm64.zip) |

All releases: **[github.com/ilikemacos/rNitro/releases](https://github.com/ilikemacos/rNitro/releases)**

### Install from App ZIP

1. Download the ZIP for your channel (above)
2. Double-click to unzip `rNitro.app`
3. Drag **rNitro.app** into **Applications**
4. First launch: right-click → **Open** → **Open** (once) if Gatekeeper blocks it

### Install from source (.sh)

Download the installer from the [website](https://getrnitro.netlify.app/) or run:

```bash
bash ~/Downloads/rNitro-v8.2.6-Final-arm64.sh   # stable
# or
bash ~/Downloads/rNitro-v8.2.8-Beta-arm64.sh    # beta
```

The script compiles natively on your Mac (~30 seconds) and installs to `~/Applications/rNitro.app`.

---

## What it shows

- **CPU Usage** — total load with a 60-second live history graph
- **Temperature** — die temperature in °C, color-coded by intensity
- **Clock Speed** — base and boost MHz tracked in real time
- **Per-Core Breakdown** — usage bar and clock speed for every logical core

---

## Requirements

- macOS 12 Ventura or later (MacOS 16 is advised)
- Apple Silicon (M1 / M2 / M3)
- Xcode Command Line Tools (`xcode-select --install`)

---

## Notes

Apple Silicon doesn't expose die temperature through public APIs without special entitlements, so rNitro uses a calibrated thermal model (base 35°C + load curve) that closely tracks real-world readings. For exact values, run `sudo powermetrics --samplers cpu_power` in Terminal alongside the app.

---

## License

MIT
