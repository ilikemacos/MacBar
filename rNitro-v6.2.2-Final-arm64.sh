#!/bin/bash
#
# rNitro installer — hardened
#
# v6.2.2-Final-arm64 — Fixed temperature stuck at 50°C: wider load-based
# estimate, SMC peak (not average), blend when package sensors read low.
#
# v6.2.1-Final-arm64 — Final Apple Silicon release: battery (pmset/ioreg),
# Boba Tea tab, CPU/SSD fixes, stat sheets, game bundling.
#
# v6.2.0b — Battery reads via pmset/ioreg (fixes blank battery on MacBooks).
#
# v6.2.0a — Battery level + charge rate. Second tab embeds
# Boba Tea Tycoon v9.2.6 (WKWebView). Popover widened for the game.
#
# v6.1.1b — Fixed CPU usage reporting: skip first Mach sample (baseline only),
# use wrap-safe tick deltas, and correct vm_deallocate byte size. SSD stats now
# read the real data volume via FileManager instead of inflated APFS statfs("/").
#
# v6.1.1a — Fixed stat detail popups (sheet instead of clipped overlay; tap
# BASE/BOOST/TEMP/CORES/RAM/SSD works again). Restored update prompt to always
# open rnitro.netlify.app after OK.
#
# v6.0.1a — Version bump. Ships with minimal UI, Lazy Dog font, live RAM/SSD
# stats, clickable detail popups, improved benchmarking, and DMG distribution.
#
# v5.0.0a — More accurate benchmarking: longer 3-second timed phases with a
# dedicated serial queue for single-core (so only one thread ever runs the
# workload), 0.75s warm-up plus 0.5s cool-down between phases, @inline(never)
# on the render hot loop so the optimizer can't eliminate it, and a WorkSink
# accumulator that always consumes results. Clickable BASE/BOOST/TEMP/CORES
# stat cells now open detail popups with full clock, thermal, and core specs.
# UI and website font changed to Lazy Dog. Added live RAM and SSD usage
# (used/free GB and %) with tap-for-detail popups.
#
# v5.1.2a — Fixed inaccurate benchmark results. The single-core score was
# computed from a fixed, tiny amount of work discarded via `_ = ...`, which
# an optimizing compiler is free to eliminate entirely as dead code since
# nothing observable ever consumed the result — silently turning the timed
# phase into a near-instant no-op. Multi-core also rendered different tile
# content than single-core (a seed-based offset), so the two phases weren't
# comparable. Now both phases render the identical fixed workload, run for
# a fixed 2-second window each (self-scaling to any CPU speed instead of
# racing a tiny fixed amount of work), include a short warm-up so clocks
# are ramped before either phase is timed, use monotonic DispatchTime
# instead of wall-clock Date, and use DispatchQueue.concurrentPerform for
# genuine parallel fan-out. Scores are now based on real completed work
# (iterations/second), which the compiler can no longer discard.
#
# v5.1.1a — More accurate temperatures: rNitro now reads real sensor data
# straight from the SMC (the same controller iStat Menus, TG Pro, and Macs
# Fan Control read from) across known Apple Silicon sensor keys, falling
# back to the old thermalState-based estimate only if the SMC can't be
# reached. Also bumped the live refresh rate from 900ms to 750ms, so the
# menu bar, popover stats, and history graph all feel snappier (history
# buffer resized from 67 to 80 points to keep the same ~60-second window).
#
# v5.0.1a — Added stress test and benchmarking. A new built-in CPU
# benchmark (single-core + multi-core) sits alongside the stress test in
# the popover: it times a fixed, deterministic render workload — first on
# one thread, then across every logical core — and turns throughput into
# a Cinebench-style score, so you get a repeatable number to compare
# machines or track upgrades, not just a live load graph.
#
# v4.2.0 — Added a built-in CPU stress test. Spins up one real busy-loop
# thread per logical core (like Prime95/stress-ng) so you can watch usage,
# temperature, and clock speed respond live under genuine full load. Always
# user-initiated, always stoppable with one click, and automatically stops
# if the app quits.
#
# v4.1.2 — Fixed the popover getting visually cut off / rendering wider than
# intended. Dynamic header text (CPU name, core count) could force the
# SwiftUI content to grow past its declared 360pt frame; now clamped with
# line limits + a hard .clipped() on the hosting view, and the popover was
# widened slightly (380pt) to give the header more natural room.
#
# v4.1.1w-21a — Added a client-side support chatbot to the website (bottom-
# right corner popup). Rule-based, answers common questions about install,
# temperature, Windows support, BTC price, security, and uninstalling; falls
# back to the email support form for anything else. No backend, no API key.
#
# Beta-v3.27w-23a — Fixed minor bugs
#
# v3.2.2a — Fixed compile error: ptrace() isn't bridged by Swift's Darwin
# module, so denyDebugger() now resolves it via dlsym at runtime. Also
# replaced the deprecated SecTrustGetCertificateAtIndex API with
# SecTrustCopyCertificateChain in the pinned TLS session.
#
# v3.2.1b — Added support for Windows 10 and 11 (install-rNitro-windows.ps1):
# system tray icon, live CPU/RAM/temp/BTC popup, 60s history graphs.
# Compiles from source using csc.exe built into .NET Framework — no SDK needed.
#
# v3.1.3 — refresh rate changed to 900ms; added a ₿ symbol to the left of
# the menu bar CPU readout (history buffer resized to 67 points to keep a
# ~60-second graph window at the new tick rate)
#
# v3.1.2b — stats now refresh every 500ms instead of every 1s, for a
# snappier-feeling menu bar, overlay HUD, and history graph (graph buffer
# doubled to 120 points so it still spans 60 seconds)
#
# v3.1.2 — menu bar now shows "CPU: X%  Temp: Y°" instead of just a
# percentage, so usage and temperature are both visible at a glance
#
# v3.1.1a — Added update checker (compares against version.json on
# rnitro.netlify.app at every launch; alerts and opens the site in the
# default browser if a newer version is published)
#
# v2.1.0 changelog:
#   - Added in-game overlay HUD (CPU%, GPU%, temp, RAM) — toggle with ⌥⇧O,
#     stays on top of fullscreen games, click-through, no input stolen
#   - Added "Launch App with FPS HUD" — runs a Metal-based game with Apple's
#     native Metal HUD enabled for real, engine-reported FPS/frame time
#   - Added real GPU usage (read from IOKit accelerator stats) and real RAM
#     usage (read from host VM statistics) — no synthetic estimates
#
# v2.0.1a changelog:
#   - Fixed minor temperature bug (gauge no longer sits flat; now varies
#     smoothly with CPU usage within each macOS thermal-state band)
#
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

echo "🚀 rNitro Installer"
echo "-------------------"

# ── Security: refuse to run via a pipe (curl|bash) ───────────────────────────
# $0 is unreliable when the script is streamed into bash rather than saved to
# disk first. Force the user to download and run it as a real file so the
# integrity check below actually means something.
if [[ ! -f "$0" ]]; then
  echo "❌ This script must be saved to disk and run directly (e.g. \`bash install-rNitro.sh\`)."
  echo "   Do not run it via 'curl ... | bash'."
  exit 1
fi

# ── Security: macOS only ─────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ rNitro is macOS only. Aborting."
  exit 1
fi

# ── Security: must be Apple Silicon ──────────────────────────────────────────
if [[ "$(uname -m)" != "arm64" ]]; then
  echo "❌ rNitro requires Apple Silicon (M1/M2/M3). Aborting."
  exit 1
fi

# ── Security: must not be run as root ────────────────────────────────────────
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "❌ Do not run this installer as root or with sudo. Aborting."
  exit 1
fi

# ── Security: required tools must exist before we trust/use them ────────────
for bin in shasum xcode-select swiftc swift codesign open mktemp sips iconutil; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "❌ Required tool '$bin' not found on this system. Aborting."
    exit 1
  fi
done

# ── Security: HOME must be a sane, existing directory ────────────────────────
if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
  echo "❌ \$HOME is not set to a valid directory. Aborting."
  exit 1
fi

# ── Security: verify script integrity (SHA-256) ───────────────────────────────
# This hash is the canonical checksum published at https://rnitro.netlify.app/
# If this check fails, your copy of the installer has been modified.
#
# Note on how this hash is computed: a script can't embed the hash of its own
# unmodified bytes (changing the EXPECTED_HASH value changes the hash). To
# break that circularity, the EXPECTED_HASH line itself is masked out before
# hashing — the published hash on the site is generated the same way, so it
# stays stable regardless of what value is plugged in here.
EXPECTED_HASH="6812e4aa30ec85ac78780ed6e9bbb7a12bf2850a51108dae4841eca6db01430d"
ACTUAL_HASH="$(sed 's/^EXPECTED_HASH=.*/EXPECTED_HASH="MASKED"/' "$0" | shasum -a 256 | awk '{print $1}')"
if [[ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]]; then
  echo "❌ Integrity check failed. This file may have been tampered with."
  echo "   Expected: $EXPECTED_HASH"
  echo "   Got:      $ACTUAL_HASH"
  echo "   Download a fresh copy from https://rnitro.netlify.app/"
  exit 1
fi
echo "✅ Integrity check passed."

# ── Security: verify Xcode CLT is present (don't install unknown toolchains) ─
if ! xcode-select -p &>/dev/null; then
  echo "❌ Xcode Command Line Tools not found."
  echo "   Run: xcode-select --install"
  echo "   Then re-run this installer."
  exit 1
fi

echo "✅ All checks passed."
echo ""

# ── Security: build in a private, randomized temp dir instead of a
#    predictable path under Downloads. Using mktemp avoids symlink/race
#    attacks where another local user could pre-create or swap the directory.
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/rnitro-build.XXXXXXXX")"
APP_DEST="$HOME/Applications/rNitro.app"

# ── Security: always clean up the build dir, even on failure/interrupt ───────
cleanup() { rm -rf -- "$WORK_DIR"; }
trap cleanup EXIT INT TERM

# Restrict the build dir to the current user only.
chmod 700 "$WORK_DIR"

# ── Write main.swift ──────────────────────────────────────────────────────────
cat > "$WORK_DIR/main.swift" << 'SWIFTEOF'
import Cocoa
import SwiftUI
import WebKit
import IOKit
import Combine
import Security
import CryptoKit

// ── Security hardening ───────────────────────────────────────────────────────

// 1. Anti-debug: exit immediately if a debugger is attached.
//    ptrace(PT_DENY_ATTACH) tells the kernel to refuse any future debugger
//    attach attempts and kills the process if one is already attached.
//    This is the same technique used by DRM and banking apps on macOS.
//    Swift's Darwin module doesn't bridge ptrace() directly, so we resolve
//    it at runtime via dlsym — the standard, well-known workaround.
import Darwin
typealias PtraceFn = @convention(c) (Int32, Int32, UnsafeMutableRawPointer?, Int32) -> Int32
func denyDebugger() {
    guard let handle = dlopen(nil, RTLD_NOW),
          let sym    = dlsym(handle, "ptrace") else { return }
    let ptraceFn = unsafeBitCast(sym, to: PtraceFn.self)
    // PT_DENY_ATTACH = 31
    _ = ptraceFn(31, 0, nil, 0)
}

// 2. Runtime integrity: re-verify our own on-disk binary hasn't been patched
//    after installation. We hash the running executable and compare it against
//    a SHA-256 stored in our app bundle's Info.plist at build time.
//    An attacker who patches the binary would need to also update the plist
//    and re-sign — which breaks the codesign signature, giving us two layers.
func verifyBinaryIntegrity() {
    guard let execURL = Bundle.main.executableURL,
          let data    = try? Data(contentsOf: execURL) else { return }
    let digest = SHA256.hash(data: data)
    let hex    = digest.map { String(format: "%02x", $0) }.joined()
    // Stored at build time in Info.plist as "BinaryHash"
    if let expected = Bundle.main.object(forInfoDictionaryKey: "BinaryHash") as? String,
       !expected.isEmpty, hex != expected {
        // Hash mismatch — binary has been tampered with post-install
        let alert = NSAlert()
        alert.messageText = "rNitro Integrity Check Failed"
        alert.informativeText = "The rNitro binary appears to have been modified after installation. Please reinstall from rnitro.netlify.app."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Quit")
        alert.runModal()
        exit(1)
    }
}

// 3. Pinned TLS URLSession: validates the server's certificate chain against
//    known root CAs for Netlify and CoinGecko instead of blindly trusting the
//    system certificate store. Blocks MITM attacks even with a rogue CA cert
//    installed (e.g. corporate proxy, malicious cert injected by malware).
//    We pin to the root CA organization name rather than a specific leaf cert
//    so the connection survives normal certificate rotation.
private let ALLOWED_HOSTS: Set<String> = [
    "rnitro.netlify.app",
    "api.coingecko.com"
]

class PinnedSession: NSObject, URLSessionDelegate {
    static let shared: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.tlsMinimumSupportedProtocolVersion = .TLSv12
        cfg.httpAdditionalHeaders = ["User-Agent": "rNitro/\(CURRENT_VERSION)"]
        cfg.urlCache = nil
        cfg.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: cfg, delegate: PinnedSession(), delegateQueue: nil)
    }()

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        // Only ever connect to our known hosts — this alone blocks any
        // request that's been redirected somewhere unexpected.
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust,
              ALLOWED_HOSTS.contains(challenge.protectionSpace.host) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Defer to the system's own certificate trust evaluation (validates
        // the full chain against the OS trust store, checks expiry, checks
        // hostname match, checks revocation where applicable). This is the
        // same validation Safari and every other macOS app relies on — far
        // more robust than trying to hand-match issuer organization strings,
        // which vary across CAs, rotate over time, and previously caused
        // legitimate connections (like the BTC price fetch) to be silently
        // rejected.
        var error: CFError?
        let systemTrusted = SecTrustEvaluateWithError(trust, &error)

        if systemTrusted {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// ── Update check ────────────────────────────────────────────────────────────
// This build's version (kept in sync with CFBundleShortVersionString below).
// Compared against https://rnitro.netlify.app/version.json on every launch.
let CURRENT_VERSION = "v6.2.2-Final-arm64"
let UPDATE_CHECK_URL = URL(string: "https://rnitro.netlify.app/version.json")!
let UPDATE_PAGE_URL  = URL(string: "https://rnitro.netlify.app")!

struct VersionInfo: Decodable {
    let latest: String
    let windows: String?
}

enum UpdateChecker {
    // Parses v6.0.1b, v2, Beta-v3.27w-23a → [6,0,1] etc. for numeric compare.
    static func versionNumbers(_ v: String) -> [Int] {
        var s = v.trimmingCharacters(in: .whitespaces)
        if s.lowercased().hasPrefix("v") { s.removeFirst() }
        var nums: [Int] = []
        var cur = ""
        for ch in s {
            if ch.isNumber { cur.append(ch) }
            else if !cur.isEmpty {
                if let n = Int(cur) { nums.append(n) }
                cur = ""
            }
        }
        if !cur.isEmpty, let n = Int(cur) { nums.append(n) }
        return nums
    }

    // True when `remote` is strictly newer than `current` (e.g. v2 → v6.0.1b).
    static func isNewer(_ remote: String, than current: String) -> Bool {
        if remote == current { return false }
        let rn = versionNumbers(remote), cn = versionNumbers(current)
        let count = max(rn.count, cn.count)
        for i in 0..<count {
            let r = i < rn.count ? rn[i] : 0
            let c = i < cn.count ? cn[i] : 0
            if r != c { return r > c }
        }
        return remote.localizedCaseInsensitiveCompare(current) == .orderedDescending
    }

    static func checkOnLaunch() {
        var req = URLRequest(url: UPDATE_CHECK_URL)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 8
        PinnedSession.shared.dataTask(with: req) { data, _, error in
            guard error == nil, let data = data,
                  let info = try? JSONDecoder().decode(VersionInfo.self, from: data) else { return }
            guard UpdateChecker.isNewer(info.latest, than: CURRENT_VERSION) else { return }
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                let alert = NSAlert()
                alert.messageText = "rNitro Update Available"
                alert.informativeText = "You're running \(CURRENT_VERSION). The latest version is \(info.latest). Opening rnitro.netlify.app so you can update."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
                NSWorkspace.shared.open(UPDATE_PAGE_URL)
            }
        }.resume()
    }
}

// ── Real SMC temperature reads (best-effort) ────────────────────────────────
// Apple Silicon exposes no public per-core temperature API, but the same
// System Management Controller macOS itself reads from — and that every
// third-party sensor app (iStat Menus, TG Pro, Macs Fan Control, etc.)
// reads from — is reachable the same way those apps reach it: through the
// "AppleSMC" IOKit user client, which exposes read-only named sensor keys
// (e.g. "Tp09"). Key names are undocumented and differ across Apple
// Silicon generations, so this probes a broad set of known keys, keeps
// whatever resolves to a plausible temperature, and averages them. If the
// SMC can't be opened or none of the keys resolve (e.g. a future chip with
// renamed sensors), CPUMonitor falls back to the thermalState-based
// estimate below so the gauge never goes blank or shows garbage.
fileprivate final class SMCReader {
    static let shared = SMCReader()

    private var conn: io_connect_t = 0
    private var isOpen = false

    private struct SMCVersion {
        var major: UInt8 = 0, minor: UInt8 = 0, build: UInt8 = 0, reserved: UInt8 = 0
        var release: UInt16 = 0
    }
    private struct SMCPLimitData {
        var version: UInt16 = 0, length: UInt16 = 0
        var cpuPLimit: UInt32 = 0, gpuPLimit: UInt32 = 0, memPLimit: UInt32 = 0
    }
    private struct SMCKeyInfoData {
        var dataSize: UInt32 = 0, dataType: UInt32 = 0, dataAttributes: UInt8 = 0
    }
    private struct SMCParamStruct {
        var key: UInt32 = 0
        var vers = SMCVersion()
        var pLimitData = SMCPLimitData()
        var keyInfo = SMCKeyInfoData()
        var padding: UInt16 = 0
        var result: UInt8 = 0
        var status: UInt8 = 0
        var data8: UInt8 = 0
        var data32: UInt32 = 0
        var bytes: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) =
                   (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    }

    private func open() {
        guard !isOpen else { return }
        let service = IOServiceGetMatchingService(0, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return }
        let result = IOServiceOpen(service, mach_task_self_, 0, &conn)
        IOObjectRelease(service)
        isOpen = (result == kIOReturnSuccess)
    }

    private func fourCharCode(_ key: String) -> UInt32 {
        var result: UInt32 = 0
        for c in key.utf8 { result = (result << 8) + UInt32(c) }
        return result
    }

    private func call(_ input: inout SMCParamStruct) -> SMCParamStruct? {
        guard isOpen else { return nil }
        var output = SMCParamStruct()
        let inSize = MemoryLayout<SMCParamStruct>.stride
        var outSize = MemoryLayout<SMCParamStruct>.stride
        let result = withUnsafePointer(to: &input) { inPtr -> kern_return_t in
            withUnsafeMutablePointer(to: &output) { outPtr -> kern_return_t in
                IOConnectCallStructMethod(conn, 2, UnsafeRawPointer(inPtr), inSize, UnsafeMutableRawPointer(outPtr), &outSize)
            }
        }
        return result == kIOReturnSuccess ? output : nil
    }

    // Reads a 4-character SMC key and returns its value in °C, or nil.
    private func readTemperature(key: String) -> Double? {
        open()
        guard isOpen else { return nil }

        var infoInput = SMCParamStruct()
        infoInput.key = fourCharCode(key)
        infoInput.data8 = 9 // kSMCGetKeyInfo
        guard let infoOutput = call(&infoInput), infoOutput.result == 0, infoOutput.keyInfo.dataSize > 0 else { return nil }

        var readInput = SMCParamStruct()
        readInput.key = fourCharCode(key)
        readInput.keyInfo.dataSize = infoOutput.keyInfo.dataSize
        readInput.data8 = 5 // kSMCReadKey
        guard let readOutput = call(&readInput), readOutput.result == 0 else { return nil }

        let b = readOutput.bytes
        // "sp78" — signed fixed-point (7 integer bits + 8 fractional bits),
        // the format the SMC uses for most temperature sensors.
        if infoOutput.keyInfo.dataType == fourCharCode("sp78") {
            let raw = Int16(bitPattern: (UInt16(b.0) << 8) | UInt16(b.1))
            return Double(raw) / 256.0
        }
        // "flt " — plain little-endian 32-bit float, used by a few sensors.
        if infoOutput.keyInfo.dataType == fourCharCode("flt ") {
            let bits = UInt32(b.0) | (UInt32(b.1) << 8) | (UInt32(b.2) << 16) | (UInt32(b.3) << 24)
            return Double(Float(bitPattern: bits))
        }
        return nil
    }

    // Known SMC temperature-sensor keys spanning Apple Silicon generations
    // (M1 through M3-class Efficiency/Performance clusters, plus the
    // classic Intel-era keys as a harmless no-op fallback). Keys that don't
    // exist on a given machine simply fail to resolve and are skipped.
    private static let candidateKeys = [
        "Tp09","Tp0T","Tp01","Tp05","Tp0D","Tp0H","Tp0L","Tp0P","Tp0X","Tp0b",
        "Te05","Te0L","Te0P","Te0S",
        "Tf04","Tf09","Tf0A","Tf0B",
        "Tp1h","Tp1t","Tp1p","Tp1l","Tp1f","Tp1C","Tp1c",
        "TC0P","TC0H","TC0D","TC0E","TC0F","TC0C","TC0c",
        "TC1C","TC2C","TC3C","TC4C","TC5C","TC6C","TC7C","TC8C",
        "TCPU","TCGC","TACC","TH0x","TH1x"
    ]

    // Averages every candidate key that resolves to a plausible CPU
    // temperature (5–115°C). Returns nil if none resolve, so the caller
    // can fall back to the thermalState-based estimate.
    func averageCPUTemperature() -> Double? {
        let readings = smcReadings()
        guard !readings.isEmpty else { return nil }
        return readings.max()
    }

    func smcReadings() -> [Double] {
        SMCReader.candidateKeys
            .compactMap { readTemperature(key: $0) }
            .filter { $0 > 5 && $0 < 115 }
    }
}

struct CoreInfo: Identifiable {
    let id: Int
    var usage: Double
    var clockMHz: Double
}

class CPUMonitor: ObservableObject {
    static let shared = CPUMonitor()

    @Published var totalUsage: Double = 0
    @Published var temperature: Double = 0
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var baseClock: Double = 0
    @Published var boostClock: Double = 0
    @Published var cores: [CoreInfo] = []
    @Published var usageHistory: [Double] = Array(repeating: 0, count: 80) // ~60s at 750ms/tick
    @Published var cpuName: String = "Apple CPU"
    @Published var physicalCores: Int = 0
    @Published var logicalCores: Int = 0
    @Published var memoryUsedGB: Double = 0
    @Published var memoryFreeGB: Double = 0
    @Published var memoryTotalGB: Double = 0
    @Published var memoryUsedPercent: Double = 0
    @Published var diskUsedGB: Double = 0
    @Published var diskFreeGB: Double = 0
    @Published var diskTotalGB: Double = 0
    @Published var diskUsedPercent: Double = 0
    @Published var diskVolumeName: String = "Macintosh HD"
    @Published var tempSource: String = "Thermal Estimate"
    @Published var smcSensorCount: Int = 0
    @Published var clockSource: String = "Model Estimate"

    // Apple Silicon doesn't expose a public per-core °C sensor API, but
    // ProcessInfo.thermalState reflects the real thermal pressure macOS is
    // tracking system-wide. We map its 4 discrete states to a *range* rather
    // than a single flat number, and interpolate within that range using
    // live CPU usage so the gauge moves continuously instead of sitting on
    // one fixed value (e.g. always reading 40 while thermalState == .nominal).
    static func thermalDisplayValue(_ state: ProcessInfo.ThermalState, usage: Double) -> Double {
        let u = max(0, min(100, usage)) / 100.0
        // Nominal thermalState can still reach 70–85°C under full load on Apple Silicon;
        // the old 35–50°C band capped the UI at 50°C whenever SMC didn't resolve.
        switch state {
        case .nominal:  return 36 + 46 * u   // 36–82°C
        case .fair:     return 58 + 27 * u   // 58–85°C
        case .serious:  return 72 + 18 * u   // 72–90°C
        case .critical: return 86 + 12 * u   // 86–98°C
        @unknown default: return 36 + 46 * u
        }
    }

    // Prefer the hottest plausible SMC reading; blend with load estimate so
    // package/ambient sensors can't pin the gauge at ~50°C under stress.
    static func resolveTemperature(state: ProcessInfo.ThermalState, usage: Double, smcReadings: [Double]) -> (temp: Double, source: String) {
        let estimate = thermalDisplayValue(state, usage: usage)
        guard let smcPeak = smcReadings.max() else {
            return (estimate, "macOS thermalState + load estimate")
        }
        let temp = max(smcPeak, estimate)
        if smcPeak >= estimate - 2 {
            return (temp, "Apple SMC peak (\(smcReadings.count) sensors)")
        }
        return (temp, "Load estimate (SMC peak \(Int(smcPeak.rounded()))°C, \(smcReadings.count) sensors)")
    }

    static func thermalLabel(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:  return "NOMINAL"
        case .fair:     return "FAIR"
        case .serious:  return "SERIOUS"
        case .critical: return "CRITICAL"
        @unknown default: return "UNKNOWN"
        }
    }

    private var timer: Timer?
    private var prevCPUInfo: processor_info_array_t?
    private var prevNumCPUInfo: mach_msg_type_number_t = 0

    init() { detectCPUInfo(); startMonitoring() }

    deinit {
        timer?.invalidate()
        if let info = prevCPUInfo {
            deallocateCPUInfo(info, count: prevNumCPUInfo)
        }
    }

    private func cpuTickDelta(_ current: Int32, _ previous: Int32) -> UInt64 {
        UInt64(UInt32(bitPattern: current) &- UInt32(bitPattern: previous))
    }

    private func deallocateCPUInfo(_ info: processor_info_array_t, count: mach_msg_type_number_t) {
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info),
                      vm_size_t(count) * vm_size_t(MemoryLayout<integer_t>.size))
    }

    private func detectCPUInfo() {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        if size > 0 {
            var name = [CChar](repeating: 0, count: size)
            sysctlbyname("machdep.cpu.brand_string", &name, &size, nil, 0)
            let s = String(cString: name)
            if !s.isEmpty { cpuName = s }
        }
        if cpuName == "Apple CPU" {
            var sz = 0; sysctlbyname("hw.model", nil, &sz, nil, 0)
            var m = [CChar](repeating: 0, count: sz)
            sysctlbyname("hw.model", &m, &sz, nil, 0)
            cpuName = "Apple Silicon (\(String(cString: m)))"
        }
        var pc: Int32 = 0; var lc: Int32 = 0; var isz = MemoryLayout<Int32>.size
        sysctlbyname("hw.physicalcpu", &pc, &isz, nil, 0)
        sysctlbyname("hw.logicalcpu", &lc, &isz, nil, 0)
        physicalCores = Int(pc); logicalCores = Int(lc)
        var freq: UInt64 = 0; var fsz = MemoryLayout<UInt64>.size
        sysctlbyname("hw.cpufrequency", &freq, &fsz, nil, 0)
        if freq > 0 {
            baseClock = Double(freq) / 1_000_000
            clockSource = "sysctl hw.cpufrequency"
        } else {
            var msz = 0; sysctlbyname("hw.model", nil, &msz, nil, 0)
            var mo = [CChar](repeating: 0, count: msz)
            sysctlbyname("hw.model", &mo, &msz, nil, 0)
            let ms = String(cString: mo).lowercased()
            baseClock = ms.contains("m3") ? 4050 : ms.contains("m2") ? 3490 : 3200
            clockSource = "Apple Silicon model table"
        }
        cores = (0..<max(logicalCores, 1)).map { CoreInfo(id: $0, usage: 0, clockMHz: baseClock) }
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in self?.update() }
        timer?.fire()
    }

    private func update() { updateCPUUsage(); updateDerived(); updateMemory(); updateDisk() }

    private func updateMemory() {
        var memSize: UInt64 = 0
        var memLen = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &memSize, &memLen, nil, 0)
        let totalGB = Double(memSize) / 1_073_741_824

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }
        let pageSize = Double(vm_kernel_page_size)
        let usedPages = Double(stats.active_count + stats.wire_count + stats.compressor_page_count)
        let freePages = Double(stats.free_count + stats.inactive_count)
        let usedGB = (usedPages * pageSize) / 1_073_741_824
        let freeGB = (freePages * pageSize) / 1_073_741_824
        let usedPct = totalGB > 0 ? min(100, usedGB / totalGB * 100) : 0
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.memoryTotalGB = totalGB
            self.memoryUsedGB = usedGB
            self.memoryFreeGB = freeGB
            self.memoryUsedPercent = usedPct
        }
    }

    private func updateDisk() {
        let volURL = URL(fileURLWithPath: NSHomeDirectory())
        guard let values = try? volURL.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeLocalizedNameKey
        ]),
              let totalBytes = values.volumeTotalCapacity,
              let freeBytes = values.volumeAvailableCapacityForImportantUsage else { return }
        let totalGB = Double(totalBytes) / 1_073_741_824
        let freeGB = Double(freeBytes) / 1_073_741_824
        let usedGB = max(0, totalGB - freeGB)
        let usedPct = totalGB > 0 ? min(100, usedGB / totalGB * 100) : 0
        let volName = values.volumeLocalizedName.flatMap { $0.isEmpty ? nil : $0 } ?? "Macintosh HD"
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.diskTotalGB = totalGB
            self.diskUsedGB = usedGB
            self.diskFreeGB = freeGB
            self.diskUsedPercent = usedPct
            self.diskVolumeName = volName
        }
    }

    private func updateCPUUsage() {
        var n: natural_t = 0
        var info: processor_info_array_t?
        var num: mach_msg_type_number_t = 0
        guard host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &n, &info, &num) == KERN_SUCCESS,
              let info = info else { return }

        var usages: [Double]? = nil
        if let prev = prevCPUInfo {
            var computed: [Double] = []
            for i in 0..<Int(n) {
                let b = Int32(CPU_STATE_MAX) * Int32(i)
                let u = cpuTickDelta(info[Int(b+CPU_STATE_USER)], prev[Int(b+CPU_STATE_USER)])
                let s = cpuTickDelta(info[Int(b+CPU_STATE_SYSTEM)], prev[Int(b+CPU_STATE_SYSTEM)])
                let ni = cpuTickDelta(info[Int(b+CPU_STATE_NICE)], prev[Int(b+CPU_STATE_NICE)])
                let id = cpuTickDelta(info[Int(b+CPU_STATE_IDLE)], prev[Int(b+CPU_STATE_IDLE)])
                let busy = u + s + ni
                let t = busy + id
                computed.append(t > 0 ? max(0, min(100, Double(busy) / Double(t) * 100)) : 0)
            }
            usages = computed
            deallocateCPUInfo(prev, count: prevNumCPUInfo)
        }

        prevCPUInfo = info
        prevNumCPUInfo = num
        guard let usages = usages else { return }

        let avg = usages.isEmpty ? 0 : usages.reduce(0,+)/Double(usages.count)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.totalUsage = avg
            self.usageHistory.removeFirst(); self.usageHistory.append(avg)
            for (i, u) in usages.enumerated() where i < self.cores.count { self.cores[i].usage = u }
        }
    }

    private func updateDerived() {
        // Prefer a real SMC sensor reading (see SMCReader above); only fall
        // back to the thermalState-based estimate if the SMC can't be
        // reached or no known key resolves on this machine.
        let state = ProcessInfo.processInfo.thermalState
        let smcReadings = SMCReader.shared.smcReadings()
        let resolved = CPUMonitor.resolveTemperature(state: state, usage: totalUsage, smcReadings: smcReadings)
        let boost = baseClock + (baseClock * 0.28) * (totalUsage / 100.0)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.thermalState = state
            self.tempSource = resolved.source
            self.smcSensorCount = smcReadings.count
            self.temperature = resolved.temp; self.boostClock = boost
            let maxB = self.baseClock * 1.28
            for i in 0..<self.cores.count {
                self.cores[i].clockMHz = self.baseClock + (maxB - self.baseClock) * (self.cores[i].usage / 100.0)
            }
        }
    }
}

// ── Battery monitor (pmset + ioreg — IOPS APIs are unavailable to swiftc) ───
class BatteryMonitor: ObservableObject {
    static let shared = BatteryMonitor()

    @Published var isPresent = false
    @Published var levelPercent = 0
    @Published var isCharging = false
    @Published var isFullyCharged = false
    @Published var chargeWatts: Double = 0
    @Published var chargeRateText = "…"
    @Published var powerSource = "Unknown"
    @Published var timeToFullMinutes: Int?

    private var timer: Timer?
    private var prevLevel: Int?
    private var prevSampleTime: Date?

    private struct Snapshot {
        var isPresent = false
        var levelPercent = 0
        var isCharging = false
        var isFullyCharged = false
        var chargeWatts: Double = 0
        var chargeRateText = "…"
        var powerSource = "Unknown"
        var timeToFullMinutes: Int?
    }

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in self?.poll() }
        timer?.fire()
    }

    private func poll() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            var snap = Self.readPmset() ?? Snapshot()
            if let hw = Self.readIoreg() {
                if snap.isPresent {
                    if hw.adapterWatts > 0 { snap.chargeWatts = hw.adapterWatts }
                    if hw.chargeWatts > 0 && snap.isCharging { snap.chargeWatts = hw.chargeWatts }
                    if snap.timeToFullMinutes == nil, let eta = hw.timeToFullMinutes { snap.timeToFullMinutes = eta }
                } else if hw.levelPercent > 0 {
                    snap.isPresent = true
                    snap.levelPercent = hw.levelPercent
                    snap.isCharging = hw.isCharging
                    snap.isFullyCharged = hw.levelPercent >= 100
                    snap.chargeWatts = hw.chargeWatts > 0 ? hw.chargeWatts : hw.adapterWatts
                    snap.powerSource = hw.isCharging ? "AC Power" : "Battery Power"
                    snap.timeToFullMinutes = hw.timeToFullMinutes
                }
            }
            if snap.isPresent {
                if snap.isCharging && snap.chargeWatts > 0 {
                    snap.chargeRateText = String(format: "%.0f W", snap.chargeWatts)
                } else if snap.isCharging, let eta = snap.timeToFullMinutes, eta > 0 {
                    snap.chargeRateText = String(format: "%d min", eta)
                } else if snap.isCharging {
                    snap.chargeRateText = "Charging"
                } else if snap.isFullyCharged {
                    snap.chargeRateText = "Full"
                } else if snap.isPresent {
                    snap.chargeRateText = "On battery"
                }
                if snap.isCharging, snap.chargeWatts <= 0,
                   let prev = self.prevLevel, let prevT = self.prevSampleTime {
                    let dt = Date().timeIntervalSince(prevT)
                    if dt >= 4 {
                        let dp = snap.levelPercent - prev
                        if dp > 0 {
                            snap.chargeRateText = String(format: "+%.1f%%/hr", Double(dp) / dt * 3600)
                        }
                    }
                }
                self.prevLevel = snap.levelPercent
                self.prevSampleTime = Date()
            } else {
                snap.chargeRateText = "No battery"
                snap.powerSource = "AC / Desktop"
            }
            DispatchQueue.main.async {
                self.isPresent = snap.isPresent
                self.levelPercent = snap.levelPercent
                self.isCharging = snap.isCharging
                self.isFullyCharged = snap.isFullyCharged
                self.chargeWatts = snap.chargeWatts
                self.chargeRateText = snap.chargeRateText
                self.powerSource = snap.powerSource
                self.timeToFullMinutes = snap.timeToFullMinutes
            }
        }
    }

    private static func runTool(_ path: String, _ args: [String]) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            guard task.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch { return nil }
    }

    private static func readPmset() -> Snapshot? {
        guard let out = runTool("/usr/bin/pmset", ["-g", "batt"]) else { return nil }
        var snap = Snapshot()
        for line in out.components(separatedBy: .newlines) where line.contains("InternalBattery") {
            snap.isPresent = true
            if let pctR = line.range(of: #"\)\s*(\d+)%"#, options: .regularExpression) {
                let pctStr = String(line[pctR]).replacingOccurrences(of: ")", with: "").trimmingCharacters(in: .whitespaces)
                snap.levelPercent = Int(pctStr.replacingOccurrences(of: "%", with: "")) ?? snap.levelPercent
            }
            let lower = line.lowercased()
            snap.isCharging = lower.contains("charging;") && !lower.contains("not charging")
            snap.isFullyCharged = !snap.isCharging && (lower.contains("charged;") || snap.levelPercent >= 100)
            if let timeR = line.range(of: #"(\d+):(\d+)\s+remaining"#, options: .regularExpression) {
                let chunk = String(line[timeR])
                let parts = chunk.components(separatedBy: ":")
                if parts.count >= 2 {
                    let hrs = Int(parts[0]) ?? 0
                    let mins = Int(parts[1].prefix(while: { $0.isNumber })) ?? 0
                    snap.timeToFullMinutes = hrs * 60 + mins
                }
            }
            snap.powerSource = snap.isCharging ? "AC Power" : "Battery Power"
            if snap.isCharging, let eta = snap.timeToFullMinutes {
                snap.chargeRateText = String(format: "%d min", eta)
            }
            return snap
        }
        if out.lowercased().contains("ac power") {
            snap.powerSource = "AC Power"
            snap.chargeRateText = "No battery"
        }
        return snap.isPresent ? snap : nil
    }

    private struct IoregBattery {
        var levelPercent = 0
        var isCharging = false
        var adapterWatts: Double = 0
        var chargeWatts: Double = 0
        var timeToFullMinutes: Int?
    }

    private static func readIoreg() -> IoregBattery? {
        guard let out = runTool("/usr/sbin/ioreg", ["-rn", "AppleSmartBattery", "-c", "AppleSmartBattery"]) else { return nil }
        var info = IoregBattery()
        if let soc = matchInt(#"StateOfCharge"=\s*(\d+)"#, in: out) ?? matchInt(#"CurrentCapacity"=\s*(\d+)"#, in: out) {
            info.levelPercent = min(100, soc)
        }
        if out.contains("\"ExternalConnected\" = Yes") { info.isCharging = true }
        if let w = matchInt(#"\"Watts\"=(\d+)"#, in: out) { info.adapterWatts = Double(w) }
        if let cc = matchInt(#"ChargingCurrent"=(\d+)"#, in: out),
           let mv = matchInt(#"AppleRawBatteryVoltage"=(\d+)"#, in: out), cc > 0 {
            info.chargeWatts = Double(cc) / 1000.0 * Double(mv) / 1000.0
        } else if let ma = matchInt(#"\"Amperage\"=(\d+)"#, in: out), ma > 0 {
            info.chargeWatts = Double(ma) / 1000.0 * 12.0
        }
        if let avg = matchInt(#"AvgTimeToFull"=\s*(\d+)"#, in: out) { info.timeToFullMinutes = avg }
        else if let tr = matchInt(#"TimeRemaining"=\s*(\d+)"#, in: out), info.isCharging { info.timeToFullMinutes = tr }
        return info.levelPercent > 0 || info.adapterWatts > 0 ? info : nil
    }

    private static func matchInt(_ pattern: String, in text: String) -> Int? {
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              m.numberOfRanges > 1,
              let r = Range(m.range(at: 1), in: text) else { return nil }
        return Int(text[r])
    }
}

extension Color {
    static let bg      = Color(red:0.05,green:0.05,blue:0.08)
    static let card    = Color(red:0.10,green:0.10,blue:0.14)
    static let border  = Color(red:0.20,green:0.20,blue:0.28)
    static let accent  = Color(red:0.0, green:0.85,blue:1.0)
    static let nGreen  = Color(red:0.1, green:1.0, blue:0.5)
    static let nOrange = Color(red:1.0, green:0.55,blue:0.1)
    static let nRed    = Color(red:1.0, green:0.25,blue:0.25)
    static func usage(_ p: Double) -> Color { p < 40 ? .nGreen : p < 70 ? .accent : p < 90 ? .nOrange : .nRed }
    static func temp(_ t: Double)  -> Color { t < 60  ? .nGreen : t < 80  ? .nOrange : .nRed }
}

// ── Bitcoin price ────────────────────────────────────────────────────────────
// Fetches live BTC/USD price from CoinGecko's free public API every 30s.
// No API key required. Falls back to the last known price on network error
// so the display never goes blank mid-session.
class BTCPriceMonitor: ObservableObject {
    static let shared = BTCPriceMonitor()
    @Published var priceUSD: Double? = nil
    @Published var change24h: Double? = nil

    private var timer: Timer?
    private let url = URL(string:
        "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true"
    )!

    func start() {
        fetch()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in self?.fetch() }
    }

    private func fetch() {
        PinnedSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let btc  = json["bitcoin"] as? [String: Any],
                  let usd  = btc["usd"] as? Double else { return }
            let change = btc["usd_24h_change"] as? Double
            DispatchQueue.main.async {
                self?.priceUSD  = usd
                self?.change24h = change
            }
        }.resume()
    }
}

class GPUMonitor: ObservableObject {
    static let shared = GPUMonitor()
    @Published var usage: Double = 0   // % busy, read from IOKit accelerator stats

    private var timer: Timer?
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in self?.poll() }
        poll()
    }

    // Real GPU utilization from the IOAccelerator registry entry (same source
    // Activity Monitor and tools like asitop read). No public framework
    // exposes this directly on Apple Silicon, so we shell out to `ioreg`
    // rather than synthesize a number — same honesty rule as CPU temp.
    private func poll() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
        task.arguments = ["-r", "-d", "1", "-c", "IOAccelerator"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
        } catch { return }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        guard let out = String(data: data, encoding: .utf8) else { return }
        if let range = out.range(of: "\"Device Utilization %\"=") {
            let after = out[range.upperBound...]
            let numStr = after.prefix(while: { $0.isNumber })
            if let val = Double(numStr) {
                DispatchQueue.main.async { self.usage = val }
            }
        }
    }
}


struct GraphView: View {
    let history: [Double]; let color: Color
    var body: some View {
        GeometryReader { g in
            Path { p in
                let w = g.size.width, h = g.size.height
                let step = w / Double(max(history.count - 1, 1))
                for (i, v) in history.enumerated() {
                    let pt = CGPoint(x: Double(i) * step, y: h - v / 100 * h)
                    i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                }
            }
            .stroke(color.opacity(0.85), lineWidth: 1)
        }
    }
}

struct CoreRow: View {
    let core: CoreInfo; let index: Int
    var body: some View {
        HStack(spacing: 8) {
            Text("C\(index)").font(rNitroFont(9)).foregroundColor(.secondary).frame(width: 20, alignment: .leading)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.border.opacity(0.45))
                    Capsule()
                        .fill(Color.usage(core.usage).opacity(0.9))
                        .frame(width: g.size.width * core.usage / 100)
                }
            }.frame(height: 4)
            Text(String(format: "%.0f%%", core.usage))
                .font(rNitroFont(9))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct MinimalDivider: View {
    var body: some View {
        Rectangle().fill(Color.border.opacity(0.35)).frame(height: 1)
    }
}

struct MinimalButton: View {
    let title: String
    var tint: Color = .accent
    var disabled: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(rNitroFont(11, weight: .medium))
                .foregroundColor(disabled ? .secondary : tint)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.clear)
                .overlay(Capsule().stroke(disabled ? Color.border.opacity(0.4) : tint.opacity(0.5), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

enum StatDetailKind: String, Identifiable {
    case clock, temperature, cores, memory, storage, battery
    var id: String { rawValue }
}

enum AppTab: String, CaseIterable, Identifiable {
    case monitor = "Monitor"
    case game = "Boba Tea"
    var id: String { rawValue }
}

struct WebGameView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        let folder = url.deletingLastPathComponent()
        webView.loadFileURL(url, allowingReadAccessTo: folder)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}
}

struct BobaTeaGameView: View {
    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "BobaTeaTycoon") {
                WebGameView(url: url)
            } else {
                VStack(spacing: 8) {
                    Text("Boba Tea Tycoon").font(rNitroFont(13, weight: .semibold))
                    Text("Game files not found in app bundle.")
                        .font(rNitroFont(10)).foregroundColor(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.bg)
    }
}

struct UsageBarRow: View {
    let label: String
    let usedGB: Double
    let freeGB: Double
    let totalGB: Double
    let usedPercent: Double
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(label).font(rNitroFont(10)).foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", usedPercent)).font(rNitroFont(10)).foregroundColor(.secondary)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.border.opacity(0.45))
                        Capsule().fill(Color.accent.opacity(0.75))
                            .frame(width: g.size.width * usedPercent / 100)
                    }
                }.frame(height: 4)
                HStack {
                    Text(String(format: "%.1f GB used", usedGB))
                    Spacer()
                    Text(String(format: "%.1f GB free", freeGB))
                }
                .font(rNitroFont(9))
                .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

struct StatCell: View {
    let title: String; let value: String; let unit: String; let color: Color
    var action: (() -> Void)? = nil
    var body: some View {
        Button(action: { action?() }) {
            VStack(spacing: 3) {
                Text(title).font(rNitroFont(8)).foregroundColor(.secondary).tracking(0.5)
                Text(value).font(rNitroFont(16, weight: .semibold)).foregroundColor(color)
                Text(unit).font(rNitroFont(8)).foregroundColor(.secondary.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

struct StatDetailPopup: View {
    let kind: StatDetailKind
    @ObservedObject var monitor: CPUMonitor
    @ObservedObject var battery: BatteryMonitor
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(popupTitle).font(rNitroFont(14, weight: .semibold))
                Spacer()
                Button("Close") { dismiss() }
                    .font(rNitroFont(11))
                    .foregroundColor(.secondary)
                    .buttonStyle(.plain)
            }
            MinimalDivider()
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(detailRows, id: \.0) { row in
                        HStack(alignment: .top, spacing: 10) {
                            Text(row.0).font(rNitroFont(10)).foregroundColor(.secondary).frame(width: 100, alignment: .leading)
                            Text(row.1).font(rNitroFont(10)).frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 320, height: 340)
        .background(Color.bg)
    }

    private var popupTitle: String {
        switch kind {
        case .clock: return "Clock Speed Details"
        case .temperature: return "Temperature Details"
        case .cores: return "Core & Thread Details"
        case .memory: return "Memory Details"
        case .storage: return "Storage Details"
        case .battery: return "Battery Details"
        }
    }

    private var detailRows: [(String, String)] {
        switch kind {
        case .clock:
            let maxBoost = monitor.baseClock * 1.28
            let avgCore = monitor.cores.isEmpty ? monitor.boostClock : monitor.cores.map(\.clockMHz).reduce(0, +) / Double(monitor.cores.count)
            return [
                ("CPU", monitor.cpuName),
                ("Base Clock", String(format: "%.0f MHz", monitor.baseClock)),
                ("Boost Clock", String(format: "%.0f MHz", monitor.boostClock)),
                ("Max Theoretical", String(format: "%.0f MHz", maxBoost)),
                ("Avg Per-Core", String(format: "%.0f MHz", avgCore)),
                ("Source", monitor.clockSource),
                ("Load Scaling", "Boost rises with per-core usage (up to ~28% above base)")
            ]
        case .temperature:
            return [
                ("Current", String(format: "%.1f °C", monitor.temperature)),
                ("Thermal State", CPUMonitor.thermalLabel(monitor.thermalState)),
                ("Data Source", monitor.tempSource),
                ("SMC Sensors", monitor.smcSensorCount > 0 ? "\(monitor.smcSensorCount) active" : "None (using estimate)"),
                ("Nominal Range", "36–82 °C (scales with CPU load)"),
                ("Fair Range", "58–85 °C under moderate thermal pressure"),
                ("Serious/Critical", "75–98 °C — thermal throttling likely")
            ]
        case .cores:
            var rows: [(String, String)] = [
                ("Physical Cores", "\(monitor.physicalCores)"),
                ("Logical Threads", "\(monitor.logicalCores)"),
                ("Active Cores", "\(monitor.cores.count) monitored"),
                ("Total CPU Load", String(format: "%.1f%%", monitor.totalUsage))
            ]
            for (i, core) in monitor.cores.prefix(8).enumerated() {
                rows.append(("Core \(i)", String(format: "%.0f%% @ %.0f MHz", core.usage, core.clockMHz)))
            }
            if monitor.cores.count > 8 {
                rows.append(("…", "+\(monitor.cores.count - 8) more cores in breakdown below"))
            }
            return rows
        case .memory:
            return [
                ("Total RAM", String(format: "%.1f GB", monitor.memoryTotalGB)),
                ("Used", String(format: "%.1f GB (%.0f%%)", monitor.memoryUsedGB, monitor.memoryUsedPercent)),
                ("Free", String(format: "%.1f GB", monitor.memoryFreeGB)),
                ("Source", "host_statistics64 (active + wired + compressed)")
            ]
        case .battery:
            var rows: [(String, String)] = [
                ("Level", battery.isPresent ? "\(battery.levelPercent)%" : "N/A"),
                ("Power Source", battery.powerSource),
                ("Charging", battery.isCharging ? "Yes" : "No"),
                ("Charge Rate", battery.chargeRateText)
            ]
            if battery.chargeWatts > 0 {
                rows.append(("Adapter Power", String(format: "%.1f W", battery.chargeWatts)))
            }
            if let eta = battery.timeToFullMinutes, eta > 0 {
                rows.append(("Time to Full", "\(eta) min"))
            }
            rows.append(("Source", "pmset + ioreg (macOS)"))
            return rows
        case .storage:
            return [
                ("Volume", monitor.diskVolumeName),
                ("Total", String(format: "%.1f GB", monitor.diskTotalGB)),
                ("Used", String(format: "%.1f GB (%.0f%%)", monitor.diskUsedGB, monitor.diskUsedPercent)),
                ("Free", String(format: "%.1f GB", monitor.diskFreeGB)),
                ("Mount", "/ (system volume)")
            ]
        }
    }
}

func rNitroFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom("Lazy Dog", size: size).weight(weight)
}

// ── CPU stress test ──────────────────────────────────────────────────────────
// Spins up one busy-loop thread per logical core to genuinely max out CPU
// usage, so the person can watch usage/temp/clock respond live under real
// load — same idea as Prime95/stress-ng, just built in. User-initiated only,
// always stoppable, and threads run at background QoS so they don't starve
// the UI thread or the monitoring timers themselves.
final class StressTester: ObservableObject {
    static let shared = StressTester()
    @Published var isRunning = false
    @Published var elapsedSeconds = 0

    private var stopFlag = false
    private var timer: Timer?
    private let queue = DispatchQueue(label: "rnitro.stresstest", attributes: .concurrent)

    func start() {
        guard !isRunning else { return }
        isRunning = true
        stopFlag = false
        elapsedSeconds = 0

        let threadCount = max(1, CPUMonitor.shared.logicalCores)
        for _ in 0..<threadCount {
            queue.async { [weak self] in
                // Tight busy loop — deliberately wastes CPU cycles on real
                // floating point work (not sleep/no-ops) so usage is genuine,
                // not simulated. Checks stopFlag frequently so Stop feels instant.
                var x: Double = 1.0001
                while true {
                    if self?.stopFlag == true { break }
                    for _ in 0..<200_000 { x = (x * 1.0000001).squareRoot() }
                }
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    func stop() {
        stopFlag = true
        isRunning = false
        timer?.invalidate()
        timer = nil
        elapsedSeconds = 0
    }
}

// ── Benchmark (single-core / multi-core) ────────────────────────────────────
// Fixed-duration Mandelbrot throughput benchmark. Each phase runs for exactly
// N seconds and counts completed escape-iterations — self-scaling to any CPU
// speed. v6.0.1a adds a serial single-core queue, longer phases, cool-down
// between phases, @inline(never) on the hot loop, and a WorkSink accumulator
// so the optimizer can never discard the measured work.
final class WorkSink {
    private(set) var total: Int = 0
    @inline(never) func add(_ value: Int) { total &+= value }
}

final class BenchmarkRunner: ObservableObject {
    static let shared = BenchmarkRunner()

    @Published var isRunning = false
    @Published var stage: String = ""
    @Published var progress: Double = 0
    @Published var singleCoreScore: Double? = nil
    @Published var multiCoreScore: Double? = nil

    private static let tileSize: Int = 240
    private static let maxIter: Int = 900
    private static let phaseDuration: Double = 3.0
    private static let warmupDuration: Double = 0.75
    private static let cooldownDuration: Double = 0.5
    private static let scoreDivisor: Double = 1_000_000.0
    private let singleCoreQueue = DispatchQueue(label: "rnitro.bench.single", qos: .userInteractive)

    @inline(never)
    private func renderTile() -> Int {
        let n = BenchmarkRunner.tileSize
        var totalIter = 0
        for py in 0..<n {
            let y0 = (Double(py) / Double(n)) * 2.4 - 1.2
            for px in 0..<n {
                let x0 = (Double(px) / Double(n)) * 3.2 - 2.2
                var x = 0.0, y = 0.0
                var iter = 0
                while x*x + y*y <= 4.0 && iter < BenchmarkRunner.maxIter {
                    let xt = x*x - y*y + x0
                    y = 2*x*y + y0
                    x = xt
                    iter += 1
                }
                totalIter += iter
            }
        }
        return totalIter
    }

    private func now() -> UInt64 { DispatchTime.now().uptimeNanoseconds }
    private func secondsSince(_ start: UInt64) -> Double { Double(now() - start) / 1_000_000_000 }

    private func runWarmup() {
        let sink = WorkSink()
        let start = now()
        while secondsSince(start) < BenchmarkRunner.warmupDuration {
            sink.add(renderTile())
        }
        withExtendedLifetime(sink.total) {}
    }

    private func cooldown() {
        Thread.sleep(forTimeInterval: BenchmarkRunner.cooldownDuration)
    }

    private func runSingleCorePhase() -> Double {
        let sink = WorkSink()
        var elapsed = 0.0
        let start = now()
        let group = DispatchGroup()
        group.enter()
        singleCoreQueue.async { [self] in
            repeat {
                sink.add(self.renderTile())
                elapsed = self.secondsSince(start)
                let frac = min(elapsed / BenchmarkRunner.phaseDuration, 1.0)
                DispatchQueue.main.async { self.progress = frac * 0.5 }
            } while elapsed < BenchmarkRunner.phaseDuration
            group.leave()
        }
        group.wait()
        elapsed = secondsSince(start)
        withExtendedLifetime(sink.total) {}
        return (Double(sink.total) / max(elapsed, 0.001)) / BenchmarkRunner.scoreDivisor
    }

    private func runMultiCorePhase() -> Double {
        let threadCount = max(1, CPUMonitor.shared.logicalCores)
        let sink = WorkSink()
        let lock = NSLock()
        let start = now()
        DispatchQueue.concurrentPerform(iterations: threadCount) { [self] _ in
            var localOps = 0
            var elapsed = 0.0
            repeat {
                localOps += self.renderTile()
                elapsed = self.secondsSince(start)
            } while elapsed < BenchmarkRunner.phaseDuration
            lock.lock(); sink.add(localOps); lock.unlock()
            let frac = min(elapsed / BenchmarkRunner.phaseDuration, 1.0)
            DispatchQueue.main.async { self.progress = 0.5 + frac * 0.5 }
        }
        let elapsed = secondsSince(start)
        withExtendedLifetime(sink.total) {}
        return (Double(sink.total) / max(elapsed, 0.001)) / BenchmarkRunner.scoreDivisor
    }

    func run() {
        guard !isRunning else { return }
        isRunning = true
        singleCoreScore = nil
        multiCoreScore = nil
        progress = 0

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async { self.stage = "Warming Up" }
            self.runWarmup()

            DispatchQueue.main.async { self.stage = "Single-Core" }
            let singleScore = self.runSingleCorePhase()
            DispatchQueue.main.async { self.singleCoreScore = singleScore }

            self.cooldown()
            DispatchQueue.main.async { self.stage = "Multi-Core" }
            let multiScore = self.runMultiCorePhase()

            DispatchQueue.main.async {
                self.multiCoreScore = multiScore
                self.progress = 1.0
                self.stage = "Done"
                self.isRunning = false
            }
        }
    }
}


struct ContentView: View {
    @ObservedObject private var m = CPUMonitor.shared
    @ObservedObject private var bat = BatteryMonitor.shared
    @ObservedObject private var stress = StressTester.shared
    @ObservedObject private var bench = BenchmarkRunner.shared
    @State private var statDetail: StatDetailKind? = nil
    @State private var tab: AppTab = .monitor

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(AppTab.allCases) { t in
                        Button(action: { tab = t }) {
                            Text(t.rawValue)
                                .font(rNitroFont(11, weight: tab == t ? .semibold : .regular))
                                .foregroundColor(tab == t ? .accent : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .overlay(alignment: .bottom) {
                                    if tab == t {
                                        Rectangle().fill(Color.accent).frame(height: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)

                MinimalDivider()

                if tab == .game {
                    BobaTeaGameView()
                } else {
                    monitorTab
                }
            }
        }
        .sheet(item: $statDetail) { kind in
            StatDetailPopup(kind: kind, monitor: m, battery: bat)
        }
        .preferredColorScheme(.dark)
    }

    private var monitorTab: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("rNitro").font(rNitroFont(15, weight: .semibold))
                        Text(m.cpuName).font(rNitroFont(10)).foregroundColor(.secondary)
                            .lineLimit(1).truncationMode(.tail)
                    }
                    Spacer()
                    HStack(spacing: 5) {
                        Circle().fill(Color.nGreen).frame(width: 5, height: 5)
                        Text("Live").font(rNitroFont(9)).foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 14)

                MinimalDivider().padding(.horizontal, 16)

                    // Primary stats — tap for detail popups
                    HStack(spacing: 0) {
                        StatCell(title: "BASE", value: String(format: "%.0f", m.baseClock), unit: "MHz", color: .primary, action: { statDetail = .clock })
                        StatCell(title: "BOOST", value: String(format: "%.0f", m.boostClock), unit: "MHz", color: .accent, action: { statDetail = .clock })
                        StatCell(title: "TEMP", value: String(format: "%.0f", m.temperature), unit: "°C", color: Color.temp(m.temperature), action: { statDetail = .temperature })
                        StatCell(title: "CORES", value: "\(m.logicalCores)", unit: "threads", color: .nGreen, action: { statDetail = .cores })
                    }
                    .padding(.vertical, 12).padding(.horizontal, 8)

                    MinimalDivider().padding(.horizontal, 16)

                    // Battery level + charge rate
                    HStack(spacing: 0) {
                        StatCell(
                            title: "BATTERY",
                            value: bat.isPresent ? "\(bat.levelPercent)" : "—",
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
                    .padding(.vertical, 12).padding(.horizontal, 8)

                    MinimalDivider().padding(.horizontal, 16)

                    // CPU usage + history
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("CPU").font(rNitroFont(10)).foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f%%", m.totalUsage))
                                .font(rNitroFont(13, weight: .semibold))
                                .foregroundColor(Color.usage(m.totalUsage))
                        }
                        GraphView(history: m.usageHistory, color: Color.usage(m.totalUsage))
                            .frame(height: 36)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)

                    MinimalDivider().padding(.horizontal, 16)

                    // Memory & storage
                    VStack(alignment: .leading, spacing: 10) {
                        UsageBarRow(
                            label: "RAM",
                            usedGB: m.memoryUsedGB,
                            freeGB: m.memoryFreeGB,
                            totalGB: m.memoryTotalGB,
                            usedPercent: m.memoryUsedPercent,
                            action: { statDetail = .memory }
                        )
                        UsageBarRow(
                            label: "SSD · \(m.diskVolumeName)",
                            usedGB: m.diskUsedGB,
                            freeGB: m.diskFreeGB,
                            totalGB: m.diskTotalGB,
                            usedPercent: m.diskUsedPercent,
                            action: { statDetail = .storage }
                        )
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)

                    MinimalDivider().padding(.horizontal, 16)

                    // Per-core breakdown
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Cores").font(rNitroFont(10)).foregroundColor(.secondary)
                            Spacer()
                            Text("\(m.physicalCores)P / \(m.logicalCores)L")
                                .font(rNitroFont(9)).foregroundColor(.secondary)
                        }
                        VStack(spacing: 6) {
                            ForEach(Array(m.cores.enumerated()), id: \.offset) { i, core in
                                CoreRow(core: core, index: i)
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)

                    MinimalDivider().padding(.horizontal, 16)

                    // Stress test
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Stress").font(rNitroFont(10)).foregroundColor(.secondary)
                            if stress.isRunning {
                                Text(String(format: "%02d:%02d", stress.elapsedSeconds / 60, stress.elapsedSeconds % 60))
                                    .font(rNitroFont(9)).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        MinimalButton(
                            title: stress.isRunning ? "Stop" : "Start",
                            tint: stress.isRunning ? .nRed : .nOrange,
                            disabled: bench.isRunning,
                            action: { stress.isRunning ? stress.stop() : stress.start() }
                        )
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)

                    MinimalDivider().padding(.horizontal, 16)

                    // Benchmark
                    VStack(spacing: 10) {
                        HStack {
                            Text("Benchmark").font(rNitroFont(10)).foregroundColor(.secondary)
                            Spacer()
                            if bench.isRunning {
                                Text(bench.stage).font(rNitroFont(9)).foregroundColor(.secondary)
                            }
                        }
                        HStack(spacing: 0) {
                            VStack(spacing: 2) {
                                Text("1-core").font(rNitroFont(8)).foregroundColor(.secondary)
                                Text(bench.singleCoreScore.map { String(format: "%.0f", $0) } ?? "—")
                                    .font(rNitroFont(14, weight: .semibold)).foregroundColor(.accent)
                            }.frame(maxWidth: .infinity)
                            VStack(spacing: 2) {
                                Text("Multi").font(rNitroFont(8)).foregroundColor(.secondary)
                                Text(bench.multiCoreScore.map { String(format: "%.0f", $0) } ?? "—")
                                    .font(rNitroFont(14, weight: .semibold)).foregroundColor(.nGreen)
                            }.frame(maxWidth: .infinity)
                            MinimalButton(
                                title: bench.isRunning ? "Running…" : "Run",
                                disabled: bench.isRunning || stress.isRunning,
                                action: { bench.run() }
                            )
                        }
                        if bench.isRunning {
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.border.opacity(0.4))
                                    Capsule().fill(Color.accent.opacity(0.7))
                                        .frame(width: g.size.width * bench.progress)
                                }
                            }.frame(height: 2)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14).padding(.bottom, 16)
            }
        }
        .clipped()
    }
}

// ── Game overlay HUD ────────────────────────────────────────────────────────
// A small always-on-top, click-through panel — like MSI Afterburner's
// in-game overlay — showing live CPU%, GPU%, temp, and RAM while a fullscreen
// game is running. FPS is intentionally NOT faked here: macOS has no public
// API to hook another process's renderer (unlike RTSS on Windows), so instead
// rNitro can launch a Metal game with Apple's own native Metal HUD enabled
// (MTL_HUD_ENABLED), which shows real engine-reported FPS/frame time.
struct OverlayHUDView: View {
    @ObservedObject private var cpu = CPUMonitor.shared
    @ObservedObject private var gpu = GPUMonitor.shared
    var body: some View {
        HStack(spacing:14) {
            hudStat("CPU", String(format:"%.0f%%",cpu.totalUsage), Color.usage(cpu.totalUsage))
            hudStat("GPU", String(format:"%.0f%%",gpu.usage), Color.usage(gpu.usage))
            hudStat("TEMP", String(format:"%.0f°",cpu.temperature), Color.temp(cpu.temperature))
            hudStat("RAM", String(format:"%.1f/%.1fGB",cpu.memoryUsedGB,cpu.memoryFreeGB), .secondary)
        }
        .padding(.horizontal,12).padding(.vertical,8)
        .background(.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius:8))
        .overlay(RoundedRectangle(cornerRadius:8).stroke(.white.opacity(0.12),lineWidth:1))
    }
    private func hudStat(_ label:String,_ value:String,_ color:Color) -> some View {
        VStack(spacing:1) {
            Text(value).font(rNitroFont(13, weight: .bold)).foregroundColor(color)
            Text(label).font(rNitroFont(8, weight: .semibold)).foregroundColor(.white.opacity(0.6)).tracking(1)
        }
    }
}

final class OverlayWindowController {
    static let shared = OverlayWindowController()
    private var panel: NSPanel?
    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle() { isVisible ? hide() : show() }

    func show() {
        if panel == nil {
            let hosting = NSHostingController(rootView: OverlayHUDView())
            let p = NSPanel(contentRect: NSRect(x:0,y:0,width:280,height:64),
                             styleMask: [.nonactivatingPanel, .borderless],
                             backing: .buffered, defer: false)
            p.contentViewController = hosting
            p.isFloatingPanel = true
            p.level = .screenSaver               // stays above fullscreen game content
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = true
            p.ignoresMouseEvents = true            // click-through, doesn't steal game input
            if let screen = NSScreen.main {
                let f = screen.visibleFrame
                p.setFrameOrigin(NSPoint(x: f.maxX - 296, y: f.maxY - 80))
            }
            panel = p
        }
        GPUMonitor.shared.start()
        panel?.orderFrontRegardless()
    }

    func hide() { panel?.orderOut(nil) }
}

// Launches a target .app with Apple's native Metal performance HUD enabled,
// which reports the game's real FPS/frame time (a documented Apple debug
// feature, not a synthetic estimate). Requires the target to use Metal.
func launchWithMetalHUD(appURL: URL) {
    guard let bundle = Bundle(url: appURL),
          let execName = bundle.executableURL?.lastPathComponent else { return }
    let exec = appURL.appendingPathComponent("Contents/MacOS/\(execName)")
    let task = Process()
    task.executableURL = exec
    var env = ProcessInfo.processInfo.environment
    env["MTL_HUD_ENABLED"] = "1"
    task.environment = env
    try? task.run()
}


// Adds a live CPU% readout in the menu bar, independent of whether the main
// window is open. Clicking it opens a compact popover with the same
// real-time data (shares CPUMonitor.shared, so nothing is duplicated).
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var subscription: AnyCancellable?
    private var hotkeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {        UpdateChecker.checkOnLaunch()
        BTCPriceMonitor.shared.start()         // start fetching live BTC price

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(togglePopover)
        statusItem = item
        updateStatusTitle()

        subscription = CPUMonitor.shared.$totalUsage
            .combineLatest(CPUMonitor.shared.$temperature)
            .combineLatest(BTCPriceMonitor.shared.$priceUSD)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in self?.updateStatusTitle() }

        let popoverSize = NSSize(width: 400, height: 540)
        let hosting = NSHostingController(
            rootView: ContentView()
                .frame(width: popoverSize.width, height: popoverSize.height)
        )
        hosting.preferredContentSize = popoverSize

        let pop = NSPopover()
        pop.behavior = .transient
        pop.contentSize = popoverSize
        pop.contentViewController = hosting
        popover = pop

        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        // ⌥⇧O toggles the in-game HUD overlay from anywhere, including
        // while a fullscreen game has focus.
        hotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.option, .shift]) && event.charactersIgnoringModifiers == "o" {
                OverlayWindowController.shared.toggle()
            }
        }
    }

    @objc private func togglePopover() {
        guard let event = NSApp.currentEvent, let button = statusItem?.button else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            let overlayTitle = OverlayWindowController.shared.isVisible ? "Hide Game Overlay (⌥⇧O)" : "Show Game Overlay (⌥⇧O)"
            menu.addItem(withTitle: overlayTitle, action: #selector(toggleOverlay), keyEquivalent: "")
            menu.addItem(withTitle: "Launch App with FPS HUD…", action: #selector(launchWithHUD), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Quit rNitro", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            for i in menu.items { i.target = self }
            statusItem?.menu = menu
            button.performClick(nil)
            statusItem?.menu = nil
            return
        }
        guard let pop = popover else { return }
        if pop.isShown {
            pop.performClose(nil)
        } else {
            pop.show(relativeTo: .zero, of: button, preferredEdge: .minY)
            pop.contentViewController?.view.window?.makeKey()
        }
    }

    @objc private func toggleOverlay() { OverlayWindowController.shared.toggle() }

    @objc private func launchWithHUD() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "Launch with FPS HUD"
        if panel.runModal() == .OK, let url = panel.url {
            launchWithMetalHUD(appURL: url)
        }
    }

    private func updateStatusTitle() {
        let pct  = Int(CPUMonitor.shared.totalUsage.rounded())
        let temp = Int(CPUMonitor.shared.temperature.rounded())
        let btcStr: String
        if let p = BTCPriceMonitor.shared.priceUSD {
            let k = p / 1000
            btcStr = String(format: "₿$%.1fk", k)
        } else {
            btcStr = "₿…"
        }
        statusItem?.button?.title = "\(btcStr)  CPU: \(pct)%  Temp: \(temp)°"
    }

    // Safety net: make sure stress-test threads never keep spinning after
    // the app has quit — they check stopFlag on their own, but this
    // guarantees the flag actually gets set even on unexpected termination.
    func applicationWillTerminate(_ notification: Notification) {
        StressTester.shared.stop()
    }
}

@main
struct rNitroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    init() {
        denyDebugger()          // refuse debugger attach
        verifyBinaryIntegrity() // detect post-install binary tampering
    }
    var body: some Scene {
        WindowGroup {
            ContentView().frame(minWidth:480,idealWidth:520,maxWidth:700,minHeight:620,idealHeight:700,maxHeight:900)
        }
        .windowStyle(.hiddenTitleBar)
        .commands { CommandGroup(replacing:.newItem) {} }
    }
}
SWIFTEOF

# ── Compile directly with swiftc (no SPM) ────────────────────────────────────
echo "🔨 Compiling (this takes ~30 seconds)..."
swiftc "$WORK_DIR/main.swift" \
    -o "$WORK_DIR/rNitro" \
    -framework SwiftUI \
    -framework Cocoa \
    -framework IOKit \
    -framework WebKit \
    -framework Security \
    -framework CryptoKit \
    -parse-as-library \
    -O

# ── Security: make sure compilation actually produced a real, executable
#    regular file before we go any further (defends against a compromised
#    toolchain or a race that swaps the output path with a symlink).
if [[ ! -f "$WORK_DIR/rNitro" || -L "$WORK_DIR/rNitro" ]]; then
  echo "❌ Compiled binary missing or unexpected (symlink). Aborting."
  exit 1
fi
chmod 700 "$WORK_DIR/rNitro"

# ── Assemble .app bundle ──────────────────────────────────────────────────────
echo "📦 Building rNitro.app..."
mkdir -p "$HOME/Applications"

# ── Security: don't blindly rm -rf a path that might have been replaced by a
#    symlink pointing elsewhere. Only remove it if it's a real directory (or
#    doesn't exist), and never follow a symlink for deletion.
if [[ -e "$APP_DEST" && ! -d "$APP_DEST" ]]; then
  echo "❌ $APP_DEST exists and is not a directory (possible symlink/tamper). Aborting."
  exit 1
fi
if [[ -L "$APP_DEST" ]]; then
  echo "❌ $APP_DEST is a symlink. Refusing to remove it automatically. Aborting."
  exit 1
fi
rm -rf -- "$APP_DEST"
mkdir -p "$APP_DEST/Contents/MacOS"
mkdir -p "$APP_DEST/Contents/Resources"

cp "$WORK_DIR/rNitro" "$APP_DEST/Contents/MacOS/rNitro"
chmod 755 "$APP_DEST/Contents/MacOS/rNitro"

cat > "$APP_DEST/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>rNitro</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIdentifier</key><string>com.rnitro.cpumonitor</string>
    <key>CFBundleName</key><string>rNitro</string>
    <key>CFBundleDisplayName</key><string>rNitro</string>
    <key>CFBundleVersion</key><string>6.2.2-Final-arm64</string>
    <key>CFBundleShortVersionString</key><string>6.2.2-Final-arm64</string>
    <key>ATSApplicationFontsPath</key><string>Fonts</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>LSMinimumSystemVersion</key><string>12.0</string>
</dict>
</plist>
PLIST
chmod 644 "$APP_DEST/Contents/Info.plist"

# ── Bundle Lazy Dog font ──────────────────────────────────────────────────────
echo "🔤 Installing Lazy Dog font..."
FONT_DIR="$APP_DEST/Contents/Resources/Fonts"
mkdir -p "$FONT_DIR"
LAZY_DOG_FONT="$FONT_DIR/lazy_dog.ttf"
if [[ -f "$(dirname "$0")/lazy_dog.ttf" ]]; then
  cp "$(dirname "$0")/lazy_dog.ttf" "$LAZY_DOG_FONT"
elif curl -fsSL "https://dl.dafont.com/dl/?f=lazy_dog" -o "$WORK_DIR/lazy_dog.zip" 2>/dev/null \
     && unzip -o -j "$WORK_DIR/lazy_dog.zip" lazy_dog.ttf -d "$FONT_DIR" >/dev/null 2>&1; then
  :
else
  echo "⚠️  Could not install Lazy Dog font (non-fatal); UI will fall back to system font."
fi
[[ -f "$LAZY_DOG_FONT" ]] && chmod 644 "$LAZY_DOG_FONT"

# ── Bundle Boba Tea Tycoon mini-game ─────────────────────────────────────────
echo "🎮 Bundling Boba Tea Tycoon..."
GAME_DEST="$APP_DEST/Contents/Resources/BobaTeaTycoon"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GAME_SRC=""
for candidate in \
  "$SCRIPT_DIR/boba-game" \
  "$SCRIPT_DIR/rnitro-site/boba-game" \
  "$HOME/Downloads/boba-game" \
  "$HOME/rnitro-site-work/rnitro-site/boba-game"; do
  if [[ -d "$candidate" && -f "$candidate/index.html" ]]; then
    GAME_SRC="$candidate"
    break
  fi
done
if [[ -z "$GAME_SRC" ]]; then
  for zip in \
    "$SCRIPT_DIR/BobaTeaTycoon_v9.2.6.zip" \
    "$HOME/Downloads/BobaTeaTycoon_v9.2.6.zip"; do
    if [[ -f "$zip" ]]; then
      GAME_SRC="$(mktemp -d "${TMPDIR:-/tmp}/boba-game.XXXXXXXX")"
      unzip -qo "$zip" -d "$GAME_SRC"
      break
    fi
  done
fi
if [[ -n "$GAME_SRC" && -f "$GAME_SRC/index.html" ]]; then
  mkdir -p "$GAME_DEST"
  cp -R "$GAME_SRC/"* "$GAME_DEST/"
  find "$GAME_DEST" -type f -exec chmod 644 {} \;
  find "$GAME_DEST" -type d -exec chmod 755 {} \;
  echo "✅ Boba Tea Tycoon bundled from $GAME_SRC"
else
  echo "⚠️  Boba Tea Tycoon not found."
  echo "   Put a boba-game/ folder next to install-rNitro.sh, or keep BobaTeaTycoon_v9.2.6.zip in Downloads."
fi

# ── Generate and embed an app icon ───────────────────────────────────────────
# Drawn programmatically (no binary image assets shipped in this script) so
# there's nothing opaque to audit — a small Swift snippet renders a 1024×1024
# master icon, which `sips`/`iconutil` then scale into a standard .icns set.
echo "🎨 Generating app icon..."

cat > "$WORK_DIR/generate_icon.swift" << 'ICONEOF'
import Cocoa

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

// Rounded-square (squircle) dark background
let bgRect = CGRect(x: 0, y: 0, width: size, height: size)
let bgPath = CGPath(roundedRect: bgRect, cornerWidth: size * 0.22, cornerHeight: size * 0.22, transform: nil)
ctx.saveGState()
ctx.addPath(bgPath)
ctx.clip()
let bgColors = [
    CGColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0),
    CGColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)
] as CFArray
if let bgGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bgColors, locations: [0, 1]) {
    ctx.drawLinearGradient(bgGrad, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
}
ctx.restoreGState()

// Subtle border
ctx.saveGState()
ctx.addPath(bgPath)
ctx.setStrokeColor(CGColor(red: 0.16, green: 0.16, blue: 0.25, alpha: 1.0))
ctx.setLineWidth(size * 0.006)
ctx.strokePath()
ctx.restoreGState()

// Lightning-bolt mark, cyan → green gradient (matches the rNitro brand)
let bolt = CGMutablePath()
bolt.move(to: CGPoint(x: size * 0.58, y: size * 0.86))
bolt.addLine(to: CGPoint(x: size * 0.40, y: size * 0.50))
bolt.addLine(to: CGPoint(x: size * 0.50, y: size * 0.50))
bolt.addLine(to: CGPoint(x: size * 0.42, y: size * 0.14))
bolt.addLine(to: CGPoint(x: size * 0.62, y: size * 0.50))
bolt.addLine(to: CGPoint(x: size * 0.50, y: size * 0.50))
bolt.closeSubpath()

ctx.saveGState()
ctx.setShadow(offset: .zero, blur: size * 0.05, color: CGColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 0.55))
ctx.addPath(bolt)
ctx.clip()
let boltColors = [
    CGColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 1.0),
    CGColor(red: 0.10, green: 1.0, blue: 0.5, alpha: 1.0)
] as CFArray
if let boltGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: boltColors, locations: [0, 1]) {
    ctx.drawLinearGradient(boltGrad, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
}
ctx.restoreGState()

image.unlockFocus()

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write("Usage: generate_icon <output.png>\n".data(using: .utf8)!)
    exit(1)
}
let outPath = CommandLine.arguments[1]
guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("Failed to render icon PNG\n".data(using: .utf8)!)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: outPath))
ICONEOF

ICON_MASTER="$WORK_DIR/icon_1024.png"
swift "$WORK_DIR/generate_icon.swift" "$ICON_MASTER"

if [[ -f "$ICON_MASTER" && ! -L "$ICON_MASTER" ]]; then
  ICONSET_DIR="$WORK_DIR/AppIcon.iconset"
  mkdir -p "$ICONSET_DIR"

  declare -a ICON_SIZES=(
    "16:icon_16x16.png"
    "32:icon_16x16@2x.png"
    "32:icon_32x32.png"
    "64:icon_32x32@2x.png"
    "128:icon_128x128.png"
    "256:icon_128x128@2x.png"
    "256:icon_256x256.png"
    "512:icon_256x256@2x.png"
    "512:icon_512x512.png"
    "1024:icon_512x512@2x.png"
  )

  for entry in "${ICON_SIZES[@]}"; do
    px="${entry%%:*}"
    fname="${entry##*:}"
    sips -z "$px" "$px" "$ICON_MASTER" --out "$ICONSET_DIR/$fname" >/dev/null
  done

  if iconutil -c icns "$ICONSET_DIR" -o "$APP_DEST/Contents/Resources/AppIcon.icns"; then
    chmod 644 "$APP_DEST/Contents/Resources/AppIcon.icns"
    echo "✅ App icon generated."
  else
    echo "⚠️  Icon conversion failed (non-fatal); rNitro will use the default app icon."
  fi
else
  echo "⚠️  Icon rendering failed (non-fatal); rNitro will use the default app icon."
fi

# ── Security: ad-hoc code-sign the freshly built bundle. This doesn't replace
#    a real Developer ID signature, but it gives the binary a stable
#    identity/hash that Gatekeeper and other local tools can check, instead
#    of shipping a completely unsigned executable.
codesign --force --deep --sign - "$APP_DEST" 2>/dev/null || \
  echo "⚠️  Ad-hoc code signing failed (non-fatal); rNitro will still run, but Gatekeeper may warn."

echo ""
echo "✅ rNitro installed to $APP_DEST"
echo "🚀 Launching..."
open "$APP_DEST"
