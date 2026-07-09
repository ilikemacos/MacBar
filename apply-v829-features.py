#!/usr/bin/env python3
"""Apply v8.2.9-Beta / v8.2.8-Final feature patches to install-rNitro.sh."""
from __future__ import annotations

import re
from pathlib import Path

SITE = Path(__file__).resolve().parent
SRC = SITE / "install-rNitro.sh"

BUILD_FLAGS = '''
let RNITRO_BUILD_CHANNEL = "beta"
let RNITRO_FEATURE_BETA_UI = (RNITRO_BUILD_CHANNEL == "beta")
'''

SECTION_STORE = '''
enum SectionExpansionStore {
    static let keys = [
        "rnitro.sectionExpanded.cpu",
        "rnitro.sectionExpanded.gpu",
        "rnitro.sectionExpanded.memory",
        "rnitro.sectionExpanded.disk",
        "rnitro.sectionExpanded.network",
        "rnitro.sectionExpanded.battery",
        "rnitro.sectionExpanded.sensors",
        "rnitro.sectionExpanded.settings"
    ]

    static func migrateExtrasKey() {
        let d = UserDefaults.standard
        if d.object(forKey: "rnitro.sectionExpanded.settings") == nil,
           d.object(forKey: "rnitro.sectionExpanded.extras") != nil {
            d.set(d.bool(forKey: "rnitro.sectionExpanded.extras"), forKey: "rnitro.sectionExpanded.settings")
        }
    }

    static func toggle(key: String, soloMode: Bool) {
        migrateExtrasKey()
        let d = UserDefaults.standard
        let expanding = !d.bool(forKey: key)
        if soloMode && expanding {
            for k in keys where k != key { d.set(false, forKey: k) }
        }
        d.set(expanding, forKey: key)
    }
}

'''

HARDWARE_MAPPER = '''
enum HardwareLabelMapper {
    static func networkInterface(_ iface: String) -> String {
        switch iface {
        case "en0": return "Wi-Fi"
        case "en1": return "Ethernet"
        case "en2", "en3": return "Thunderbolt"
        case "bridge0": return "Internet Sharing"
        case "awdl0": return "AirDrop / Wi-Fi Direct"
        case "lo0": return "Loopback"
        default:
            if iface.hasPrefix("en") { return "Network (\\(iface))" }
            return iface
        }
    }

    static func smcTemperature(_ key: String) -> (name: String, detail: String) {
        let map: [String: (String, String)] = [
            "Tp09": ("CPU Proximity", "Heat near the processor package"),
            "Tp0T": ("CPU Die", "Core-adjacent temperature"),
            "Tp01": ("Performance Cluster", "P-core region"),
            "Tp05": ("Efficiency Cluster", "E-core region"),
            "Te05": ("Efficiency Die", "Low-power core heat"),
            "Te0L": ("Logic Board", "Board-level sensor"),
            "TC0P": ("CPU Package", "Overall CPU temperature"),
            "TC0D": ("CPU Diode", "On-die sensor"),
            "TCPU": ("CPU", "Processor temperature"),
        ]
        if let m = map[key] { return (m.0, m.1) }
        if key.hasPrefix("Tp") { return ("CPU Sensor \\(key)", "SMC temperature key") }
        if key.hasPrefix("Te") { return ("Efficiency Sensor \\(key)", "Efficiency cluster sensor") }
        if key.hasPrefix("TC") { return ("Thermal \\(key)", "Thermal controller reading") }
        return ("Sensor \\(key)", "System Management Controller key")
    }

    static func fan(_ key: String) -> String {
        switch key {
        case "F0Ac", "F0Mn", "F0Md": return "Fan 1"
        case "F1Ac", "F1Mn", "F1Md": return "Fan 2"
        case "F2Ac": return "Fan 3"
        default: return "Fan \\(key)"
        }
    }

    static func coreLabel(index: Int, isEfficiency: Bool, clusterIndex: Int) -> String {
        isEfficiency ? "E\\(clusterIndex + 1)" : "P\\(clusterIndex + 1)"
    }
}

'''

WEATHER_SERVICE = '''
class WeatherService: ObservableObject {
    static let shared = WeatherService()

    struct Snapshot: Equatable {
        let city: String
        let tempC: Double
        let condition: String
    }

    @Published var snapshot: Snapshot?
    @Published var isLoading = false

    private var lastNetworkKey = ""
    private var lastFetch: Date?
    private let cacheTTL: TimeInterval = 1800

    func refresh(forNetworkKey key: String, enabled: Bool) {
        guard enabled, !key.isEmpty else { snapshot = nil; return }
        if key == lastNetworkKey, let snap = cachedSnapshot(for: key),
           let last = lastFetch, Date().timeIntervalSince(last) < cacheTTL {
            snapshot = snap
            return
        }
        lastNetworkKey = key
        isLoading = true
        guard let url = URL(string: "https://ipapi.co/json/") else { isLoading = false; return }
        PinnedSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let lat = json["latitude"] as? Double,
                  let lon = json["longitude"] as? Double else {
                DispatchQueue.main.async { self?.isLoading = false }
                return
            }
            let city = (json["city"] as? String) ?? "Your location"
            self.fetchOpenMeteo(lat: lat, lon: lon, city: city, networkKey: key)
        }.resume()
    }

    private func fetchOpenMeteo(lat: Double, lon: Double, city: String, networkKey: String) {
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\\(lat)&longitude=\\(lon)&current=temperature_2m,weather_code&timezone=auto"
        guard let url = URL(string: urlStr) else { DispatchQueue.main.async { self.isLoading = false }; return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self else { return }
            var snap: Snapshot?
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let current = json["current"] as? [String: Any],
               let temp = current["temperature_2m"] as? Double {
                let code = current["weather_code"] as? Int ?? 0
                snap = Snapshot(city: city, tempC: temp, condition: Self.conditionLabel(code))
            }
            DispatchQueue.main.async {
                self.isLoading = false
                if let snap {
                    self.snapshot = snap
                    self.lastFetch = Date()
                    self.storeSnapshot(snap, for: networkKey)
                }
            }
        }.resume()
    }

    private static func conditionLabel(_ code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1, 2, 3: return "Partly cloudy"
        case 45, 48: return "Fog"
        case 51...67: return "Rain"
        case 71...77: return "Snow"
        case 80...82: return "Showers"
        case 95...99: return "Storm"
        default: return "Weather"
        }
    }

    private func cacheKey(_ networkKey: String) -> String { "rnitro.weather.\\(networkKey)" }

    private func cachedSnapshot(for key: String) -> Snapshot? {
        guard let d = UserDefaults.standard.dictionary(forKey: cacheKey(key)),
              let city = d["city"] as? String,
              let temp = d["temp"] as? Double,
              let cond = d["cond"] as? String else { return nil }
        return Snapshot(city: city, tempC: temp, condition: cond)
    }

    private func storeSnapshot(_ snap: Snapshot, for key: String) {
        UserDefaults.standard.set(["city": snap.city, "temp": snap.tempC, "cond": snap.condition], forKey: cacheKey(key))
    }
}

'''

APP_CLEANER = '''
struct AppLeftover: Identifiable, Hashable {
    let id: String
    let path: String
    let label: String
    let bytes: Int64
}

struct InstalledApp: Identifiable {
    let id: String
    let name: String
    let path: String
    let bundleId: String
    let icon: NSImage?
    let appBytes: Int64
    let lastUsed: Date?
    var leftovers: [AppLeftover] = []

    var totalLeftoverBytes: Int64 { leftovers.reduce(0) { $0 + $1.bytes } }
}

enum AppCleanerSort: String, CaseIterable, Identifiable {
    case lastUsed = "Last used"
    case name = "Name"
    case size = "Size"
    var id: String { rawValue }
}

class AppCleanerModel: ObservableObject {
    @Published var apps: [InstalledApp] = []
    @Published var isScanning = false
    @Published var search = ""
    @Published var sort: AppCleanerSort = .lastUsed

    func scan() {
        isScanning = true
        DispatchQueue.global(qos: .utility).async {
            let dirs = ["/Applications", NSHomeDirectory() + "/Applications"]
            var found: [InstalledApp] = []
            let fm = FileManager.default
            for dir in dirs {
                guard let items = try? fm.contentsOfDirectory(atPath: dir) else { continue }
                for item in items where item.hasSuffix(".app") {
                    let path = (dir as NSString).appendingPathComponent(item)
                    if path.hasPrefix("/System") { continue }
                    guard let bundle = Bundle(path: path),
                          let bid = bundle.bundleIdentifier else { continue }
                    let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? item.replacingOccurrences(of: ".app", with: "")
                    let icon = NSWorkspace.shared.icon(forFile: path)
                    let appBytes = Self.folderBytes(path)
                    let lastUsed = Self.lastUsedDate(path: path)
                    var app = InstalledApp(id: path, name: name, path: path, bundleId: bid, icon: icon, appBytes: appBytes, lastUsed: lastUsed)
                    app.leftovers = Self.findLeftovers(bundleId: bid, appName: name)
                    found.append(app)
                }
            }
            DispatchQueue.main.async {
                self.apps = found
                self.isScanning = false
            }
        }
    }

    var filteredApps: [InstalledApp] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var list = apps
        if !q.isEmpty { list = list.filter { $0.name.lowercased().contains(q) || $0.bundleId.lowercased().contains(q) } }
        switch sort {
        case .lastUsed:
            list.sort { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
        case .name:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .size:
            list.sort { ($0.appBytes + $0.totalLeftoverBytes) > ($1.appBytes + $1.totalLeftoverBytes) }
        }
        return list
    }

    static func folderBytes(_ path: String) -> Int64 {
        let fm = FileManager.default
        guard let e = fm.enumerator(atPath: path) else { return 0 }
        var total: Int64 = 0
        for case let f as String in e {
            let p = (path as NSString).appendingPathComponent(f)
            if let attrs = try? fm.attributesOfItem(atPath: p), let sz = attrs[.size] as? Int64 { total += sz }
        }
        return total
    }

    static func lastUsedDate(path: String) -> Date? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/mdls")
        proc.arguments = ["-name", "kMDItemLastUsedDate", "-raw", path]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        try? proc.run()
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let raw = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty, raw != "(null)" else {
            return (try? FileManager.default.attributesOfItem(atPath: path))?[.modificationDate] as? Date
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return f.date(from: raw) ?? f.date(from: raw.replacingOccurrences(of: " +0000", with: " +0000"))
    }

    static func findLeftovers(bundleId: String, appName: String) -> [AppLeftover] {
        let home = NSHomeDirectory()
        let candidates: [(String, String)] = [
            ("\\(home)/Library/Caches/\\(bundleId)", "Caches"),
            ("\\(home)/Library/Preferences/\\(bundleId).plist", "Preferences"),
            ("\\(home)/Library/Application Support/\\(appName)", "Application Support"),
            ("\\(home)/Library/Containers/\\(bundleId)", "Container"),
        ]
        var out: [AppLeftover] = []
        let fm = FileManager.default
        for (path, label) in candidates where fm.fileExists(atPath: path) {
            out.append(AppLeftover(id: path, path: path, label: label, bytes: folderBytes(path)))
        }
        return out
    }

    func moveToTrash(_ paths: [String]) -> String? {
        let fm = FileManager.default
        for p in paths {
            let url = URL(fileURLWithPath: p)
            do { try fm.trashItem(at: url, resultingItemURL: nil) }
            catch { return "Could not move \\(p) to Trash" }
        }
        return nil
    }
}

struct AppCleanerView: View {
    @Environment(\\.uiMetrics) private var metrics
    @StateObject private var model = AppCleanerModel()
    @State private var selected: InstalledApp?
    @State private var selectedLeftovers: Set<String> = []
    @State private var alertMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("Search apps", text: $model.search)
                    .textFieldStyle(.roundedBorder)
                Picker("Sort", selection: $model.sort) {
                    ForEach(AppCleanerSort.allCases) { s in Text(s.rawValue).tag(s) }
                }
                .pickerStyle(.menu)
                .frame(width: 110)
            }
            if model.isScanning {
                Text("Scanning…").font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
            } else if model.filteredApps.isEmpty {
                Text("No apps found").font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(model.filteredApps) { app in
                            Button(action: { openDetail(app) }) {
                                HStack(spacing: 10) {
                                    if let icon = app.icon {
                                        Image(nsImage: icon).resizable().frame(width: 28, height: 28)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(app.name).font(rNitroFont(.label, metrics: metrics, weight: .medium))
                                        Text(relativeLastUsed(app.lastUsed))
                                            .font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(Self.formatBytes(app.appBytes))
                                        .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, metrics.hPad).padding(.vertical, 12)
        .onAppear { if model.apps.isEmpty { model.scan() } }
        .sheet(item: $selected) { app in cleanerDetail(app) }
        .alert("App Cleaner", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: { Text(alertMessage ?? "") }
    }

    private func openDetail(_ app: InstalledApp) {
        selected = app
        selectedLeftovers = Set(app.leftovers.map(\\.id))
    }

    private func cleanerDetail(_ app: InstalledApp) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(app.name).font(rNitroFont(.title, metrics: metrics, weight: .semibold))
            Text(app.path).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
            if app.leftovers.isEmpty {
                Text("No leftover files found").font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
            } else {
                Text("Leftover files").font(rNitroFont(.label, metrics: metrics, weight: .semibold))
                ForEach(app.leftovers) { item in
                    Toggle(isOn: Binding(
                        get: { selectedLeftovers.contains(item.id) },
                        set: { on in if on { selectedLeftovers.insert(item.id) } else { selectedLeftovers.remove(item.id) } }
                    )) {
                        HStack {
                            Text(item.label).font(rNitroFont(.caption, metrics: metrics))
                            Spacer()
                            Text(Self.formatBytes(item.bytes)).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                        }
                    }
                }
            }
            HStack {
                Button("Cancel") { selected = nil }
                Spacer()
                Button("Move App to Trash", role: .destructive) { performClean(app, includeApp: true) }
                Button("Remove Selected") { performClean(app, includeApp: false) }
            }
        }
        .padding(20)
        .frame(minWidth: 320)
    }

    private func performClean(_ app: InstalledApp, includeApp: Bool) {
        var paths: [String] = []
        if includeApp { paths.append(app.path) }
        paths += app.leftovers.filter { selectedLeftovers.contains($0.id) }.map(\\.path)
        if let err = model.moveToTrash(paths) { alertMessage = err }
        else {
            alertMessage = includeApp ? "Moved \\(app.name) to Trash" : "Removed selected files"
            selected = nil
            model.scan()
        }
    }

    private func relativeLastUsed(_ date: Date?) -> String {
        guard let date else { return "Last used: unknown" }
        let days = Int(Date().timeIntervalSince(date) / 86400)
        if days == 0 { return "Last used: today" }
        if days == 1 { return "Last used: yesterday" }
        if days < 30 { return "Last used: \\(days)d ago" }
        return "Last used: \\(days / 30)+ mo ago"
    }

    static func formatBytes(_ b: Int64) -> String {
        if b >= 1_073_741_824 { return String(format: "%.1f GB", Double(b) / 1_073_741_824) }
        if b >= 1_048_576 { return String(format: "%.1f MB", Double(b) / 1_048_576) }
        if b >= 1024 { return String(format: "%.0f KB", Double(b) / 1024) }
        return "\\(b) B"
    }
}

extension InstalledApp: Hashable {
    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

'''

MONITOR_PANEL = '''
enum MonitorPanel: String, CaseIterable, Identifiable {
    case cpu, gpu, memory, disk, network, battery, sensors, settings, cleaner
    var id: String { rawValue }

    var title: String {
        switch self {
        case .cpu: return "CPU"
        case .gpu: return "GPU"
        case .memory: return "Memory"
        case .disk: return "Disk"
        case .network: return "Network"
        case .battery: return "Battery & Power"
        case .sensors: return "Sensors"
        case .settings: return "Settings"
        case .cleaner: return "Cleaner"
        }
    }

    var icon: String {
        switch self {
        case .cpu: return "cpu"
        case .gpu: return "display"
        case .memory: return "memorychip"
        case .disk: return "internaldrive"
        case .network: return "wifi"
        case .battery: return "battery.100"
        case .sensors: return "thermometer.medium"
        case .settings: return "gearshape"
        case .cleaner: return "trash"
        }
    }

    var storageKey: String {
        switch self {
        case .settings: return "rnitro.sectionExpanded.settings"
        default: return "rnitro.sectionExpanded.\\(rawValue)"
        }
    }

    static func visiblePanels() -> [MonitorPanel] {
        let order = UserDefaults.standard.stringArray(forKey: "rnitro.panelOrder") ?? allCases.map(\\.rawValue)
        return order.compactMap { raw in
            guard let p = MonitorPanel(rawValue: raw) else { return nil }
            let key = "rnitro.panelVisible.\\(p.rawValue)"
            if UserDefaults.standard.object(forKey: key) == nil { return p }
            return UserDefaults.standard.bool(forKey: key) ? p : nil
        }
    }
}

struct MonitorSidebar: View {
    @Environment(\\.uiMetrics) private var metrics
    @Binding var selected: MonitorPanel
    let compact: Bool

    var body: some View {
        VStack(spacing: 4) {
            ForEach(MonitorPanel.visiblePanels()) { panel in
                Button(action: { selected = panel }) {
                    HStack(spacing: 8) {
                        Image(systemName: panel.icon)
                            .frame(width: 16)
                        if !compact { Text(panel.title).font(rNitroFont(.caption, metrics: metrics)) }
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(selected == panel ? .accent : .secondary)
                    .padding(.horizontal, compact ? 6 : 10)
                    .padding(.vertical, 6)
                    .background(selected == panel ? Color.accent.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .frame(width: compact ? 44 : 128)
    }
}

'''


def patch(text: str) -> str:
    if "RNITRO_BUILD_CHANNEL" in text:
        print("Already patched")
        return text

    text = text.replace(
        'let CURRENT_VERSION = "v8.2.8-Beta-arm64"',
        'let CURRENT_VERSION = "v8.2.9-Beta-arm64"\n' + BUILD_FLAGS.strip(),
    )
    text = text.replace("# v8.2.8-Beta-arm64 —", "# v8.2.9-Beta-arm64 —")

    text = text.replace(
        "struct MonitorSection<Content: View>: View {",
        SECTION_STORE.strip() + "\n\nstruct MonitorSection<Content: View>: View {",
    )

    # MonitorSection solo mode
    text = text.replace(
        "Button(action: { withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() } }) {",
        """Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if UserDefaults.standard.bool(forKey: "rnitro.soloMode") {
                        SectionExpansionStore.toggle(key: storageKey, soloMode: true)
                    } else {
                        isExpanded.toggle()
                    }
                }
            }) {""",
    )

    text = text.replace(
        "class SensorsMonitor: ObservableObject {",
        HARDWARE_MAPPER.strip() + "\n\nclass SensorsMonitor: ObservableObject {",
    )

    # SensorsMonitor Entry + refresh
    text = text.replace(
        """    struct Entry: Identifiable {
        let id: String
        let name: String
        let value: String
        let unit: String
    }""",
        """    struct Entry: Identifiable {
        let id: String
        let rawKey: String
        let name: String
        let detail: String?
        let value: String
        let unit: String
        let group: String
    }""",
    )

    text = text.replace(
        """            for t in SMCReader.shared.temperatureEntries().prefix(12) {
                rows.append(Entry(id: "t-\\(t.key)", name: t.key, value: String(format: "%.0f", t.value), unit: t.unit))
            }
            for f in SMCReader.shared.fanRPMReadings() {
                rows.append(Entry(id: "f-\\(f.key)", name: "Fan \\(f.key)", value: "\\(f.rpm)", unit: "RPM"))
            }""",
        """            for t in SMCReader.shared.temperatureEntries().prefix(14) {
                let mapped = HardwareLabelMapper.smcTemperature(t.key)
                rows.append(Entry(id: "t-\\(t.key)", rawKey: t.key, name: mapped.name, detail: mapped.detail,
                                  value: String(format: "%.0f", t.value), unit: t.unit, group: "Temperatures"))
            }
            for f in SMCReader.shared.fanRPMReadings() {
                rows.append(Entry(id: "f-\\(f.key)", rawKey: f.key, name: HardwareLabelMapper.fan(f.key), detail: nil,
                                  value: "\\(f.rpm)", unit: "RPM", group: "Fans"))
            }""",
    )

    text = text.replace(
        "extension Color {",
        WEATHER_SERVICE.strip() + "\n\nextension Color {",
        1,
    )

    text = text.replace(
        "enum MonitorPreferences {",
        """enum MonitorPreferences {
    static let soloModeKey = "rnitro.soloMode"
    static let classicScrollKey = "rnitro.classicScrollMode"
    static let showWeatherKey = "rnitro.showWeather"
""",
    )

    # UIMetrics
    text = text.replace(
        """    static func forWidth(_ w: CGFloat, layout: ContentLayout) -> UIMetrics {
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
    }""",
        """    static func forWidth(_ w: CGFloat, layout: ContentLayout) -> UIMetrics {
        let compact = layout == .popover || w < 420
        let scale: CGFloat
        let base: CGFloat
        if layout == .popover || compact {
            base = 13
            scale = 1.0
        } else {
            scale = min(max(w / 520.0, 0.85), 1.35)
            base = 17 * scale
        }
        return UIMetrics(
            base: base,
            compact: compact,
            hPad: (compact ? 10 : 16) * (RNITRO_FEATURE_BETA_UI ? scale : 1),
            statCellMin: (compact ? 72 : 88) * (RNITRO_FEATURE_BETA_UI ? min(scale, 1.15) : 1),
            graphHeight: (compact ? 28 : 36) * (RNITRO_FEATURE_BETA_UI ? min(scale, 1.2) : 1),
            bubbleSpacer: compact ? 20 : 40
        )
    }""",
    )

    # CoreRow
    text = text.replace(
        "struct CoreRow: View {\n    @Environment(\\.uiMetrics) private var metrics\n    let core: CoreInfo; let index: Int\n    var isEfficiency: Bool = false",
        "struct CoreRow: View {\n    @Environment(\\.uiMetrics) private var metrics\n    let core: CoreInfo; let index: Int\n    var isEfficiency: Bool = false\n    var clusterIndex: Int = 0",
    )
    text = text.replace(
        'Text(isEfficiency ? "E\\(index)" : "P\\(index)")',
        'Text(HardwareLabelMapper.coreLabel(index: index, isEfficiency: isEfficiency, clusterIndex: clusterIndex))',
    )

    # AppTab
    text = text.replace(
        """enum AppTab: String, CaseIterable, Identifiable {
    case monitor = "Monitor"
    case advisor = "Advisor"
    case chat = "Chat"
    var id: String { rawValue }
    static let popoverTabs: [AppTab] = [.monitor, .advisor, .chat]
    static let windowTabs: [AppTab] = [.monitor, .advisor, .chat]
}""",
        """enum AppTab: String, CaseIterable, Identifiable {
    case monitor = "Monitor"
    case advisor = "Advisor"
    case chat = "Chat"
    case cleaner = "Cleaner"
    var id: String { rawValue }
    static let popoverTabs: [AppTab] = RNITRO_FEATURE_BETA_UI
        ? [.monitor, .advisor, .chat, .cleaner]
        : [.monitor, .advisor, .chat, .cleaner]
    static let windowTabs: [AppTab] = popoverTabs
}""",
    )

    text = text.replace(
        "struct ContentView: View {",
        APP_CLEANER.strip() + "\n" + MONITOR_PANEL.strip() + "\n\nstruct ContentView: View {",
    )

    # ContentView state vars
    text = text.replace(
        "@State private var showFirstLaunchTips = FirstLaunchTips.shouldShow",
        """@State private var showFirstLaunchTips = FirstLaunchTips.shouldShow
    @AppStorage(MonitorPreferences.soloModeKey) private var soloMode = false
    @AppStorage(MonitorPreferences.classicScrollKey) private var classicScrollMode = false
    @AppStorage(MonitorPreferences.showWeatherKey) private var showWeather = true
    @State private var selectedPanel: MonitorPanel = .cpu
    @ObservedObject private var weather = WeatherService.shared""",
    )

    # Switch tab for cleaner
    text = text.replace(
        """                    switch tab {
                    case .chat:
                        AIChatView(compact: layout == .popover)
                    case .advisor:
                        SystemAdvisorView(compact: layout == .popover)
                    case .monitor:
                        if uiStyleRaw == MonitorUIStyle.legacy.rawValue {
                            legacyMonitorTab
                        } else {
                            modernMonitorTab
                        }
                    }""",
        """                    switch tab {
                    case .chat:
                        AIChatView(compact: layout == .popover)
                    case .advisor:
                        SystemAdvisorView(compact: layout == .popover)
                    case .cleaner:
                        AppCleanerView()
                    case .monitor:
                        if uiStyleRaw == MonitorUIStyle.legacy.rawValue {
                            legacyMonitorTab
                        } else if RNITRO_FEATURE_BETA_UI && !classicScrollMode {
                            betaSidebarMonitorTab
                        } else {
                            modernMonitorTab
                        }
                    }""",
    )

    # Extras -> Settings
    text = text.replace('title: "Extras"', 'title: "Settings"')
    text = text.replace('storageKey: "rnitro.sectionExpanded.extras"', 'storageKey: "rnitro.sectionExpanded.settings"')

    # Sensors UI
    text = text.replace(
        """                    if sensors.entries.isEmpty {
                        MonitorRow(label: "Status", value: "No SMC/fan sensors resolved")
                    } else {
                        ForEach(sensors.entries) { entry in
                            MonitorRow(label: entry.name, value: "\\(entry.value) \\(entry.unit)")
                        }
                    }""",
        """                    if sensors.entries.isEmpty {
                        MonitorRow(label: "Status", value: "No temperature or fan sensors found")
                        MonitorRow(label: "Tip", value: "SMC keys vary by chip — CPU temp still shown above")
                    } else {
                        let groups = Dictionary(grouping: sensors.entries, by: { $0.group })
                        ForEach(["Temperatures", "Fans"], id: \\.self) { group in
                            if let items = groups[group] {
                                Text(group).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                                ForEach(items) { entry in
                                    VStack(alignment: .leading, spacing: 0) {
                                        MonitorRow(label: entry.name, value: "\\(entry.value) \\(entry.unit)")
                                        Text(entry.rawKey).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary.opacity(0.6))
                                    }
                                }
                            }
                        }
                    }""",
    )

    # Core rows in modernMonitorTab - fix cluster index
    text = text.replace(
        """                    VStack(spacing: 4) {
                        ForEach(Array(m.cores.enumerated()), id: \\.offset) { i, core in
                            CoreRow(core: core, index: i, isEfficiency: i < m.efficiencyCoreCount)
                        }
                    }""",
        """                    VStack(spacing: 4) {
                        ForEach(Array(m.cores.enumerated()), id: \\.offset) { i, core in
                            let eff = i < m.efficiencyCoreCount
                            let cIdx = eff ? i : i - m.efficiencyCoreCount
                            CoreRow(core: core, index: i, isEfficiency: eff, clusterIndex: cIdx)
                        }
                    }""",
    )

    # Network row interface label - read NetworkMonitorRow
    text = text.replace(
        'Text("Network").font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)',
        'Text(HardwareLabelMapper.networkInterface(net.interfaceName)).font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)',
        1,
    )

    # Settings section - add solo mode + weather toggles + panel visibility
    text = text.replace(
        "                    uiStylePicker\n                    menuBarSettings",
        """                    if RNITRO_FEATURE_BETA_UI {
                        Toggle(isOn: $soloMode) { Text("Solo Mode (one panel open)").font(rNitroFont(.label, metrics: metrics)) }
                            .toggleStyle(.switch)
                        Toggle(isOn: $classicScrollMode) { Text("Classic scroll (all sections)").font(rNitroFont(.label, metrics: metrics)) }
                            .toggleStyle(.switch)
                        Toggle(isOn: $showWeather) { Text("Show weather on Network").font(rNitroFont(.label, metrics: metrics)) }
                            .toggleStyle(.switch)
                        panelVisibilityToggles
                    }
                    uiStylePicker
                    menuBarSettings""",
    )

    # Add betaSidebarMonitorTab + panelVisibilityToggles + weather row before legacyMonitorTab
    beta_sidebar = '''
    @ViewBuilder
    private var panelVisibilityToggles: some View {
        Text("Visible panels").font(rNitroFont(.label, metrics: metrics, weight: .semibold))
        ForEach(MonitorPanel.allCases.filter { $0 != .cleaner }) { panel in
            Toggle(isOn: Binding(
                get: { UserDefaults.standard.object(forKey: "rnitro.panelVisible.\\(panel.rawValue)") == nil ? true : UserDefaults.standard.bool(forKey: "rnitro.panelVisible.\\(panel.rawValue)") },
                set: { UserDefaults.standard.set($0, forKey: "rnitro.panelVisible.\\(panel.rawValue)") }
            )) {
                Text(panel.title).font(rNitroFont(.caption, metrics: metrics))
            }
            .toggleStyle(.switch)
        }
    }

    private var betaSidebarMonitorTab: some View {
        HStack(spacing: 0) {
            MonitorSidebar(selected: $selectedPanel, compact: layout == .popover)
            ScrollView {
                VStack(spacing: 0) {
                    panelContent(selectedPanel)
                }
            }
        }
        .onAppear {
            SectionExpansionStore.migrateExtrasKey()
            let key = net.wifiSSID.isEmpty ? "wired-\\(net.interfaceName)" : net.wifiSSID
            weather.refresh(forNetworkKey: key, enabled: showWeather)
        }
        .onChange(of: net.wifiSSID) { _ in
            let key = net.wifiSSID.isEmpty ? "wired-\\(net.interfaceName)" : net.wifiSSID
            weather.refresh(forNetworkKey: key, enabled: showWeather)
        }
        .onChange(of: showWeather) { on in
            let key = net.wifiSSID.isEmpty ? "wired-\\(net.interfaceName)" : net.wifiSSID
            weather.refresh(forNetworkKey: key, enabled: on)
        }
    }

    @ViewBuilder
    private func panelContent(_ panel: MonitorPanel) -> some View {
        switch panel {
        case .cpu: cpuSection
        case .gpu: gpuSection
        case .memory: memorySection
        case .disk: diskSection
        case .network: networkSection
        case .battery: batterySection
        case .sensors: sensorsSection
        case .settings: settingsSection
        case .cleaner: AppCleanerView()
        }
    }

'''

    # Extract sections from modernMonitorTab into computed properties - simpler approach: 
    # Insert betaSidebarMonitorTab and refactor modernMonitorTab to use section builders

    # For network weather row - add after wifiSSID MonitorRow in modernMonitorTab
    weather_row = '''
                        if showWeather, let w = weather.snapshot {
                            MonitorRow(label: "Weather", value: String(format: "%.0f°C %@", w.tempC, w.condition))
                            MonitorRow(label: "Location", value: w.city)
                        } else if showWeather && weather.isLoading {
                            MonitorRow(label: "Weather", value: "Loading…")
                        }
'''

    text = text.replace(
        """                        if !net.wifiSSID.isEmpty {
                            MonitorRow(label: "Wi-Fi", value: net.wifiSSID)
                        }""",
        """                        if !net.wifiSSID.isEmpty {
                            MonitorRow(label: "Wi-Fi", value: net.wifiSSID)
                        }
""" + weather_row,
    )

    text = text.replace(
        "    private var legacyMonitorTab: some View {",
        beta_sidebar + "\n    private var legacyMonitorTab: some View {",
    )

    # Section computed properties - insert before modernMonitorTab
    sections = '''
    private var cpuSection: some View {
        MonitorSection(title: "CPU", accent: .accent, summary: String(format: "%.0f%%", m.totalUsage), sparkline: m.usageHistory, storageKey: "rnitro.sectionExpanded.cpu") {
            GraphView(history: m.usageHistory, color: Color.usage(m.totalUsage)).frame(height: metrics.graphHeight)
            MonitorRow(label: "Usage", value: String(format: "%.1f%%", m.totalUsage), valueColor: Color.usage(m.totalUsage))
            MonitorRow(label: "Load avg", value: String(format: "%.2f · %.2f · %.2f", m.loadAverage1, m.loadAverage5, m.loadAverage15))
            MonitorRow(label: "Clock", value: String(format: "%.0f / %.0f MHz", m.baseClock, m.boostClock))
            VStack(spacing: 4) {
                ForEach(Array(m.cores.enumerated()), id: \\.offset) { i, core in
                    let eff = i < m.efficiencyCoreCount
                    CoreRow(core: core, index: i, isEfficiency: eff, clusterIndex: eff ? i : i - m.efficiencyCoreCount)
                }
            }
        }
    }

    private var gpuSection: some View {
        MonitorSection(title: "GPU", accent: .nGreen, summary: String(format: "%.0f%%", gpu.usage), sparkline: gpu.usageHistory, storageKey: "rnitro.sectionExpanded.gpu") {
            GraphView(history: gpu.usageHistory, color: Color.usage(gpu.usage)).frame(height: metrics.graphHeight)
            MonitorRow(label: "Usage", value: String(format: "%.1f%%", gpu.usage), valueColor: Color.usage(gpu.usage))
            MonitorRow(label: "Power", value: String(format: "%.1f W", m.gpuPowerWatts))
        }
    }

    private var memorySection: some View {
        MonitorSection(title: "Memory", accent: .nPurple, summary: String(format: "%.0f%%", m.memoryUsedPercent), sparkline: m.memoryHistory, storageKey: "rnitro.sectionExpanded.memory") {
            UsageBarRow(label: "RAM", usedGB: m.memoryUsedGB, freeGB: m.memoryFreeGB, totalGB: m.memoryTotalGB, usedPercent: m.memoryUsedPercent, action: { toggleStatDetail(.memory) })
            MonitorRow(label: "Pressure", value: m.memoryPressure, valueColor: Color.pressure(m.memoryPressure))
            MonitorRow(label: "Wired", value: String(format: "%.1f GB", m.memoryWiredGB))
            MonitorRow(label: "Compressed", value: String(format: "%.1f GB", m.memoryCompressedGB))
            MonitorRow(label: "Swap used", value: String(format: "%.1f GB", m.memorySwapGB))
        }
    }

    private var diskSection: some View {
        MonitorSection(title: "Disk", accent: .nOrange, summary: String(format: "%.0f%%", m.diskUsedPercent), sparkline: disk.activityHistory, sparkMax: max(disk.activityHistory.max() ?? 1, 10), storageKey: "rnitro.sectionExpanded.disk") {
            UsageBarRow(label: "SSD · \\(m.diskVolumeName)", usedGB: m.diskUsedGB, freeGB: m.diskFreeGB, totalGB: m.diskTotalGB, usedPercent: m.diskUsedPercent, action: { toggleStatDetail(.storage) })
            MiniGraphView(history: disk.activityHistory, color: .nOrange, maxValue: max(disk.activityHistory.max() ?? 1, 10)).frame(height: 28)
            MonitorRow(label: "Read", value: String(format: "%.1f MB/s", disk.readMBps))
            MonitorRow(label: "Write", value: String(format: "%.1f MB/s", disk.writeMBps))
        }
    }

    @ViewBuilder
    private var networkSection: some View {
        if showNetworkUI {
            MonitorSection(title: "Network", accent: .nBlue, summary: net.isAvailable ? NetworkMonitor.formatSpeed(net.downloadMbps) : "—", sparkline: net.downloadHistory, sparkMax: max(net.downloadHistory.max() ?? 1, 100), storageKey: "rnitro.sectionExpanded.network") {
                NetworkMonitorRow(net: net)
                MonitorRow(label: "Interface", value: HardwareLabelMapper.networkInterface(net.interfaceName))
                MonitorRow(label: "IP", value: net.localIP)
                if !net.wifiSSID.isEmpty { MonitorRow(label: "Wi-Fi", value: net.wifiSSID) }
                if showWeather, let w = weather.snapshot {
                    MonitorRow(label: "Weather", value: String(format: "%.0f°C %@", w.tempC, w.condition))
                    MonitorRow(label: "Location", value: w.city)
                } else if showWeather && weather.isLoading {
                    MonitorRow(label: "Weather", value: "Loading…")
                }
            }
        } else {
            Text("Network hidden in Settings").font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary).padding()
        }
    }

    private var batterySection: some View {
        MonitorSection(title: "Battery & Power", accent: .nGreen, summary: bat.isPresent ? "\\(bat.levelPercent)%" : String(format: "%.1fW", m.packagePowerWatts), sparkline: m.powerHistory, sparkMax: max(m.powerHistory.max() ?? 1, CPUMonitor.chipPowerCeiling(m.cpuName)), storageKey: "rnitro.sectionExpanded.battery") {
            BatteryCpuPowerRow(bat: bat, monitor: m, onBatteryTap: bat.isPresent ? { toggleStatDetail(.battery) } : nil, onCpuPowerTap: { toggleStatDetail(.cpuPower) })
            if m.isLowPowerModeEnabled { MonitorRow(label: "Low Power Mode", value: "On", valueColor: Color(red: 0.55, green: 0.88, blue: 0.42)) }
            PowerGraphView(history: m.powerHistory, color: Color.usage(m.totalUsage), maxWatts: max(CPUMonitor.chipPowerCeiling(m.cpuName) * 1.2, m.powerHistory.max() ?? 0, 8)).frame(height: metrics.graphHeight)
        }
    }

    @ViewBuilder
    private var sensorsSection: some View {
        MonitorSection(title: "Sensors", accent: .nOrange, summary: sensors.entries.isEmpty ? "—" : "\\(sensors.entries.count) readings", storageKey: "rnitro.sectionExpanded.sensors") {
            if sensors.entries.isEmpty {
                MonitorRow(label: "Status", value: "No temperature or fan sensors found")
            } else {
                let groups = Dictionary(grouping: sensors.entries, by: { $0.group })
                ForEach(["Temperatures", "Fans"], id: \\.self) { group in
                    if let items = groups[group] {
                        Text(group).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                        ForEach(items) { entry in
                            VStack(alignment: .leading, spacing: 0) {
                                MonitorRow(label: entry.name, value: "\\(entry.value) \\(entry.unit)")
                                Text(entry.rawKey).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary.opacity(0.6))
                            }
                        }
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        MonitorSection(title: "Settings", accent: .secondary, summary: "Tools", storageKey: "rnitro.sectionExpanded.settings") {
            if let price = btc.priceUSD { MonitorRow(label: "Bitcoin", value: String(format: "$%.0f", price)) }
            if RNITRO_FEATURE_BETA_UI {
                Toggle(isOn: $soloMode) { Text("Solo Mode").font(rNitroFont(.label, metrics: metrics)) }.toggleStyle(.switch)
                Toggle(isOn: $classicScrollMode) { Text("Classic scroll").font(rNitroFont(.label, metrics: metrics)) }.toggleStyle(.switch)
                Toggle(isOn: $showWeather) { Text("Weather").font(rNitroFont(.label, metrics: metrics)) }.toggleStyle(.switch)
                panelVisibilityToggles
            }
            uiStylePicker
            menuBarSettings
            HStack {
                Text("Stress Test").font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                Spacer()
                MinimalButton(title: stress.isRunning ? "Stop" : "Start", tint: stress.isRunning ? .nRed : .nOrange, disabled: bench.isRunning, action: { stress.isRunning ? stress.stop() : stress.start() })
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Benchmark").font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                    Text("1-core \\(bench.singleCoreScore.map { String(format: "%.0f", $0) } ?? "—") · multi \\(bench.multiCoreScore.map { String(format: "%.0f", $0) } ?? "—")")
                        .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                }
                Spacer()
                MinimalButton(title: bench.isRunning ? "Running…" : "Run", disabled: bench.isRunning || stress.isRunning, action: { bench.run() })
            }
            sharedToolToggles
        }
    }

'''

    text = text.replace("    private var modernMonitorTab: some View {", sections + "\n    private var modernMonitorTab: some View {")

    # Plist version bumps
    text = text.replace("<key>CFBundleVersion</key><string>8.2.1-Beta-arm64</string>",
                        "<key>CFBundleVersion</key><string>8.2.9-Beta-arm64</string>")
    text = text.replace("<key>CFBundleShortVersionString</key><string>8.2.8-Beta-arm64</string>",
                        "<key>CFBundleShortVersionString</key><string>8.2.9-Beta-arm64</string>")

    return text


def main() -> None:
    text = SRC.read_text(encoding="utf-8")
    SRC.write_text(patch(text), encoding="utf-8")
    print(f"Patched {SRC}")


if __name__ == "__main__":
    main()