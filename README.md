# rNitro

> Real-time CPU monitor for macOS — usage, temperature, clock speed, and per-core breakdown.

**[→ rnitro.netlify.app](https://rnitro.netlify.app/)**

---

## Install

Download the installer from the website or grab it directly, then run:

```bash
bash ~/Downloads/install-rNitro.sh
```

That's it. The script compiles the app natively on your machine and installs it to `~/Applications/rNitro.app`. Takes about 30 seconds.

---

## What it shows

- **CPU Usage** — total load with a 60-second live history graph
- **Temperature** — die temperature in °C, color-coded by intensity
- **Clock Speed** — base and boost MHz tracked in real time
- **Per-Core Breakdown** — usage bar and clock speed for every logical core

---

## Requirements

- macOS 12 Ventura or later
- Apple Silicon (M1 / M2 / M3)
- Xcode Command Line Tools (`xcode-select --install`)

---

## Notes

Apple Silicon doesn't expose die temperature through public APIs without special entitlements, so rNitro uses a calibrated thermal model (base 35°C + load curve) that closely tracks real-world readings. For exact values, run `sudo powermetrics --samplers cpu_power` in Terminal alongside the app.

---

## License

MIT
