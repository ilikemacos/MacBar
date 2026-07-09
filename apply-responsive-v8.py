#!/usr/bin/env python3
"""Apply responsive UI + v8.1.1 / v7.0.1a version prep to install-rNitro.sh."""
import re
from pathlib import Path

SRC = Path("/Users/mehmeh/rnitro-site-work/rnitro-site/install-rNitro.sh")
text = SRC.read_text()

# ── Version header ──
text = text.replace(
    "# v8.1-Beta-arm64 — Beta AI chat: Gemini, OpenAI, Anthropic, Groq, DeepSeek,\n"
    "# OpenRouter, LM Studio, Ollama, and Hermes. Per-provider Keychain keys.\n",
    "# v8.1.1-Beta-arm64 — Responsive UI, AI chat in menubar popover, per-provider history.\n"
    "# Gemini, OpenAI, Anthropic, Groq, DeepSeek, OpenRouter, LM Studio, Ollama, Hermes.\n",
    1,
)

text = text.replace('let CURRENT_VERSION = "v8.1-Beta-arm64"', 'let CURRENT_VERSION = "v8.1.1-Beta-arm64"')
text = text.replace("<key>CFBundleVersion</key><string>8.1-Beta-arm64</string>",
                    "<key>CFBundleVersion</key><string>8.1.1-Beta-arm64</string>")
text = text.replace("<key>CFBundleShortVersionString</key><string>8.1-Beta-arm64</string>",
                    "<key>CFBundleShortVersionString</key><string>8.1.1-Beta-arm64</string>")

# ── UIMetrics system (replace rNitroFont) ──
OLD_FONT = '''func rNitroFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom("Lazy Dog", size: size).weight(weight)
}'''

NEW_FONT = '''enum FontRole {
    case micro, caption, label, body, headline, title, statValue
}

struct UIMetrics: Equatable {
    let base: CGFloat
    let compact: Bool
    let hPad: CGFloat
    let statCellMin: CGFloat
    let graphHeight: CGFloat
    let bubbleSpacer: CGFloat

    func size(_ role: FontRole) -> CGFloat {
        switch role {
        case .micro: return base * 0.71
        case .caption: return base * 0.79
        case .label: return base * 0.86
        case .body: return base
        case .headline: return base * 1.07
        case .title: return base * 1.14
        case .statValue: return base * 1.29
        }
    }

    static func forWidth(_ w: CGFloat, layout: ContentLayout) -> UIMetrics {
        let compact = layout == .popover || w < 420
        let base: CGFloat = compact ? 12 : 14
        return UIMetrics(
            base: base,
            compact: compact,
            hPad: compact ? 10 : 16,
            statCellMin: compact ? 72 : 88,
            graphHeight: compact ? 28 : 36,
            bubbleSpacer: compact ? 20 : 40
        )
    }
}

private struct UIMetricsKey: EnvironmentKey {
    static let defaultValue = UIMetrics.forWidth(520, layout: .window)
}

extension EnvironmentValues {
    var uiMetrics: UIMetrics {
        get { self[UIMetricsKey.self] }
        set { self[UIMetricsKey.self] = newValue }
    }
}

func rNitroFont(_ role: FontRole, metrics: UIMetrics, weight: Font.Weight = .regular) -> Font {
    .custom("Lazy Dog", size: metrics.size(role)).weight(weight)
}

struct MetricsReader<Content: View>: View {
    let layout: ContentLayout
    @ViewBuilder let content: (UIMetrics) -> Content

    var body: some View {
        GeometryReader { geo in
            let metrics = UIMetrics.forWidth(geo.size.width, layout: layout)
            content(metrics)
                .frame(width: geo.size.width, height: geo.size.height)
                .environment(\\.uiMetrics, metrics)
        }
    }
}

struct ResponsiveStatGrid<Content: View>: View {
    @Environment(\\.uiMetrics) private var metrics
    @ViewBuilder let content: () -> Content

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: metrics.statCellMin), spacing: 0)],
            spacing: 8,
            content: content
        )
    }
}'''

if OLD_FONT not in text:
    raise SystemExit("rNitroFont block not found")
text = text.replace(OLD_FONT, NEW_FONT)

FONT_MAP = {
    "8": ".micro",
    "9": ".caption",
    "10": ".label",
    "11": ".body",
    "12": ".body",
    "13": ".headline",
    "14": ".headline",
    "15": ".title",
    "16": ".statValue",
}

def font_replace(m):
    size = m.group(1)
    rest = m.group(2) or ""
    role = FONT_MAP.get(size, ".body")
    return f"rNitroFont({role}, metrics: metrics{rest})"

text = re.sub(
    r"rNitroFont\((\d+(?:\.\d+)?)(, weight: [^)]+)?\)",
    font_replace,
    text,
)

text = text.replace(
    "rNitroFont(.body, metrics: metrics, weight: .semibold)",
    "rNitroFont(metrics.compact ? .label : .body, metrics: metrics, weight: .semibold)",
    1,
)

VIEWS_NEED_ENV = [
    "struct CoreRow: View {",
    "struct MinimalButton: View {",
    "struct AIChatView: View {",
    "struct UsageBarRow: View {",
    "struct StatCell: View {",
    "struct StatDetailPopup: View {",
    "struct ContentView: View {",
    "struct OverlayHUDView: View {",
]
for decl in VIEWS_NEED_ENV:
    if decl not in text:
        raise SystemExit(f"Missing {decl}")
    text = text.replace(
        decl,
        decl + "\n    @Environment(\\.uiMetrics) private var metrics",
        1,
    )

OLD_BODY = '''    var body: some View {
        Group {
            if layout == .window {
                rootContent
                    .sheet(item: $statDetail) { kind in
                        StatDetailPopup(kind: kind, monitor: m, battery: bat)
                    }
            } else {
                rootContent
            }
        }
        .preferredColorScheme(.dark)
    }'''

NEW_BODY = '''    var body: some View {
        MetricsReader(layout: layout) { _ in
            Group {
                if layout == .window {
                    rootContent
                        .sheet(item: $statDetail) { kind in
                            StatDetailPopup(kind: kind, monitor: m, battery: bat)
                        }
                } else {
                    rootContent
                }
            }
            .preferredColorScheme(.dark)
        }
    }'''

if OLD_BODY not in text:
    raise SystemExit("ContentView body not found")
text = text.replace(OLD_BODY, NEW_BODY)

text = text.replace(
    ".padding(.vertical, 10)",
    ".padding(.vertical, metrics.compact ? 8 : 10)",
    1,
)

OLD_HEADER = '''                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("rNitro").font(rNitroFont(.title, metrics: metrics, weight: .semibold))
                        Text(m.cpuName).font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                            .lineLimit(1).truncationMode(.tail)
                    }
                    Spacer()
                    HStack(spacing: 5) {
                        Circle().fill(Color.nGreen).frame(width: 5, height: 5)
                        Text("Live").font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 14)'''

NEW_HEADER = '''                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("rNitro").font(rNitroFont(.title, metrics: metrics, weight: .semibold))
                        Text(m.cpuName).font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                            .lineLimit(1).truncationMode(.tail)
                        Text(CURRENT_VERSION).font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary.opacity(0.75))
                    }
                    Spacer()
                    HStack(spacing: 5) {
                        Circle().fill(Color.nGreen).frame(width: 5, height: 5)
                        Text("Live").font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, metrics.hPad).padding(.top, 12).padding(.bottom, 14)'''

if OLD_HEADER not in text:
    raise SystemExit("Header block not found - fonts may not be converted yet")
text = text.replace(OLD_HEADER, NEW_HEADER)

OLD_STATS = '''                    HStack(spacing: 0) {
                        StatCell(title: "BASE", value: String(format: "%.0f", m.baseClock), unit: "MHz", color: .primary, action: { statDetail = .clock })
                        StatCell(title: "BOOST", value: String(format: "%.0f", m.boostClock), unit: "MHz", color: .accent, action: { statDetail = .clock })
                        StatCell(title: "TEMP", value: String(format: "%.0f", m.temperature), unit: "°C", color: Color.temp(m.temperature), action: { statDetail = .temperature })
                        StatCell(title: "CORES", value: "\\(m.logicalCores)", unit: "threads", color: .nGreen, action: { statDetail = .cores })
                    }
                    .padding(.vertical, 12).padding(.horizontal, 8)'''

NEW_STATS = '''                    ResponsiveStatGrid {
                        StatCell(title: "BASE", value: String(format: "%.0f", m.baseClock), unit: "MHz", color: .primary, action: { statDetail = .clock })
                        StatCell(title: "BOOST", value: String(format: "%.0f", m.boostClock), unit: "MHz", color: .accent, action: { statDetail = .clock })
                        StatCell(title: "TEMP", value: String(format: "%.0f", m.temperature), unit: "°C", color: Color.temp(m.temperature), action: { statDetail = .temperature })
                        StatCell(title: "CORES", value: "\\(m.logicalCores)", unit: "threads", color: .nGreen, action: { statDetail = .cores })
                    }
                    .padding(.vertical, 12).padding(.horizontal, metrics.compact ? 6 : 8)'''

if OLD_STATS not in text:
    raise SystemExit("Primary stats block not found")
text = text.replace(OLD_STATS, NEW_STATS)

OLD_BAT = '''                    HStack(spacing: 0) {
                        StatCell(
                            title: "BATTERY",
                            value: bat.isPresent ? "\\(bat.levelPercent)" : "—",
                            unit: "%",
                            color: bat.isCharging ? .nGreen : .accent,
                            action: bat.isPresent ? { statDetail = .battery } : nil
                        )
                        StatCell(
                            title: "CHARGE",
                            value: bat.isPresent ? bat.chargeRateText : "N/A",
                            unit: bat.isCharging ? "charging" : (bat.isPresent ? "status" : "desktop"),
                            color: bat.isCharging ? .nOrange : .secondary,
                            action: bat.isPresent ? { statDetail = .battery } : nil
                        )
                    }
                    .padding(.vertical, 12).padding(.horizontal, 8)'''

NEW_BAT = '''                    ResponsiveStatGrid {
                        StatCell(
                            title: "BATTERY",
                            value: bat.isPresent ? "\\(bat.levelPercent)" : "—",
                            unit: "%",
                            color: bat.isCharging ? .nGreen : .accent,
                            action: bat.isPresent ? { statDetail = .battery } : nil
                        )
                        StatCell(
                            title: "CHARGE",
                            value: bat.isPresent ? bat.chargeRateText : "N/A",
                            unit: bat.isCharging ? "charging" : (bat.isPresent ? "status" : "desktop"),
                            color: bat.isCharging ? .nOrange : .secondary,
                            action: bat.isPresent ? { statDetail = .battery } : nil
                        )
                    }
                    .padding(.vertical, 12).padding(.horizontal, metrics.compact ? 6 : 8)'''

if OLD_BAT not in text:
    raise SystemExit("Battery stats block not found")
text = text.replace(OLD_BAT, NEW_BAT)

text = text.replace(
    "GraphView(history: m.usageHistory, color: Color.usage(m.totalUsage))\n                            .frame(height: 36)",
    "GraphView(history: m.usageHistory, color: Color.usage(m.totalUsage))\n                            .frame(height: metrics.graphHeight)",
    1,
)

OLD_STATCELL = '''            VStack(spacing: 3) {
                Text(title).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary).tracking(0.5)
                Text(value).font(rNitroFont(.statValue, metrics: metrics, weight: .semibold)).foregroundColor(color)
                Text(unit).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())'''

NEW_STATCELL = '''            VStack(spacing: 3) {
                Text(title).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary).tracking(0.5)
                    .lineLimit(1).minimumScaleFactor(0.85)
                Text(value).font(rNitroFont(.statValue, metrics: metrics, weight: .semibold)).foregroundColor(color)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(unit).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary.opacity(0.8))
                    .lineLimit(1).minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())'''

text = text.replace(OLD_STATCELL, NEW_STATCELL)

text = text.replace(
    ".frame(width: 320, height: 340)",
    ".frame(minWidth: 260, idealWidth: 340, maxWidth: 420, minHeight: 280, idealHeight: 340, maxHeight: 440)",
    1,
)
text = text.replace(
    'Text(row.0).font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary).frame(width: 100, alignment: .leading)',
    'Text(row.0).font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary).frame(minWidth: 72, maxWidth: 120, alignment: .leading)',
    1,
)
text = text.replace(
    'Text(row.1).font(rNitroFont(.label, metrics: metrics)).frame(maxWidth: .infinity, alignment: .leading)',
    'Text(row.1).font(rNitroFont(.label, metrics: metrics)).frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)',
    1,
)

text = text.replace(
    'Text("C\\(index)").font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary).frame(width: 20, alignment: .leading)',
    'Text("C\\(index)").font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary).frame(minWidth: 18, maxWidth: 28, alignment: .leading).lineLimit(1)',
    1,
)
text = text.replace(
    '.frame(width: 30, alignment: .trailing)',
    '.frame(minWidth: 28, maxWidth: 40, alignment: .trailing).lineLimit(1)',
    1,
)

text = text.replace(
    'if msg.role == "user" { Spacer(minLength: 40) }',
    'if msg.role == "user" { Spacer(minLength: metrics.bubbleSpacer) }',
    1,
)
text = text.replace(
    'if msg.role != "user" { Spacer(minLength: 40) }',
    'if msg.role != "user" { Spacer(minLength: metrics.bubbleSpacer) }',
    1,
)

OLD_BENCH = '''                        HStack(spacing: 0) {
                            VStack(spacing: 2) {
                                Text("1-core").font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                                Text(bench.singleCoreScore.map { String(format: "%.0f", $0) } ?? "—")
                                    .font(rNitroFont(.headline, metrics: metrics, weight: .semibold)).foregroundColor(.accent)
                            }.frame(maxWidth: .infinity)
                            VStack(spacing: 2) {
                                Text("Multi").font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                                Text(bench.multiCoreScore.map { String(format: "%.0f", $0) } ?? "—")
                                    .font(rNitroFont(.headline, metrics: metrics, weight: .semibold)).foregroundColor(.nGreen)
                            }.frame(maxWidth: .infinity)
                            MinimalButton(
                                title: bench.isRunning ? "Running…" : "Run",
                                disabled: bench.isRunning || stress.isRunning,
                                action: { bench.run() }
                            )
                        }'''

NEW_BENCH = '''                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 0) {
                                VStack(spacing: 2) {
                                    Text("1-core").font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                                    Text(bench.singleCoreScore.map { String(format: "%.0f", $0) } ?? "—")
                                        .font(rNitroFont(.headline, metrics: metrics, weight: .semibold)).foregroundColor(.accent)
                                }.frame(maxWidth: .infinity)
                                VStack(spacing: 2) {
                                    Text("Multi").font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                                    Text(bench.multiCoreScore.map { String(format: "%.0f", $0) } ?? "—")
                                        .font(rNitroFont(.headline, metrics: metrics, weight: .semibold)).foregroundColor(.nGreen)
                                }.frame(maxWidth: .infinity)
                                MinimalButton(
                                    title: bench.isRunning ? "Running…" : "Run",
                                    disabled: bench.isRunning || stress.isRunning,
                                    action: { bench.run() }
                                )
                            }
                            VStack(spacing: 8) {
                                HStack(spacing: 0) {
                                    VStack(spacing: 2) {
                                        Text("1-core").font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                                        Text(bench.singleCoreScore.map { String(format: "%.0f", $0) } ?? "—")
                                            .font(rNitroFont(.headline, metrics: metrics, weight: .semibold)).foregroundColor(.accent)
                                    }.frame(maxWidth: .infinity)
                                    VStack(spacing: 2) {
                                        Text("Multi").font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                                        Text(bench.multiCoreScore.map { String(format: "%.0f", $0) } ?? "—")
                                            .font(rNitroFont(.headline, metrics: metrics, weight: .semibold)).foregroundColor(.nGreen)
                                    }.frame(maxWidth: .infinity)
                                }
                                MinimalButton(
                                    title: bench.isRunning ? "Running…" : "Run",
                                    disabled: bench.isRunning || stress.isRunning,
                                    action: { bench.run() }
                                )
                            }
                        }'''

if OLD_BENCH not in text:
    raise SystemExit("Benchmark block not found")
text = text.replace(OLD_BENCH, NEW_BENCH)

text = text.replace(
    ".padding(.horizontal, 12)\n                .padding(.vertical, 6)",
    ".padding(.horizontal, metrics.compact ? 10 : 12)\n                .padding(.vertical, metrics.compact ? 5 : 6)",
    1,
)

OLD_POP = '''        let popoverSize = NSSize(width: 400, height: 560)
        let popoverView = ContentView(tabs: AppTab.popoverTabs, layout: .popover)
            .frame(width: popoverSize.width, height: popoverSize.height)
            .fixedSize()
            .clipped()'''

NEW_POP = '''        let popoverSize = NSSize(width: 400, height: 560)
        let popoverView = ContentView(tabs: AppTab.popoverTabs, layout: .popover)
            .frame(minWidth: 320, idealWidth: 400, maxWidth: 480, minHeight: 480, idealHeight: 560, maxHeight: 720)
            .clipped()'''

text = text.replace(OLD_POP, NEW_POP)

text = text.replace(
    ".frame(minWidth:480,idealWidth:520,maxWidth:700,minHeight:620,idealHeight:700,maxHeight:900)",
    ".frame(minWidth:360,idealWidth:520,maxWidth:.infinity,minHeight:480,idealHeight:700,maxHeight:.infinity)",
    1,
)

text = text.replace(
    '''                StatDetailPopup(kind: kind, monitor: m, battery: bat)
                    .shadow(color: .black.opacity(0.4), radius: 12, y: 4)''',
    '''                StatDetailPopup(kind: kind, monitor: m, battery: bat)
                    .frame(maxWidth: 400)
                    .shadow(color: .black.opacity(0.4), radius: 12, y: 4)''',
    1,
)

OLD_CHAT_INPUT = '''            HStack(spacing: 8) {
                TextField("Message…", text: $chat.inputText)
                    .textFieldStyle(.plain)
                    .font(rNitroFont(.body, metrics: metrics))
                    .padding(8)
                    .background(Color.card)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.border.opacity(0.5), lineWidth: 1))
                    .onSubmit { chat.sendMessage() }
                MinimalButton(title: "Send", disabled: chat.isLoading || chat.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, action: { chat.sendMessage() })
            }'''

NEW_CHAT_INPUT = '''            HStack(spacing: 8) {
                TextField("Message…", text: $chat.inputText)
                    .textFieldStyle(.plain)
                    .font(rNitroFont(.body, metrics: metrics))
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.card)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.border.opacity(0.5), lineWidth: 1))
                    .onSubmit { chat.sendMessage() }
                MinimalButton(title: "Send", disabled: chat.isLoading || chat.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, action: { chat.sendMessage() })
                    .fixedSize()
            }'''

if OLD_CHAT_INPUT in text:
    text = text.replace(OLD_CHAT_INPUT, NEW_CHAT_INPUT)

SRC.write_text(text)
print("Applied responsive UI + version strings to install-rNitro.sh")