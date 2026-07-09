#!/bin/bash
#
# rNitro installer — hardened
#
# v8.3.3-Final-arm64 — Stable release: CPU monitor + AI chat (OpenAI & OpenRouter only).
#
# v8.2.2-Beta-arm64 — iStats-style sectioned popover + legacy UI toggle.
# Menubar: single-line values only (no stacked CPU/RAM labels). Modern/Legacy switch in Extras/Tools.
#
# v8.2.1-Beta-arm64 — All AI/API providers (Gemini, OpenAI, Anthropic, Groq,
# DeepSeek, OpenRouter, LM Studio, Ollama, Hermes). Menu bar icons, network
# monitor, uninstall-rNitro.sh.
#
# v8.1.2-Beta-arm64 — Menu bar light/dark icons, network monitor in popover,
# uninstall-rNitro.sh companion script.
#
# v8.1.1-Beta-arm64 — Responsive UI, AI chat in menubar popover, per-provider history.
# Gemini, OpenAI, Anthropic, Groq, DeepSeek, OpenRouter, LM Studio, Ollama, Hermes.
#
# v7.0.2-Beta-arm64 — Beta AI chat: Gemini, OpenAI, Anthropic, Groq, OpenRouter,
# LM Studio, Ollama, and Hermes.
#
# v7.0.1-Beta-arm64 — Beta with multi-provider AI chat (Gemini, OpenAI, Anthropic, Groq).
#
# v6.2.4-Final-arm64 — Stable macOS build without AI chat (see rNitro-v6.2.4-Final-arm64.sh).
#
# v6.2.3-Final-arm64 — Chat tab (later added to menu bar popover in v8.1):
# bring your own Gemini API key, stored in Keychain; chat via gemini-2.0-flash.
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
# open getrnitro.netlify.app after OK.
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
# getrnitro.netlify.app at every launch; alerts and opens the site in the
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
# This hash is the canonical checksum published at https://getrnitro.netlify.app/
# If this check fails, your copy of the installer has been modified.
#
# Note on how this hash is computed: a script can't embed the hash of its own
# unmodified bytes (changing the EXPECTED_HASH value changes the hash). To
# break that circularity, the EXPECTED_HASH line itself is masked out before
# hashing — the published hash on the site is generated the same way, so it
# stays stable regardless of what value is plugged in here.
EXPECTED_HASH="47dcf7e394e349109df05f5ebd0fa9445e96429d1ef6568ece71654ea77f4673"
ACTUAL_HASH="$(sed 's/^EXPECTED_HASH=.*/EXPECTED_HASH="MASKED"/' "$0" | shasum -a 256 | awk '{print $1}')"
if [[ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]]; then
  echo "❌ Integrity check failed. This file may have been tampered with."
  echo "   Expected: $EXPECTED_HASH"
  echo "   Got:      $ACTUAL_HASH"
  echo "   Download a fresh copy from https://getrnitro.netlify.app/"
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

# ── Sign + quarantine helpers (prevents Gatekeeper "damaged" errors) ─────────
# Causes of "damaged and can't be opened":
#   1. com.apple.quarantine / provenance xattrs on downloaded or copied bundles
#   2. Invalid code signature (e.g. editing Info.plist after codesign)
#   3. Launching from DMG without clearing quarantine on the .app
sign_app_bundle() {
  local app="$1"
  xattr -cr "$app" 2>/dev/null || true
  local exe="$app/Contents/MacOS/rNitro"
  if [[ ! -f "$exe" ]]; then
    echo "⚠️  Cannot sign: missing $exe"
    return 1
  fi
  codesign --force --sign - --timestamp=none "$exe"
  codesign --force --sign - --timestamp=none "$app"
}

# ── Write main.swift ──────────────────────────────────────────────────────────
cat > "$WORK_DIR/main.swift" << 'SWIFTEOF'
import Cocoa
import SwiftUI
import CoreText

import IOKit
import Combine
import Security
import CryptoKit
import ServiceManagement
import UserNotifications

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

// 2. Runtime integrity: verify the app bundle's code signature is still valid.
//    Editing the binary or bundle after install breaks the signature; Gatekeeper
//    would show "damaged" — we catch the same condition at launch.
func verifyBinaryIntegrity() {
    guard let bundleURL = Bundle.main.bundleURL as CFURL? else { return }
    var staticCode: SecStaticCode?
    guard SecStaticCodeCreateWithPath(bundleURL, [], &staticCode) == errSecSuccess,
          let code = staticCode else { return }
    if SecStaticCodeCheckValidity(code, [], nil) != errSecSuccess {
        let alert = NSAlert()
        alert.messageText = "rNitro Integrity Check Failed"
        alert.informativeText = "The rNitro app signature is invalid — the bundle may have been modified after installation. Reinstall from getrnitro.netlify.app, or run: xattr -cr ~/Applications/rNitro.app"
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
    "getrnitro.netlify.app",
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
// Compared against https://getrnitro.netlify.app/version.json on every launch.
let CURRENT_VERSION = "v8.3.3-Final-arm64"
let RNITRO_BUILD_CHANNEL = "stable"
let RNITRO_FEATURE_BETA_UI = (RNITRO_BUILD_CHANNEL == "beta")
private let RNITRO_UI_FONT = "Varela Round"
let UPDATE_CHECK_URL = URL(string: "https://getrnitro.netlify.app/version.json")!
let UPDATE_PAGE_URL  = URL(string: "https://getrnitro.netlify.app")!

struct VersionInfo: Decodable {
    let latest: String
    let beta: String?
    let windows: String?
}

private struct VersionManifest: Decodable {
    let latest: String
    let beta: String?
    let releases: ReleaseMap

    struct ReleaseMap: Decodable {
        let stable: Channel
        let beta: Channel
    }

    struct Channel: Decodable {
        let zip: String
    }

    func zipName(for versionId: String) -> String {
        if versionId == latest { return releases.stable.zip }
        if let beta, versionId == beta { return releases.beta.zip }
        return "rNitro-\(versionId).zip"
    }
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

    static func displayLabel(_ versionId: String) -> String {
        versionId
            .replacingOccurrences(of: "-arm64", with: "")
            .replacingOccurrences(of: "-Final", with: " Final")
            .replacingOccurrences(of: "-Beta", with: " Beta")
    }

    static func checkOnLaunch() {
        var req = URLRequest(url: UPDATE_CHECK_URL)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 8
        PinnedSession.shared.dataTask(with: req) { data, _, error in
            guard error == nil, let data = data,
                  let info = try? JSONDecoder().decode(VersionInfo.self, from: data) else { return }
            let stableRemote = info.latest
            let betaRemote = info.beta ?? ""
            let stableNewer = isNewer(stableRemote, than: CURRENT_VERSION)
            let betaNewer = !betaRemote.isEmpty && isNewer(betaRemote, than: CURRENT_VERSION)
            guard stableNewer || betaNewer else { return }
            DispatchQueue.main.async {
                presentUpdateChoice(stable: stableRemote, beta: betaRemote,
                                    stableNewer: stableNewer, betaNewer: betaNewer)
            }
        }.resume()
    }

    private static func presentUpdateChoice(stable: String, beta: String,
                                            stableNewer: Bool, betaNewer: Bool) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "rNitro Update Available"
        var lines = ["You're running \(displayLabel(CURRENT_VERSION))."]
        if stableNewer {
            lines.append("• Final \(displayLabel(stable)) is available (production-ready).")
        } else {
            lines.append("• Final: \(displayLabel(stable)) (switch to stable channel).")
        }
        if !beta.isEmpty {
            if betaNewer {
                lines.append("• Beta \(displayLabel(beta)) is available (all AI providers + experimental features).")
            } else {
                lines.append("• Beta: \(displayLabel(beta)) (switch to beta channel).")
            }
        }
        lines.append("\nPick which build to download and install. rNitro will restart when done.")
        alert.informativeText = lines.joined(separator: "\n")
        alert.alertStyle = .informational

        let installFinal = "Install Final"
        let installBeta = beta.isEmpty ? nil : "Install Beta"
        alert.addButton(withTitle: installFinal)
        if let installBeta {
            alert.addButton(withTitle: installBeta)
        }
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            UpdateInstaller.install(remoteVersion: stable)
        } else if installBeta != nil && response == .alertSecondButtonReturn {
            UpdateInstaller.install(remoteVersion: beta)
        }
    }
}

enum UpdateInstaller {
    private static var progressPanel: NSPanel?
    private static var progressBar: NSProgressIndicator?
    private static var progressDetail: NSTextField?
    private static let updateLogURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/rNitro/update.log")

    private static func log(_ message: String) {
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
        let dir = updateLogURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: updateLogURL.path),
           let h = try? FileHandle(forWritingTo: updateLogURL) {
            h.seekToEndOfFile()
            h.write(line.data(using: .utf8) ?? Data())
            try? h.close()
        } else {
            try? line.write(to: updateLogURL, atomically: true, encoding: .utf8)
        }
    }

    static func zipURL(for zipName: String) -> URL {
        URL(string: "https://getrnitro.netlify.app/\(zipName)")!
    }

    private static func fetchManifest() -> VersionManifest? {
        let sem = DispatchSemaphore(value: 0)
        var manifest: VersionManifest?
        var req = URLRequest(url: UPDATE_CHECK_URL)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 12
        URLSession.shared.dataTask(with: req) { data, _, _ in
            if let data = data {
                manifest = try? JSONDecoder().decode(VersionManifest.self, from: data)
            }
            sem.signal()
        }.resume()
        sem.wait()
        return manifest
    }

    static func install(remoteVersion: String) {
        log("Update requested for \(remoteVersion) from \(CURRENT_VERSION)")
        DispatchQueue.main.async { showDownloadProgress(for: remoteVersion) }
        DispatchQueue.global(qos: .userInitiated).async {
            let result = performInstall(remoteVersion: remoteVersion)
            DispatchQueue.main.async {
                hideDownloadProgress()
                switch result {
                case .success:
                    break
                case .failure(let msg):
                    let alert = NSAlert()
                    alert.messageText = "Update Failed"
                    alert.informativeText = msg
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Open Website")
                    alert.addButton(withTitle: "Cancel")
                    if alert.runModal() == .alertFirstButtonReturn {
                        NSWorkspace.shared.open(UPDATE_PAGE_URL)
                    }
                }
            }
        }
    }

    private static func showDownloadProgress(for version: String) {
        hideDownloadProgress()
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 132),
            styleMask: [.titled, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "rNitro Update"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        let stack = NSStackView(frame: NSRect(x: 16, y: 16, width: 328, height: 100))
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        let label = NSTextField(labelWithString: "Downloading update…")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        let detail = NSTextField(labelWithString: "Fetching \(version) from getrnitro.netlify.app")
        detail.font = .systemFont(ofSize: 11)
        detail.textColor = .secondaryLabelColor
        let bar = NSProgressIndicator()
        bar.isIndeterminate = true
        bar.controlSize = .regular
        bar.frame = NSRect(x: 0, y: 0, width: 328, height: 8)
        bar.startAnimation(nil)
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(detail)
        stack.addArrangedSubview(bar)
        panel.contentView = stack
        panel.center()
        panel.orderFrontRegardless()
        progressPanel = panel
        progressBar = bar
        progressDetail = detail
    }

    private static func hideDownloadProgress() {
        progressPanel?.orderOut(nil)
        progressPanel = nil
        progressBar = nil
        progressDetail = nil
    }

    private static func updateDownloadProgress(received: Int, expected: Int, version: String) {
        DispatchQueue.main.async {
            guard let bar = progressBar else { return }
            if expected > 0 {
                bar.isIndeterminate = false
                bar.maxValue = Double(expected)
                bar.doubleValue = Double(received)
                let pct = min(100, Int((Double(received) / Double(expected)) * 100))
                progressDetail?.stringValue = "\(pct)% · \(formatBytes(received)) of \(formatBytes(expected))"
            } else {
                progressDetail?.stringValue = "\(formatBytes(received)) downloaded · \(version)"
            }
        }
    }

    private static func formatBytes(_ n: Int) -> String {
        if n >= 1_048_576 { return String(format: "%.1f MB", Double(n) / 1_048_576) }
        if n >= 1024 { return String(format: "%.0f KB", Double(n) / 1024) }
        return "\(n) B"
    }

    private final class DownloadAccumulator: NSObject, URLSessionDataDelegate {
        var data = Data()
        var expectedLength = 0
        var httpStatus = 0
        var version = ""

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            if let http = response as? HTTPURLResponse { httpStatus = http.statusCode }
            expectedLength = Int(response.expectedContentLength)
            completionHandler(.allow)
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            self.data.append(data)
            UpdateInstaller.updateDownloadProgress(received: self.data.count, expected: expectedLength, version: version)
        }
    }

    private enum InstallResult {
        case success
        case failure(String)
    }

    private static func performInstall(remoteVersion: String) -> InstallResult {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory
        let manifest = fetchManifest()
        let zipName = manifest?.zipName(for: remoteVersion) ?? "rNitro-\(remoteVersion).zip"
        let zipFile = tmp.appendingPathComponent(zipName)
        let extractDir = tmp.appendingPathComponent("rNitro-update-extract", isDirectory: true)
        try? fm.removeItem(at: zipFile)
        try? fm.removeItem(at: extractDir)
        log("Resolved zip: \(zipName)")

        let sem = DispatchSemaphore(value: 0)
        var dlError: Error?
        var httpStatus = 0
        var req = URLRequest(url: zipURL(for: zipName))
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 180
        let task = URLSession.shared.downloadTask(with: req) { tempURL, resp, error in
            dlError = error
            if let http = resp as? HTTPURLResponse { httpStatus = http.statusCode }
            guard error == nil, let tempURL = tempURL else { sem.signal(); return }
            do {
                if fm.fileExists(atPath: zipFile.path) { try fm.removeItem(at: zipFile) }
                try fm.moveItem(at: tempURL, to: zipFile)
            } catch {
                dlError = error
            }
            sem.signal()
        }
        task.resume()
        sem.wait()

        if let dlError {
            log("Download error: \(dlError.localizedDescription)")
            return .failure("Could not download \(zipName): \(dlError.localizedDescription)")
        }
        if httpStatus != 0 && httpStatus != 200 {
            log("HTTP \(httpStatus) for \(zipName)")
            return .failure("Server returned HTTP \(httpStatus) for \(zipName). Download the App ZIP manually from getrnitro.netlify.app.")
        }
        guard fm.fileExists(atPath: zipFile.path) else {
            return .failure("Download did not save \(zipName). Try again or use the website.")
        }
        let size = (try? fm.attributesOfItem(atPath: zipFile.path)[.size] as? Int) ?? 0
        log("Downloaded \(zipName): \(size) bytes")
        let head = (try? Data(contentsOf: zipFile, options: [.mappedIfSafe]).prefix(64)) ?? Data()
        if head.count >= 2, head[0] == 0x3C, head[1] == 0x21 {
            return .failure("Got an HTML error page instead of the App ZIP (missing file on server). Download \(zipName) manually from getrnitro.netlify.app.")
        }
        guard head.count >= 4, head[0] == 0x50, head[1] == 0x4B else {
            return .failure("Downloaded file is not a valid ZIP archive. Try again or use the website.")
        }
        if size < 1_400_000 {
            return .failure("Downloaded package is too small (\(size) bytes). Try again or use the website.")
        }

        DispatchQueue.main.async {
            progressDetail?.stringValue = "Installing \(remoteVersion)…"
            progressBar?.isIndeterminate = true
            progressBar?.startAnimation(nil)
        }

        let extractError = extractApp(from: zipFile, to: extractDir)
        if let extractError {
            log("Extract failed: \(extractError)")
            return .failure("Could not extract \(zipName): \(extractError)")
        }
        guard let staged = findAppBundle(in: extractDir) else {
            log("rNitro.app missing after extract")
            return .failure("rNitro.app not found inside \(zipName). Download manually from getrnitro.netlify.app.")
        }

        let dest = installDestination()
        log("Installing to \(dest.path)")
        if let installError = replaceApp(stagedApp: staged, destination: dest) {
            log("Install failed: \(installError)")
            return .failure(installError)
        }
        log("Install succeeded")
        DispatchQueue.main.async {
            NSWorkspace.shared.open(dest)
            NSApp.terminate(nil)
        }
        return .success
    }

    private static func shellQuote(_ path: String) -> String {
        path.replacingOccurrences(of: "'", with: "'\\''")
    }

    private static func runCommand(_ launchPath: String, _ args: [String]) -> (Int32, String) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: launchPath)
        proc.arguments = args
        let err = Pipe()
        proc.standardError = err
        proc.standardOutput = Pipe()
        guard (try? proc.run()) != nil else { return (-1, "Could not run \(launchPath)") }
        proc.waitUntilExit()
        let msg = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (proc.terminationStatus, msg.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func extractApp(from zipURL: URL, to destDir: URL) -> String? {
        let fm = FileManager.default
        try? fm.createDirectory(at: destDir, withIntermediateDirectories: true)
        let logPath = updateLogURL.path

        func run(_ launchPath: String, _ args: [String]) -> (Int32, String) {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: launchPath)
            proc.arguments = args
            let err = Pipe()
            proc.standardError = err
            proc.standardOutput = Pipe()
            guard (try? proc.run()) != nil else { return (-1, "Could not run \(launchPath)") }
            proc.waitUntilExit()
            let msg = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return (proc.terminationStatus, msg.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let ditto = run("/usr/bin/ditto", ["-xk", zipURL.path, destDir.path])
        if ditto.0 == 0 { return nil }

        let unzip = run("/usr/bin/unzip", ["-qo", zipURL.path, "-d", destDir.path])
        if unzip.0 == 0 { return nil }

        let detail = [ditto.1, unzip.1].filter { !$0.isEmpty }.joined(separator: " | ")
        try? "ditto=\(ditto.0) unzip=\(unzip.0) \(detail)\n".write(to: URL(fileURLWithPath: logPath), atomically: true, encoding: .utf8)
        return detail.isEmpty ? "ditto and unzip both failed" : detail
    }

    private static func installDestination() -> URL {
        let current = URL(fileURLWithPath: Bundle.main.bundlePath)
        let homeApp = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications/rNitro.app", isDirectory: true)
        let path = current.path
        if path.contains("AppTranslocation") || path.hasPrefix("/Volumes/") {
            return homeApp
        }
        let parent = current.deletingLastPathComponent()
        if FileManager.default.isWritableFile(atPath: parent.path) {
            return current
        }
        return homeApp
    }

    private static func findAppBundle(in dir: URL) -> URL? {
        guard let e = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: [.isDirectoryKey]) else { return nil }
        for case let url as URL in e {
            var isDir: ObjCBool = false
            if url.lastPathComponent == "rNitro.app",
               FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                return url
            }
        }
        return nil
    }

    private static func replaceApp(stagedApp: URL, destination: URL) -> String? {
        let fm = FileManager.default
        let parent = destination.deletingLastPathComponent()
        try? fm.createDirectory(at: parent, withIntermediateDirectories: true)
        let staged = shellQuote(stagedApp.path)
        let target = shellQuote(destination.path)

        if parent.path == "/Applications" {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            proc.arguments = [
                "-e",
                "do shell script \"mkdir -p /Applications && rm -rf '\(target)' && /usr/bin/ditto '\(staged)' '\(target)' && /usr/bin/xattr -cr '\(target)'\" with administrator privileges"
            ]
            proc.standardError = Pipe()
            proc.standardOutput = Pipe()
            guard (try? proc.run()) != nil else {
                return "Could not request administrator access to update /Applications."
            }
            proc.waitUntilExit()
            if proc.terminationStatus != 0 {
                return "Could not replace rNitro in /Applications. Enter your Mac password when prompted, or download the App ZIP from getrnitro.netlify.app and drag it to Applications."
            }
            return nil
        }

        try? fm.removeItem(at: destination)
        let ditto = runCommand("/usr/bin/ditto", [stagedApp.path, destination.path])
        if ditto.0 != 0 {
            return ditto.1.isEmpty
                ? "Could not copy the update into \(parent.path). Download the App ZIP manually from getrnitro.netlify.app."
                : ditto.1
        }
        _ = runCommand("/usr/bin/xattr", ["-cr", destination.path])
        return nil
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
        "Tp0V","Tp0W","Tp0Y","Tp0z","Tp10","Tp0a","Tp0e","Tp0f","Tp0g","Tp0j",
        "Tp0k","Tp0m","Tp0n","Tp0q","Tp0r","Tp0s","Tp0u","Tp0v","Tp0w","Tp0x",
        "Te05","Te0L","Te0P","Te0S","Te0T","Te0t","Te0H","Te00",
        "Tf04","Tf09","Tf0A","Tf0B",
        "Tp1h","Tp1t","Tp1p","Tp1l","Tp1f","Tp1C","Tp1c","Tp1D",
        "TC0P","TC0H","TC0D","TC0E","TC0F","TC0C","TC0c",
        "TC1C","TC2C","TC3C","TC4C","TC5C","TC6C","TC7C","TC8C",
        "TCPU","TCGC","TACC","TH0x","TH1x","Tp00"
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
            .filter { $0 >= 20 && $0 <= 95 }
    }

    private static let fanKeys = ["F0Ac", "F1Ac", "F2Ac", "F0Mn", "F1Mn", "F0Md", "F1Md"]

    private func readUInt16BE(key: String) -> UInt16? {
        open()
        guard isOpen else { return nil }
        var infoInput = SMCParamStruct()
        infoInput.key = fourCharCode(key)
        infoInput.data8 = 9
        guard let infoOut = call(&infoInput), infoOut.result == 0 else { return nil }
        var readInput = SMCParamStruct()
        readInput.key = fourCharCode(key)
        readInput.keyInfo = infoOut.keyInfo
        readInput.data8 = 5
        guard let readOut = call(&readInput), readOut.result == 0 else { return nil }
        let b = readOut.bytes
        return UInt16(b.0) << 8 | UInt16(b.1)
    }

    func fanRPMReadings() -> [(key: String, rpm: Int)] {
        Self.fanKeys.compactMap { key in
            guard let raw = readUInt16BE(key: key), raw > 0, raw < 20_000 else { return nil }
            return (key, Int(raw))
        }
    }

    func temperatureEntries() -> [(key: String, value: Double, unit: String)] {
        Self.candidateKeys.compactMap { key in
            guard let v = readTemperature(key: key), v >= 20, v <= 115 else { return nil }
            return (key, v, "°C")
        }
    }
}

// ── IOHID die-adjacent temperature sensors (Apple Silicon, no sudo) ────────
// Complements SMC: MTR temp sensors (pACC/eACC) often track die heat better
// than package SMC keys on newer chips.
@_silgen_name("IOHIDEventSystemClientCreate")
private func IOHIDEventSystemClientCreate(_ allocator: CFAllocator?) -> UnsafeMutableRawPointer?
@_silgen_name("IOHIDEventSystemClientSetMatching")
private func IOHIDEventSystemClientSetMatching(_ client: UnsafeMutableRawPointer, _ match: CFDictionary) -> Int32
@_silgen_name("IOHIDEventSystemClientCopyServices")
private func IOHIDEventSystemClientCopyServices(_ client: UnsafeMutableRawPointer) -> Unmanaged<CFArray>?
@_silgen_name("IOHIDServiceClientCopyEvent")
private func IOHIDServiceClientCopyEvent(_ client: UnsafeRawPointer, _ type: Int64, _ flags: Int32, _ options: Int64) -> UnsafeMutableRawPointer?
@_silgen_name("IOHIDEventGetFloatValue")
private func IOHIDEventGetFloatValue(_ event: UnsafeRawPointer, _ field: Int64) -> Double

fileprivate final class IOHIDTempReader {
    static let shared = IOHIDTempReader()
    private let eventType: Int64 = 15

    func readings() -> [Double] {
        guard let client = IOHIDEventSystemClientCreate(kCFAllocatorDefault) else { return [] }
        defer { Unmanaged<CFTypeRef>.fromOpaque(client).release() }

        let match = [
            "PrimaryUsagePage": 0xff00,
            "PrimaryUsage": 0x0005
        ] as CFDictionary
        guard IOHIDEventSystemClientSetMatching(client, match) == 0,
              let services = IOHIDEventSystemClientCopyServices(client)?.takeRetainedValue() else { return [] }

        let count = CFArrayGetCount(services)
        var temps: [Double] = []
        let field = eventType << 16
        for i in 0..<count {
            guard let ptr = CFArrayGetValueAtIndex(services, i) else { continue }
            guard let event = IOHIDServiceClientCopyEvent(ptr, eventType, 0, 0) else { continue }
            let t = IOHIDEventGetFloatValue(event, field)
            Unmanaged<CFTypeRef>.fromOpaque(event).release()
            if t >= 20, t <= 95 { temps.append(t) }
        }
        return temps
    }
}

// ── Real CPU package power via IOReport (Apple Silicon, no sudo) ────────────
// Same private IOReport energy counters powermetrics reads — exposed through
// libIOReport. We delta "Energy Model" CPU channels (e.g. "CPU Energy",
// "DIE_0_CPU Energy" on Ultra) and convert mJ/uJ/nJ → Watts.
@_silgen_name("IOReportCopyAllChannels")
private func IOReportCopyAllChannels(_ a: UInt64, _ b: UInt64) -> Unmanaged<CFDictionary>?
@_silgen_name("IOReportChannelGetGroup")
private func IOReportChannelGetGroup(_ item: CFDictionary) -> Unmanaged<CFString>?
@_silgen_name("IOReportChannelGetChannelName")
private func IOReportChannelGetChannelName(_ item: CFDictionary) -> Unmanaged<CFString>?
@_silgen_name("IOReportChannelGetUnitLabel")
private func IOReportChannelGetUnitLabel(_ item: CFDictionary) -> Unmanaged<CFString>?
@_silgen_name("IOReportCreateSubscription")
private func IOReportCreateSubscription(_ a: UnsafeRawPointer?, _ b: CFMutableDictionary,
                                        _ out: UnsafeMutablePointer<CFMutableDictionary?>,
                                        _ flags: UInt64, _ opts: UnsafeRawPointer?) -> UnsafeMutableRawPointer?
@_silgen_name("IOReportCreateSamples")
private func IOReportCreateSamples(_ sub: UnsafeMutableRawPointer, _ chan: CFMutableDictionary,
                                   _ opts: UnsafeRawPointer?) -> Unmanaged<CFDictionary>?
@_silgen_name("IOReportCreateSamplesDelta")
private func IOReportCreateSamplesDelta(_ a: CFDictionary, _ b: CFDictionary,
                                        _ opts: UnsafeRawPointer?) -> Unmanaged<CFDictionary>?
@_silgen_name("IOReportSimpleGetIntegerValue")
private func IOReportSimpleGetIntegerValue(_ item: CFDictionary, _ index: Int32) -> Int64

struct SocPowerSample {
    var cpuWatts: Double = 0
    var gpuWatts: Double = 0
    var aneWatts: Double = 0
    var hasData: Bool { cpuWatts > 0 || gpuWatts > 0 || aneWatts > 0 }
    var totalWatts: Double { cpuWatts + gpuWatts + aneWatts }
}

fileprivate final class IOReportPowerReader {
    static let shared = IOReportPowerReader()

    private enum ChannelKind { case cpu, gpu, ane }

    private struct ChannelMeta { let kind: ChannelKind; let unit: String }

    private let queue = DispatchQueue(label: "rnitro.ioreport", qos: .utility)
    private(set) var isAvailable = false
    /// Retains IOReportCopyAllChannels output — channel entries in sampleChannels point into this.
    private var allChannels: CFDictionary?
    private var subscription: UnsafeMutableRawPointer?
    private var sampleChannels: CFMutableDictionary?
    private var channels: [ChannelMeta] = []
    private var prevSample: Unmanaged<CFDictionary>?
    private var prevTime: CFAbsoluteTime = 0
    private var permanentlyDisabled = false

    private init() { setup() }

    deinit {
        prevSample?.release()
        if let ch = sampleChannels { Unmanaged.passUnretained(ch).release() }
        if let sub = subscription { Unmanaged<CFTypeRef>.fromOpaque(sub).release() }
    }

    private func cfStr(_ ref: Unmanaged<CFString>?) -> String {
        guard let ref else { return "" }
        return ref.takeUnretainedValue() as String
    }

    private func energyDeltaToWatts(_ delta: Double, unit: String, durationMs: Double) -> Double {
        let joules: Double
        switch unit {
        case "mJ": joules = delta / 1e3
        case "uJ": joules = delta / 1e6
        case "nJ": joules = delta / 1e9
        default: return 0
        }
        return joules / max(durationMs / 1000.0, 0.001)
    }

    private func deltaChannelItems(_ delta: CFDictionary) -> [CFDictionary] {
        let key = "IOReportChannels" as CFString
        guard let ptr = CFDictionaryGetValue(delta, Unmanaged.passUnretained(key).toOpaque()) else { return [] }
        let arr = unsafeBitCast(ptr, to: CFArray.self)
        let n = CFArrayGetCount(arr)
        return (0..<n).map { i in
            unsafeBitCast(CFArrayGetValueAtIndex(arr, i)!, to: CFDictionary.self)
        }
    }

    private func channelKind(group: String, channel: String) -> ChannelKind? {
        guard group == "Energy Model" else { return nil }
        if channel.hasSuffix("CPU Energy") { return .cpu }
        if channel == "GPU Energy" { return .gpu }
        if channel.hasPrefix("ANE") { return .ane }
        return nil
    }

    private func disablePermanently() {
        permanentlyDisabled = true
        isAvailable = false
    }

    private func setup() {
        guard let allRaw = IOReportCopyAllChannels(0, 0)?.takeRetainedValue() else { return }

        let channelsKey = "IOReportChannels" as CFString
        guard let itemsPtr = CFDictionaryGetValue(allRaw, Unmanaged.passUnretained(channelsKey).toOpaque()) else { return }
        let allItems = unsafeBitCast(itemsPtr, to: CFArray.self)
        let itemCount = CFArrayGetCount(allItems)

        guard let selected = CFArrayCreateMutable(kCFAllocatorDefault, 0, nil) else { return }
        var metas: [ChannelMeta] = []

        for i in 0..<itemCount {
            let itemPtr = CFArrayGetValueAtIndex(allItems, i)!
            let item = unsafeBitCast(itemPtr, to: CFDictionary.self)
            let group = cfStr(IOReportChannelGetGroup(item))
            let channel = cfStr(IOReportChannelGetChannelName(item))
            guard let kind = channelKind(group: group, channel: channel) else { continue }
            CFArrayAppendValue(selected, itemPtr)
            let unit = cfStr(IOReportChannelGetUnitLabel(item)).trimmingCharacters(in: .whitespaces)
            metas.append(ChannelMeta(kind: kind, unit: unit))
        }
        guard !metas.isEmpty else { return }

        guard let chan = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, allRaw) else { return }
        CFDictionarySetValue(chan, Unmanaged.passUnretained(channelsKey).toOpaque(),
                             Unmanaged.passUnretained(selected).toOpaque())

        var subInfo: CFMutableDictionary?
        guard let sub = IOReportCreateSubscription(nil, chan, &subInfo, 0, nil) else { return }

        allChannels = allRaw
        subscription = sub
        sampleChannels = chan
        channels = metas
        isAvailable = true
    }

    func sample() -> SocPowerSample? {
        guard isAvailable, !permanentlyDisabled else { return nil }
        return queue.sync { sampleUnsafe() }
    }

    private func sampleUnsafe() -> SocPowerSample? {
        guard let sub = subscription, let chan = sampleChannels else { return nil }
        guard let sample = IOReportCreateSamples(sub, chan, nil)?.takeRetainedValue() else {
            disablePermanently()
            return nil
        }
        let now = CFAbsoluteTimeGetCurrent()

        guard let prevBox = prevSample else {
            prevSample = Unmanaged.passRetained(sample)
            prevTime = now
            return nil
        }

        let prev = prevBox.takeUnretainedValue()
        let elapsedMs = (now - prevTime) * 1000.0
        var result: SocPowerSample? = nil

        if elapsedMs >= 200, elapsedMs <= 10_000,
           let deltaRaw = IOReportCreateSamplesDelta(prev, sample, nil)?.takeRetainedValue() {
            let deltaItems = deltaChannelItems(deltaRaw)
            var out = SocPowerSample()
            for (j, item) in deltaItems.enumerated() where j < channels.count {
                let val = Double(IOReportSimpleGetIntegerValue(item, 0))
                let w = energyDeltaToWatts(val, unit: channels[j].unit, durationMs: elapsedMs)
                guard w > 0, w < 500 else { continue }
                switch channels[j].kind {
                case .cpu: out.cpuWatts += w
                case .gpu: out.gpuWatts += w
                case .ane: out.aneWatts += w
                }
            }
            if out.hasData { result = out }
        }

        prevBox.release()
        prevSample = Unmanaged.passRetained(sample)
        prevTime = now
        return result
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
    @Published var packagePowerWatts: Double = 0
    @Published var gpuPowerWatts: Double = 0
    @Published var anePowerWatts: Double = 0
    @Published var socPowerWatts: Double = 0
    @Published var packagePowerSource: String = "Load estimate"
    @Published var powerHistory: [Double] = Array(repeating: 0, count: 80) // ~60s at 750ms/tick
    @Published var loadAverage1: Double = 0
    @Published var loadAverage5: Double = 0
    @Published var loadAverage15: Double = 0
    @Published var systemUptime: TimeInterval = 0
    @Published var memoryWiredGB: Double = 0
    @Published var memoryCompressedGB: Double = 0
    @Published var memorySwapGB: Double = 0
    @Published var memoryPressure: String = "Normal"
    @Published var memoryHistory: [Double] = Array(repeating: 0, count: 80)
    @Published var efficiencyCoreCount: Int = 0
    @Published var isLowPowerModeEnabled: Bool = false

    private var smoothedUsage: Double = 0
    private var smoothedTemperature: Double = 0
    private var hasSmoothedSamples = false

    static func chipPowerCeiling(_ name: String) -> Double {
        let n = name.lowercased()
        if n.contains("ultra") { return 60 }
        if n.contains("max") { return 40 }
        if n.contains("pro") { return 30 }
        return 22
    }

    static func readLowPowerModeEnabled() -> Bool {
        if #available(macOS 12.0, *) {
            return ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        return false
    }

    static func estimatePackagePowerWatts(usage: Double, baseClock: Double, boostClock: Double,
                                          cpuName: String, thermal: ProcessInfo.ThermalState,
                                          lowPowerMode: Bool = false) -> Double {
        let idle = 3.0
        let ceiling = chipPowerCeiling(cpuName)
        let load = max(0, min(100, usage)) / 100.0
        let clockScale = baseClock > 0 ? min(1.18, boostClock / baseClock) : 1.0
        var watts = idle + (ceiling - idle) * load * clockScale
        switch thermal {
        case .fair: watts *= 1.04
        case .serious: watts *= 1.08
        case .critical: watts *= 1.12
        default: break
        }
        if lowPowerMode { watts *= 0.82 }
        return max(idle, watts)
    }

    // Apple Silicon doesn't expose a public per-core °C sensor API, but
    // ProcessInfo.thermalState reflects the real thermal pressure macOS is
    // tracking system-wide. We map its 4 discrete states to a *range* rather
    // than a single flat number, and interpolate within that range using
    // live CPU usage so the gauge moves continuously instead of sitting on
    // one fixed value (e.g. always reading 40 while thermalState == .nominal).
    static func thermalDisplayValue(_ state: ProcessInfo.ThermalState, usage: Double) -> Double {
        let u = max(0, min(100, usage)) / 100.0
        switch state {
        case .nominal:  return 38 + 42 * u   // 38–80°C
        case .fair:     return 48 + 38 * u   // 48–86°C
        case .serious:  return 58 + 30 * u   // 58–88°C
        case .critical: return 68 + 22 * u   // 68–90°C
        @unknown default: return 38 + 42 * u
        }
    }

    private static func plausibleSensorTemps(_ readings: [Double]) -> [Double] {
        readings.filter { $0 >= 20 && $0 <= 95 }
    }

    // Prefer a robust sensor cluster; never let a single bogus/stuck key peg the UI at 105°C.
    static func resolveTemperature(state: ProcessInfo.ThermalState, usage: Double, smcReadings: [Double]) -> (temp: Double, source: String) {
        let estimate = thermalDisplayValue(state, usage: usage)
        let plausible = plausibleSensorTemps(smcReadings)
        guard !plausible.isEmpty else {
            return (estimate, "macOS thermalState + load estimate")
        }

        let sorted = plausible.sorted()
        let sensor = sorted[sorted.count / 2] // median — resists one hot garbage key

        // Stuck/high sensor under light load → trust load estimate instead.
        if sensor >= 88 && usage < 35 && state == .nominal {
            return (estimate, "Load estimate (sensor \(Int(sensor.rounded()))°C ignored — light load)")
        }
        if sensor >= 95 && usage < 55 {
            return (max(estimate, sensor * 0.65), "Blended (capped hot sensor \(Int(sensor.rounded()))°C)")
        }
        if sensor < 62 && usage > 25 {
            return (max(sensor, estimate), "Blended (\(plausible.count) sensors + load)")
        }
        return (sensor, "Sensor median (\(plausible.count) sensors)")
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

    private func cpuTickDelta(_ current: integer_t, _ previous: integer_t) -> UInt64 {
        let cur = UInt32(bitPattern: Int32(truncatingIfNeeded: current))
        let prev = UInt32(bitPattern: Int32(truncatingIfNeeded: previous))
        return UInt64(cur &- prev)
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
        var ec: Int32 = 0
        if sysctlbyname("hw.perflevel0.physicalcpu", &ec, &isz, nil, 0) == 0, ec > 0 {
            efficiencyCoreCount = Int(ec)
        } else {
            efficiencyCoreCount = max(1, physicalCores / 2)
        }
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

    private var pollInterval: TimeInterval = MonitorActivity.cpuInterval

    func startMonitoring() {
        stopMonitoring()
        pollInterval = MonitorActivity.cpuInterval
        let t = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in self?.update() }
        RunLoop.main.add(t, forMode: .common)
        t.fire()
        timer = t
    }

    func setPollInterval(_ interval: TimeInterval) {
        guard interval > 0, abs(pollInterval - interval) > 0.01 else { return }
        pollInterval = interval
        startMonitoring()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func update() {
        let cpu = updateCPUUsage()
        updateMemory()
        updateDisk()
        updateSystemStats()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let cpu { self.applyCPUUsage(cpu) }
            self.updateDerived()
        }
    }

    private func updateSystemStats() {
        var load = loadavg()
        var loadSize = MemoryLayout<loadavg>.size
        if sysctlbyname("vm.loadavg", &load, &loadSize, nil, 0) == 0, load.fscale > 0 {
            let scale = Double(load.fscale)
            let la1 = Double(load.ldavg.0) / scale
            let la5 = Double(load.ldavg.1) / scale
            let la15 = Double(load.ldavg.2) / scale
            DispatchQueue.main.async { [weak self] in
                self?.loadAverage1 = la1
                self?.loadAverage5 = la5
                self?.loadAverage15 = la15
                self?.systemUptime = ProcessInfo.processInfo.systemUptime
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.systemUptime = ProcessInfo.processInfo.systemUptime
            }
        }
    }

    static func formatUptime(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        let d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60
        if d > 0 { return String(format: "%dd %dh %dm", d, h, m) }
        if h > 0 { return String(format: "%dh %dm", h, m) }
        return String(format: "%dm", m)
    }

    private func applyCPUUsage(_ sample: (avg: Double, perCore: [Double])) {
        let alpha = 0.35
        if hasSmoothedSamples {
            smoothedUsage = smoothedUsage * (1 - alpha) + sample.avg * alpha
        } else {
            smoothedUsage = sample.avg
            hasSmoothedSamples = true
        }
        totalUsage = min(100, max(0, smoothedUsage))
        usageHistory.removeFirst()
        usageHistory.append(totalUsage)
        for (i, u) in sample.perCore.enumerated() where i < cores.count {
            cores[i].usage = u
        }
    }

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
        let wiredGB = (Double(stats.wire_count) * pageSize) / 1_073_741_824
        let compressedGB = (Double(stats.compressor_page_count) * pageSize) / 1_073_741_824
        let usedPages = Double(stats.active_count + stats.wire_count + stats.compressor_page_count)
        let freePages = Double(stats.free_count + stats.inactive_count)
        let usedGB = (usedPages * pageSize) / 1_073_741_824
        let freeGB = (freePages * pageSize) / 1_073_741_824
        let usedPct = totalGB > 0 ? min(100, usedGB / totalGB * 100) : 0
        var swapUsedGB: Double = 0
        var swap = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        if sysctlbyname("vm.swapusage", &swap, &swapSize, nil, 0) == 0 {
            swapUsedGB = Double(swap.xsu_used) / 1_073_741_824
        }
        let pressure: String
        if usedPct >= 92 || freeGB < 0.5 { pressure = "Critical" }
        else if usedPct >= 82 || compressedGB > totalGB * 0.25 { pressure = "Warning" }
        else { pressure = "Normal" }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.memoryTotalGB = totalGB
            self.memoryUsedGB = usedGB
            self.memoryFreeGB = freeGB
            self.memoryUsedPercent = usedPct
            self.memoryWiredGB = wiredGB
            self.memoryCompressedGB = compressedGB
            self.memorySwapGB = swapUsedGB
            self.memoryPressure = pressure
            self.memoryHistory.removeFirst()
            self.memoryHistory.append(usedPct)
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

    private func updateCPUUsage() -> (avg: Double, perCore: [Double])? {
        var n: natural_t = 0
        var info: processor_info_array_t?
        var num: mach_msg_type_number_t = 0
        guard host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &n, &info, &num) == KERN_SUCCESS,
              let info = info else { return nil }

        let coreCount = Int(n)
        let expectedInts = coreCount * Int(CPU_STATE_MAX)
        var computed: [Double]? = nil

        if let prev = prevCPUInfo, prevNumCPUInfo == num, expectedInts > 0 {
            var coresUsage: [Double] = []
            coresUsage.reserveCapacity(coreCount)
            for i in 0..<coreCount {
                let b = Int(CPU_STATE_MAX) * i
                let u = cpuTickDelta(info[b + Int(CPU_STATE_USER)], prev[b + Int(CPU_STATE_USER)])
                let s = cpuTickDelta(info[b + Int(CPU_STATE_SYSTEM)], prev[b + Int(CPU_STATE_SYSTEM)])
                let ni = cpuTickDelta(info[b + Int(CPU_STATE_NICE)], prev[b + Int(CPU_STATE_NICE)])
                let id = cpuTickDelta(info[b + Int(CPU_STATE_IDLE)], prev[b + Int(CPU_STATE_IDLE)])
                let busy = u + s + ni
                let t = busy + id
                coresUsage.append(t > 0 ? max(0, min(100, Double(busy) / Double(t) * 100)) : 0)
            }
            computed = coresUsage
            deallocateCPUInfo(prev, count: prevNumCPUInfo)
        }

        prevCPUInfo = info
        prevNumCPUInfo = num
        guard let computed, !computed.isEmpty else { return nil }

        let avg = computed.reduce(0, +) / Double(computed.count)
        return (min(100, max(0, avg)), computed)
    }

    private func updateDerived() {
        // Prefer a real SMC sensor reading (see SMCReader above); only fall
        // back to the thermalState-based estimate if the SMC can't be
        // reached or no known key resolves on this machine.
        let state = ProcessInfo.processInfo.thermalState
        let lpm = Self.readLowPowerModeEnabled()
        let usage = totalUsage
        let sensorReadings = SMCReader.shared.smcReadings() + IOHIDTempReader.shared.readings()
        let resolved = CPUMonitor.resolveTemperature(state: state, usage: usage, smcReadings: sensorReadings)
        let tempAlpha = 0.3
        let nextTemp: Double
        if hasSmoothedSamples {
            nextTemp = smoothedTemperature * (1 - tempAlpha) + resolved.temp * tempAlpha
        } else {
            nextTemp = resolved.temp
        }
        smoothedTemperature = min(95, max(20, nextTemp))
        let boost = baseClock + (baseClock * 0.28) * (usage / 100.0)
        let estimate = Self.estimatePackagePowerWatts(
            usage: usage, baseClock: baseClock, boostClock: boost,
            cpuName: cpuName, thermal: state, lowPowerMode: lpm
        )
        let ceiling = Self.chipPowerCeiling(cpuName) * 1.15
        let socSample = MonitorActivity.includePowerSample ? IOReportPowerReader.shared.sample() : nil
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isLowPowerModeEnabled = lpm
            self.thermalState = state
            self.tempSource = resolved.source
            self.smcSensorCount = sensorReadings.count
            self.temperature = self.smoothedTemperature; self.boostClock = boost
            if let socSample {
                self.packagePowerWatts = min(socSample.cpuWatts, ceiling)
                self.gpuPowerWatts = min(socSample.gpuWatts, 120)
                self.anePowerWatts = min(socSample.aneWatts, 60)
                self.socPowerWatts = min(socSample.totalWatts, ceiling + 80)
                self.packagePowerSource = "Apple IOReport (measured)"
            } else {
                self.packagePowerWatts = min(estimate, ceiling)
                self.gpuPowerWatts = 0
                self.anePowerWatts = 0
                self.socPowerWatts = min(estimate, ceiling)
                self.packagePowerSource = "Load estimate"
            }
            self.powerHistory.removeFirst()
            self.powerHistory.append(self.packagePowerWatts)
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
    @Published var isOnAC = false
    @Published var isFullyCharged = false
    @Published var chargeWatts: Double = 0
    @Published var chargeRateText = "…"
    @Published var powerSource = "Unknown"
    @Published var timeToFullMinutes: Int?
    @Published var timeRemainingMinutes: Int?
    @Published var cycleCount: Int?
    @Published var temperatureCelsius: Double?
    @Published var healthPercent: Int?
    @Published var history12h: [Double] = []
    @Published var powerStateSince = Date()

    var remainingTimeText: String? {
        guard isPresent, !isOnAC, !isCharging,
              let m = timeRemainingMinutes, m > 0, m < 65535 else { return nil }
        if m >= 60 { return String(format: "%dh %dm", m / 60, m % 60) }
        return "\(m) min"
    }

    var timeLeftDisplay: String {
        guard isPresent else { return "N/A" }
        if isCharging {
            if let eta = timeToFullMinutes, eta > 0, eta < 65535 {
                if eta >= 60 { return String(format: "%d hr, %d min", eta / 60, eta % 60) }
                return "\(eta) min"
            }
            return "Calculating..."
        }
        if let rem = remainingTimeText { return rem }
        return isOnAC ? "On AC power" : "Calculating..."
    }

    var elapsedTimeText: String {
        let mins = max(0, Int(Date().timeIntervalSince(powerStateSince) / 60))
        if mins >= 60 { return String(format: "%d hr, %d min", mins / 60, mins % 60) }
        return "\(mins) min"
    }

    var appModeText: String {
        guard isPresent else { return "No battery" }
        if isCharging { return "Charging" }
        if isFullyCharged { return "Fully Charged" }
        if isOnAC { return "Charger connected" }
        return "Discharging"
    }

    private var timer: Timer?
    private var prevLevel: Int?
    private var prevSampleTime: Date?
    private var historyPoints: [(Date, Int)] = []
    private var lastHistorySample: Date?
    private var lastModeKey = ""

    private struct Snapshot {
        var isPresent = false
        var levelPercent = 0
        var isCharging = false
        var isOnAC = false
        var isFullyCharged = false
        var chargeWatts: Double = 0
        var chargeRateText = "…"
        var powerSource = "Unknown"
        var timeToFullMinutes: Int?
        var timeRemainingMinutes: Int?
        var cycleCount: Int?
        var temperatureCelsius: Double?
        var healthPercent: Int?
    }

    init() {
        applyActivityInterval()
    }

    func applyActivityInterval() {
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: MonitorActivity.batteryInterval, repeats: true) { [weak self] _ in self?.poll() }
        RunLoop.main.add(t, forMode: .common)
        t.fire()
        timer = t
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            var snap = Self.readPmset() ?? Snapshot()
            if let hw = Self.readIoreg() {
                if snap.isPresent {
                    snap.isOnAC = hw.isOnAC
                    snap.isCharging = hw.hasChargingSignal ? hw.isCharging : snap.isCharging
                    if hw.adapterWatts > 0 { snap.chargeWatts = hw.adapterWatts }
                    if hw.chargeWatts > 0 && snap.isCharging { snap.chargeWatts = hw.chargeWatts }
                    if snap.isCharging, snap.timeToFullMinutes == nil, let eta = hw.timeToFullMinutes { snap.timeToFullMinutes = eta }
                    if !snap.isCharging, snap.timeRemainingMinutes == nil, let rem = hw.timeRemainingMinutes { snap.timeRemainingMinutes = rem }
                    Self.applyIoregExtras(hw, to: &snap)
                } else if hw.levelPercent > 0 {
                    snap.isPresent = true
                    snap.levelPercent = hw.levelPercent
                    snap.isOnAC = hw.isOnAC
                    snap.isCharging = hw.isCharging
                    snap.isFullyCharged = hw.levelPercent >= 100 && !snap.isCharging
                    snap.chargeWatts = hw.chargeWatts > 0 ? hw.chargeWatts : hw.adapterWatts
                    snap.timeToFullMinutes = hw.timeToFullMinutes
                    snap.timeRemainingMinutes = hw.timeRemainingMinutes
                    Self.applyIoregExtras(hw, to: &snap)
                }
            }
            if snap.isPresent {
                snap.powerSource = snap.isOnAC ? "AC Power" : "Battery Power"
                if snap.isCharging && snap.chargeWatts > 0 {
                    snap.chargeRateText = String(format: "%.0f W", snap.chargeWatts)
                } else if snap.isCharging, let eta = snap.timeToFullMinutes, eta > 0, eta < 65535 {
                    snap.chargeRateText = String(format: "%d min", eta)
                } else if snap.isCharging {
                    snap.chargeRateText = "Charging"
                } else if snap.isFullyCharged || (snap.isOnAC && snap.levelPercent >= 100) {
                    snap.chargeRateText = "Full"
                    snap.isFullyCharged = true
                } else if snap.isOnAC {
                    snap.chargeRateText = "Plugged in"
                } else {
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
                let modeKey = "\(snap.isCharging)-\(snap.isOnAC)-\(snap.isFullyCharged)"
                if modeKey != self.lastModeKey {
                    self.powerStateSince = Date()
                    self.lastModeKey = modeKey
                }
                if snap.isPresent {
                    let now = Date()
                    if self.historyPoints.isEmpty || now.timeIntervalSince(self.lastHistorySample ?? .distantPast) >= 300 {
                        self.historyPoints.append((now, snap.levelPercent))
                        self.lastHistorySample = now
                    } else if !self.historyPoints.isEmpty {
                        self.historyPoints[self.historyPoints.count - 1] = (now, snap.levelPercent)
                    }
                    let cutoff = now.addingTimeInterval(-12 * 3600)
                    self.historyPoints.removeAll { $0.0 < cutoff }
                    self.history12h = self.historyPoints.map { Double($0.1) }
                }
                self.isPresent = snap.isPresent
                self.levelPercent = snap.levelPercent
                self.isCharging = snap.isCharging
                self.isOnAC = snap.isOnAC
                self.isFullyCharged = snap.isFullyCharged
                self.chargeWatts = snap.chargeWatts
                self.chargeRateText = snap.chargeRateText
                self.powerSource = snap.powerSource
                self.timeToFullMinutes = snap.timeToFullMinutes
                self.timeRemainingMinutes = snap.timeRemainingMinutes
                self.cycleCount = snap.cycleCount
                self.temperatureCelsius = snap.temperatureCelsius
                self.healthPercent = snap.healthPercent
            }
        }
    }

    private static func parseRemainingMinutes(from line: String) -> Int? {
        guard let timeR = line.range(of: #"(\d+):(\d+)\s+remaining"#, options: .regularExpression) else { return nil }
        let chunk = String(line[timeR])
        let parts = chunk.components(separatedBy: ":")
        guard parts.count >= 2 else { return nil }
        let hrs = Int(parts[0]) ?? 0
        let mins = Int(parts[1].prefix(while: { $0.isNumber })) ?? 0
        let total = hrs * 60 + mins
        return total > 0 ? total : nil
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
            if lower.contains("discharging") {
                snap.isCharging = false
                snap.isOnAC = false
            } else if lower.contains("not charging") {
                snap.isCharging = false
                snap.isOnAC = true
            } else if lower.contains("charging") {
                snap.isCharging = true
                snap.isOnAC = true
            } else if lower.contains("charged") || lower.contains("ac attached") {
                snap.isCharging = false
                snap.isOnAC = true
            } else {
                snap.isCharging = false
            }
            snap.isFullyCharged = lower.contains("charged") || (!snap.isCharging && snap.isOnAC && snap.levelPercent >= 100)
            if snap.isCharging {
                snap.timeToFullMinutes = parseRemainingMinutes(from: line)
            } else if lower.contains("discharging") {
                snap.timeRemainingMinutes = parseRemainingMinutes(from: line)
            }
            snap.powerSource = snap.isOnAC ? "AC Power" : "Battery Power"
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
        var isOnAC = false
        var hasChargingSignal = false
        var adapterWatts: Double = 0
        var chargeWatts: Double = 0
        var timeToFullMinutes: Int?
        var timeRemainingMinutes: Int?
        var cycleCount: Int?
        var temperatureCelsius: Double?
        var healthPercent: Int?
    }

    private static func readIoreg() -> IoregBattery? {
        guard let out = runTool("/usr/sbin/ioreg", ["-rn", "AppleSmartBattery", "-c", "AppleSmartBattery"]) else { return nil }
        var info = IoregBattery()
        if let soc = matchInt(#"StateOfCharge"=\s*(\d+)"#, in: out) ?? matchInt(#"CurrentCapacity"=\s*(\d+)"#, in: out) {
            info.levelPercent = min(100, soc)
        }
        info.isOnAC = out.contains("\"ExternalConnected\" = Yes") || out.contains("\"AppleRawExternalConnected\" = Yes")
        if out.contains("\"IsCharging\" = Yes") {
            info.isCharging = true
            info.hasChargingSignal = true
        } else if out.contains("\"IsCharging\" = No") {
            info.isCharging = false
            info.hasChargingSignal = true
        }
        if let w = matchInt(#"\"Watts\"=(\d+)"#, in: out) { info.adapterWatts = Double(w) }
        if let cc = matchInt(#"ChargingCurrent"=(\d+)"#, in: out),
           let mv = matchInt(#"AppleRawBatteryVoltage"=(\d+)"#, in: out), cc > 0 {
            info.chargeWatts = Double(cc) / 1000.0 * Double(mv) / 1000.0
            info.isCharging = true
            info.hasChargingSignal = true
        } else if let ma = matchInt(#"\"Amperage\"=(\d+)"#, in: out), ma > 0 {
            info.chargeWatts = Double(ma) / 1000.0 * 12.0
        }
        if let avg = matchInt(#"AvgTimeToFull"=\s*(\d+)"#, in: out), avg < 65535 { info.timeToFullMinutes = avg }
        else if let tr = matchInt(#"TimeRemaining"=\s*(\d+)"#, in: out), info.isCharging, tr < 65535 { info.timeToFullMinutes = tr }
        if !info.isCharging {
            if let empty = matchInt(#"AvgTimeToEmpty"=\s*(\d+)"#, in: out), empty < 65535 { info.timeRemainingMinutes = empty }
            else if let tr = matchInt(#"TimeRemaining"=\s*(\d+)"#, in: out), tr < 65535 { info.timeRemainingMinutes = tr }
        }
        info.cycleCount = matchInt(#"CycleCount"=\s*(\d+)"#, in: out)
        if let raw = matchInt(#"Temperature"=\s*(\d+)"#, in: out) ?? matchInt(#"AppleRawBatteryTemperature"=\s*(\d+)"#, in: out) {
            info.temperatureCelsius = raw > 200 ? Double(raw) / 100.0 : Double(raw)
        }
        if let maxCap = matchInt(#"MaxCapacity"=\s*(\d+)"#, in: out),
           let design = matchInt(#"DesignCapacity"=\s*(\d+)"#, in: out), design > 0, maxCap > 0 {
            info.healthPercent = min(100, Int(Double(maxCap) / Double(design) * 100.0))
        }
        return info.levelPercent > 0 || info.isOnAC || info.adapterWatts > 0 ? info : nil
    }

    private static func applyIoregExtras(_ hw: IoregBattery, to snap: inout Snapshot) {
        if let c = hw.cycleCount { snap.cycleCount = c }
        if let t = hw.temperatureCelsius { snap.temperatureCelsius = t }
        if let h = hw.healthPercent { snap.healthPercent = h }
    }

    private static func matchInt(_ pattern: String, in text: String) -> Int? {
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              m.numberOfRanges > 1,
              let r = Range(m.range(at: 1), in: text) else { return nil }
        return Int(text[r])
    }
}

// ── Network monitor (active interface + live throughput) ─────────────────────
// Samples byte counters from the default-route interface via getifaddrs every
// 1.5s. Upload/download rates are derived from counter deltas (bits per second).
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var interfaceName = "—"
    @Published var downloadMbps: Double = 0
    @Published var uploadMbps: Double = 0
    @Published var isAvailable = false
    @Published var localIP = "—"
    @Published var wifiSSID = ""
    @Published var downloadHistory: [Double] = Array(repeating: 0, count: 60)
    @Published var uploadHistory: [Double] = Array(repeating: 0, count: 60)

    private var timer: Timer?
    private var lastDown: UInt64 = 0
    private var lastUp: UInt64 = 0
    private var lastSample: Date?
    private let queue = DispatchQueue(label: "rnitro.network", qos: .utility)

    func start() {
        applyActivityInterval()
    }

    func applyActivityInterval() {
        stop()
        queue.async { [weak self] in self?.sample() }
        let t = Timer.scheduledTimer(withTimeInterval: MonitorActivity.networkInterval, repeats: true) { [weak self] _ in
            self?.queue.async { self?.sample() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    static func formatSpeed(_ mbps: Double) -> String {
        if mbps >= 1000 { return String(format: "%.1f Gbps", mbps / 1000) }
        if mbps >= 100 { return String(format: "%.0f Mbps", mbps) }
        if mbps >= 10 { return String(format: "%.1f Mbps", mbps) }
        if mbps >= 0.01 { return String(format: "%.2f Mbps", mbps) }
        return "0 Mbps"
    }

    private func sample() {
        guard let iface = Self.activeInterface() else {
            DispatchQueue.main.async {
                self.interfaceName = "—"
                self.downloadMbps = 0
                self.uploadMbps = 0
                self.isAvailable = false
            }
            lastSample = nil
            return
        }
        let (down, up) = Self.byteCounters(for: iface)
        let now = Date()
        var downMbps: Double = 0
        var upMbps: Double = 0
        if let prev = lastSample {
            let dt = now.timeIntervalSince(prev)
            if dt > 0.2 {
                let downDelta = down >= lastDown ? down - lastDown : 0
                let upDelta = up >= lastUp ? up - lastUp : 0
                downMbps = Double(downDelta) * 8.0 / dt / 1_000_000.0
                upMbps = Double(upDelta) * 8.0 / dt / 1_000_000.0
            }
        }
        lastDown = down
        lastUp = up
        lastSample = now
        let ip = Self.localIPv4(for: iface)
        let ssid = Self.wifiNetworkName(for: iface)
        DispatchQueue.main.async {
            self.interfaceName = iface
            self.downloadMbps = downMbps
            self.uploadMbps = upMbps
            self.isAvailable = true
            self.localIP = ip ?? "—"
            self.wifiSSID = ssid ?? ""
            self.downloadHistory.removeFirst()
            self.downloadHistory.append(downMbps)
            self.uploadHistory.removeFirst()
            self.uploadHistory.append(upMbps)
        }
    }

    private static func localIPv4(for iface: String) -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let p = ptr {
            let ifa = p.pointee
            if let cName = ifa.ifa_name, String(cString: cName) == iface,
               ifa.ifa_addr?.pointee.sa_family == UInt8(AF_INET) {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(ifa.ifa_addr, socklen_t(ifa.ifa_addr.pointee.sa_len),
                               &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let ip = String(cString: host)
                    if !ip.hasPrefix("127.") { return ip }
                }
            }
            ptr = ifa.ifa_next
        }
        return nil
    }

    private static func wifiNetworkName(for iface: String) -> String? {
        guard iface.hasPrefix("en") else { return nil }
        if let out = runTool("/usr/sbin/networksetup", ["-getairportnetwork", iface]) {
            let t = out.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.contains(":") {
                let name = t.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !name.isEmpty, !name.localizedCaseInsensitiveContains("not associated") { return name }
            }
        }
        return nil
    }

    private static func activeInterface() -> String? {
        if let out = runTool("/sbin/route", ["-n", "get", "default"]) {
            for line in out.components(separatedBy: "\n") {
                let t = line.trimmingCharacters(in: .whitespaces)
                if t.hasPrefix("interface:") {
                    let name = String(t.dropFirst("interface:".count).trimmingCharacters(in: .whitespaces))
                    if isUsableInterface(name) { return name }
                }
            }
        }
        for fallback in ["en0", "en1", "en2"] where isUsableInterface(fallback) {
            let (down, up) = byteCounters(for: fallback)
            if down > 0 || up > 0 { return fallback }
        }
        return nil
    }

    private static func isUsableInterface(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        let lower = name.lowercased()
        if lower == "lo0" || lower.hasPrefix("utun") || lower.hasPrefix("awdl") || lower.hasPrefix("bridge") {
            return false
        }
        return true
    }

    private static func byteCounters(for name: String) -> (UInt64, UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let p = ptr {
            let ifa = p.pointee
            if let cName = ifa.ifa_name,
               String(cString: cName) == name,
               ifa.ifa_addr?.pointee.sa_family == UInt8(AF_LINK),
               let data = ifa.ifa_data?.assumingMemoryBound(to: if_data.self) {
                return (UInt64(data.pointee.ifi_ibytes), UInt64(data.pointee.ifi_obytes))
            }
            ptr = ifa.ifa_next
        }
        return (0, 0)
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
}

// ── Disk activity (read/write throughput) ───────────────────────────────────
class DiskActivityMonitor: ObservableObject {
    static let shared = DiskActivityMonitor()

    @Published var readMBps: Double = 0
    @Published var writeMBps: Double = 0
    @Published var activityHistory: [Double] = Array(repeating: 0, count: 60)

    private var timer: Timer?
    private let queue = DispatchQueue(label: "rnitro.disk", qos: .utility)

    func start() {
        stop()
        queue.async { [weak self] in self?.sample() }
        let t = Timer.scheduledTimer(withTimeInterval: MonitorActivity.diskInterval, repeats: true) { [weak self] _ in
            self?.queue.async { self?.sample() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func sample() {
        guard let out = NetworkMonitor.runToolPublic("/usr/sbin/iostat", ["-d", "1", "1"]) else { return }
        let lines = out.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let dataLine = lines.last(where: { $0.contains(".") && !$0.lowercased().hasPrefix("disk") && !$0.hasPrefix("kb/t") }) else { return }
        let parts = dataLine.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard parts.count >= 3, let mbps = Double(parts[parts.count - 1]) else { return }
        let half = mbps / 2.0
        DispatchQueue.main.async {
            self.readMBps = half
            self.writeMBps = half
            self.activityHistory.removeFirst()
            self.activityHistory.append(mbps)
        }
    }
}

extension NetworkMonitor {
    static func runToolPublic(_ path: String, _ args: [String]) -> String? {
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
}

// ── SMC / fan sensor listing ────────────────────────────────────────────────
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
            if iface.hasPrefix("en") { return "Network (\(iface))" }
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
        if key.hasPrefix("Tp") { return ("CPU Sensor \(key)", "SMC temperature key") }
        if key.hasPrefix("Te") { return ("Efficiency Sensor \(key)", "Efficiency cluster sensor") }
        if key.hasPrefix("TC") { return ("Thermal \(key)", "Thermal controller reading") }
        return ("Sensor \(key)", "System Management Controller key")
    }

    static func fan(_ key: String) -> String {
        switch key {
        case "F0Ac", "F0Mn", "F0Md": return "Fan 1"
        case "F1Ac", "F1Mn", "F1Md": return "Fan 2"
        case "F2Ac": return "Fan 3"
        default: return "Fan \(key)"
        }
    }

    static func coreLabel(index: Int, isEfficiency: Bool, clusterIndex: Int) -> String {
        isEfficiency ? "E\(clusterIndex + 1)" : "P\(clusterIndex + 1)"
    }
}

class SensorsMonitor: ObservableObject {
    static let shared = SensorsMonitor()

    struct Entry: Identifiable {
        let id: String
        let rawKey: String
        let name: String
        let detail: String?
        let value: String
        let unit: String
        let group: String
    }

    @Published var entries: [Entry] = []

    private var timer: Timer?

    func start() {
        stop()
        refresh()
        let t = Timer.scheduledTimer(withTimeInterval: MonitorActivity.sensorsInterval, repeats: true) { [weak self] _ in self?.refresh() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        DispatchQueue.global(qos: .utility).async {
            var rows: [Entry] = []
            for t in SMCReader.shared.temperatureEntries().prefix(14) {
                let mapped = HardwareLabelMapper.smcTemperature(t.key)
                rows.append(Entry(id: "t-\(t.key)", rawKey: t.key, name: mapped.name, detail: mapped.detail,
                                  value: String(format: "%.0f", t.value), unit: t.unit, group: "Temperatures"))
            }
            for f in SMCReader.shared.fanRPMReadings() {
                rows.append(Entry(id: "f-\(f.key)", rawKey: f.key, name: HardwareLabelMapper.fan(f.key), detail: nil,
                                  value: "\(f.rpm)", unit: "RPM", group: "Fans"))
            }
            DispatchQueue.main.async { self.entries = rows }
        }
    }
}

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
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,weather_code&timezone=auto"
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

    private func cacheKey(_ networkKey: String) -> String { "rnitro.weather.\(networkKey)" }

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

extension Color {
    static let bg      = Color(red:0.05,green:0.05,blue:0.08)
    static let card    = Color(red:0.10,green:0.10,blue:0.14)
    static let border  = Color(red:0.20,green:0.20,blue:0.28)
    static let accent  = Color(red:0.0, green:0.85,blue:1.0)
    static let nGreen  = Color(red:0.1, green:1.0, blue:0.5)
    static let nOrange = Color(red:1.0, green:0.55,blue:0.1)
    static let nRed    = Color(red:1.0, green:0.25,blue:0.25)
    static let nPurple = Color(red:0.72, green:0.45, blue:1.0)
    static let nBlue   = Color(red:0.35, green:0.55, blue:1.0)
    static func usage(_ p: Double) -> Color { p < 40 ? .nGreen : p < 70 ? .accent : p < 90 ? .nOrange : .nRed }
    static func temp(_ t: Double)  -> Color { t < 60  ? .nGreen : t < 80  ? .nOrange : .nRed }
    static func pressure(_ label: String) -> Color {
        switch label {
        case "Critical": return .nRed
        case "Warning": return .nOrange
        default: return .nGreen
        }
    }
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

enum MonitorActivity {
    private(set) static var popoverOpen = false

    static var cpuInterval: TimeInterval { popoverOpen ? 1.0 : 2.0 }
    static var gpuInterval: TimeInterval { 3.0 }
    static var networkInterval: TimeInterval { popoverOpen ? 1.5 : 3.0 }
    static var batteryInterval: TimeInterval { popoverOpen ? 2.0 : 5.0 }
    static var diskInterval: TimeInterval { 5.0 }
    static var sensorsInterval: TimeInterval { popoverOpen ? 3.0 : 8.0 }
    static var includePowerSample: Bool { popoverOpen }

    static func setPopoverOpen(_ open: Bool) {
        guard popoverOpen != open else { return }
        popoverOpen = open
        CPUMonitor.shared.setPollInterval(cpuInterval)
        NetworkMonitor.shared.applyActivityInterval()
        BatteryMonitor.shared.applyActivityInterval()
        if open {
            GPUMonitor.shared.start()
            DiskActivityMonitor.shared.start()
            SensorsMonitor.shared.start()
        } else {
            GPUMonitor.shared.stop()
            DiskActivityMonitor.shared.stop()
            SensorsMonitor.shared.stop()
        }
    }
}

class GPUMonitor: ObservableObject {
    static let shared = GPUMonitor()
    @Published var usage: Double = 0
    @Published var usageHistory: [Double] = Array(repeating: 0, count: 80)

    private var timer: Timer?
    private let queue = DispatchQueue(label: "rnitro.gpu", qos: .utility)

    func start() {
        stop()
        queue.async { [weak self] in self?.poll() }
        let t = Timer.scheduledTimer(withTimeInterval: MonitorActivity.gpuInterval, repeats: true) { [weak self] _ in
            self?.queue.async { self?.poll() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
        task.arguments = ["-r", "-d", "1", "-c", "IOAccelerator"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do { try task.run() } catch { return }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        guard let out = String(data: data, encoding: .utf8) else { return }
        if let range = out.range(of: "\"Device Utilization %\"=") {
            let after = out[range.upperBound...]
            let numStr = after.prefix(while: { $0.isNumber })
            if let val = Double(numStr) {
                DispatchQueue.main.async {
                    self.usage = min(100, val)
                    self.usageHistory.removeFirst()
                    self.usageHistory.append(self.usage)
                }
            }
        }
    }
}

struct MiniGraphView: View {
    let history: [Double]
    let color: Color
    var maxValue: Double = 100

    var body: some View {
        GeometryReader { g in
            Path { p in
                let w = g.size.width, h = g.size.height
                let cap = max(maxValue, 1)
                let step = w / Double(max(history.count - 1, 1))
                for (i, v) in history.enumerated() {
                    let frac = min(max(v, 0), cap) / cap
                    let pt = CGPoint(x: Double(i) * step, y: h - frac * h)
                    i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                }
            }
            .stroke(color.opacity(0.85), lineWidth: 1)
        }
    }
}

struct MonitorRow: View {
    @Environment(\.uiMetrics) private var metrics
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(rNitroFont(.caption, metrics: metrics))
                .foregroundColor(.secondary)
                .frame(minWidth: 72, alignment: .leading)
            Spacer(minLength: 4)
            Text(value)
                .font(rNitroFont(.caption, metrics: metrics, weight: .medium))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(height: 22)
    }
}

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

struct MonitorSection<Content: View>: View {
    @Environment(\.uiMetrics) private var metrics
    let title: String
    let accent: Color
    let summary: String
    var sparkline: [Double]? = nil
    var sparkMax: Double = 100
    let storageKey: String
    @ViewBuilder let content: () -> Content
    @AppStorage private var isExpanded: Bool

    init(title: String, accent: Color, summary: String,
         sparkline: [Double]? = nil, sparkMax: Double = 100,
         storageKey: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.accent = accent
        self.summary = summary
        self.sparkline = sparkline
        self.sparkMax = sparkMax
        self.storageKey = storageKey
        self.content = content
        _isExpanded = AppStorage(wrappedValue: true, storageKey)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if UserDefaults.standard.bool(forKey: "rnitro.soloMode") {
                        SectionExpansionStore.toggle(key: storageKey, soloMode: true)
                    } else {
                        isExpanded.toggle()
                    }
                }
            }) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(accent)
                        .frame(width: 3, height: 22)
                    Text(title)
                        .font(rNitroFont(.label, metrics: metrics, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer(minLength: 4)
                    if let sparkline, !sparkline.isEmpty {
                        MiniGraphView(history: sparkline, color: accent, maxValue: sparkMax)
                            .frame(width: 44, height: 14)
                    }
                    Text(summary)
                        .font(rNitroFont(.caption, metrics: metrics, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.horizontal, metrics.hPad)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if isExpanded {
                VStack(spacing: 6) {
                    content()
                }
                .padding(.horizontal, metrics.hPad)
                .padding(.bottom, 10)
            }
            MinimalDivider().padding(.horizontal, metrics.hPad)
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

struct PowerGraphView: View {
    let history: [Double]
    let color: Color
    let maxWatts: Double

    var body: some View {
        GeometryReader { g in
            let cap = max(maxWatts, 1)
            ZStack(alignment: .bottomLeading) {
                Path { p in
                    let w = g.size.width, h = g.size.height
                    let step = w / Double(max(history.count - 1, 1))
                    for (i, v) in history.enumerated() {
                        let frac = min(max(v, 0), cap) / cap
                        let pt = CGPoint(x: Double(i) * step, y: h - frac * h)
                        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                    }
                }
                .stroke(color.opacity(0.9), lineWidth: 1.5)
            }
        }
    }
}

struct CoreRow: View {
    @Environment(\.uiMetrics) private var metrics
    let core: CoreInfo; let index: Int
    var isEfficiency: Bool = false
    var clusterIndex: Int = 0
    var body: some View {
        HStack(spacing: 8) {
            Text(HardwareLabelMapper.coreLabel(index: index, isEfficiency: isEfficiency, clusterIndex: clusterIndex))
                .font(rNitroFont(.caption, metrics: metrics))
                .foregroundColor(isEfficiency ? .nBlue.opacity(0.9) : .accent.opacity(0.9))
                .frame(minWidth: 22, maxWidth: 30, alignment: .leading).lineLimit(1)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.border.opacity(0.45))
                    Capsule()
                        .fill(Color.usage(core.usage).opacity(0.9))
                        .frame(width: g.size.width * core.usage / 100)
                }
            }.frame(height: 4)
            Text(String(format: "%.0f%%", core.usage))
                .font(rNitroFont(.caption, metrics: metrics))
                .foregroundColor(.secondary)
                .frame(minWidth: 28, maxWidth: 40, alignment: .trailing).lineLimit(1)
        }
    }
}

struct MinimalDivider: View {
    var body: some View {
        Rectangle().fill(Color.border.opacity(0.35)).frame(height: 1)
    }
}

struct MinimalButton: View {
    @Environment(\.uiMetrics) private var metrics
    let title: String
    var tint: Color = .accent
    var disabled: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(rNitroFont(.body, metrics: metrics, weight: .medium))
                .foregroundColor(disabled ? .secondary : tint)
                .padding(.horizontal, metrics.compact ? 10 : 12)
                .padding(.vertical, metrics.compact ? 5 : 6)
                .background(Color.clear)
                .overlay(Capsule().stroke(disabled ? Color.border.opacity(0.4) : tint.opacity(0.5), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

enum StatDetailKind: String, Identifiable {
    case clock, temperature, cores, memory, storage, battery, cpuPower
    var id: String { rawValue }
}

enum AppTab: String, CaseIterable, Identifiable {
    case monitor = "Monitor"
    case advisor = "Advisor"
    case chat = "Chat"
    case cleaner = "Cleaner"
    case settings = "Settings"
    case howItWorks = "How it works"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .monitor: return "gauge.with.dots.needle.67percent"
        case .advisor: return "waveform.path.ecg"
        case .chat: return "bubble.left.and.bubble.right"
        case .cleaner: return "trash"
        case .settings: return "gearshape"
        case .howItWorks: return "book.closed"
        }
    }

    static let popoverTabs: [AppTab] = [.monitor, .advisor, .chat, .cleaner]
    static let windowTabs: [AppTab] = [.monitor, .advisor, .chat, .cleaner, .settings, .howItWorks]
}

extension Notification.Name {
    static let rNitroOpenMainWindow = Notification.Name("rnitro.openMainWindow")
}

// ── Multi-provider AI chat (BYO API keys, stored in Keychain) ───────────────
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: String
    var text: String
    var isError: Bool

    init(id: UUID = UUID(), role: String, text: String, isError: Bool = false) {
        self.id = id
        self.role = role
        self.text = text
        self.isError = isError
    }
}

// AES-256-GCM at-rest encryption for API keys and chat history (master key in Keychain).
enum AES256SecureStore {
    private static let keychainService = "app.rnitro.crypto"
    private static let masterKeyAccount = "aes256.master"
    private static let envelopeMagic = Data("RNENC1".utf8)

    private static func loadMasterKey() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: masterKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data, data.count == 32 else { return nil }
        return SymmetricKey(data: data)
    }

    private static func saveMasterKey(_ key: SymmetricKey) {
        let data = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: masterKeyAccount
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    private static func masterKey() -> SymmetricKey {
        if let existing = loadMasterKey() { return existing }
        let key = SymmetricKey(size: .bits256)
        saveMasterKey(key)
        return key
    }

    static func isEncrypted(_ blob: Data) -> Bool {
        blob.count > envelopeMagic.count && blob.prefix(envelopeMagic.count) == envelopeMagic
    }

    static func encrypt(_ plaintext: Data) -> Data? {
        guard let sealed = try? AES.GCM.seal(plaintext, using: masterKey()),
              let combined = sealed.combined else { return nil }
        return envelopeMagic + combined
    }

    static func decrypt(_ blob: Data) -> Data? {
        guard isEncrypted(blob) else { return blob }
        let combined = blob.dropFirst(envelopeMagic.count)
        guard let box = try? AES.GCM.SealedBox(combined: Data(combined)),
              let plain = try? AES.GCM.open(box, using: masterKey()) else { return nil }
        return plain
    }
}

enum AIChatStore {
    private static let historyPrefix = "rnitro.ai.history."
    private static let maxMessagesPerProvider = 200

    static func load(provider: AIProvider) -> [ChatMessage] {
        let key = historyPrefix + provider.rawValue
        guard let blob = UserDefaults.standard.data(forKey: key),
              let data = AES256SecureStore.decrypt(blob),
              let saved = try? JSONDecoder().decode([ChatMessage].self, from: data) else { return [] }
        if !AES256SecureStore.isEncrypted(blob) { save(saved, provider: provider) }
        return saved
    }

    static func save(_ messages: [ChatMessage], provider: AIProvider) {
        let trimmed = messages.count > maxMessagesPerProvider
            ? Array(messages.suffix(maxMessagesPerProvider))
            : messages
        guard let data = try? JSONEncoder().encode(trimmed),
              let encrypted = AES256SecureStore.encrypt(data) else { return }
        UserDefaults.standard.set(encrypted, forKey: historyPrefix + provider.rawValue)
    }

    static func clear(provider: AIProvider) {
        UserDefaults.standard.removeObject(forKey: historyPrefix + provider.rawValue)
    }
}

enum AIProvider: String, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case openRouter = "OpenRouter"
    var id: String { rawValue }

    var requiresApiKey: Bool { true }

    var modelLabel: String {
        switch self {
        case .openai: return "gpt-4o-mini"
        case .openRouter: return "openrouter/auto"
        }
    }

    var keyURL: String {
        switch self {
        case .openai: return "https://platform.openai.com/api-keys"
        case .openRouter: return "https://openrouter.ai/keys"
        }
    }

    var keyHint: String {
        switch self {
        case .openai: return "OpenAI Platform"
        case .openRouter: return "OpenRouter"
        }
    }

    var setupHint: String {
        switch self {
        case .openai:
            return "Paste your OpenAI API key. Stored in Keychain — only sent to OpenAI when you chat."
        case .openRouter:
            return "Paste your OpenRouter API key. Stored in Keychain — only sent to OpenRouter when you chat."
        }
    }

    var ollamaModelTag: String? { nil }
}

enum AIConnectionState: String, Equatable {
    case connected = "Connected"
    case needsApiKey = "Needs API Key"
    case offlineError = "Offline / Error"
    case notConfigured = "Not Configured"

    var emoji: String {
        switch self {
        case .connected: return "🟢"
        case .needsApiKey: return "🟡"
        case .offlineError: return "🔴"
        case .notConfigured: return "⚪"
        }
    }

    var color: Color {
        switch self {
        case .connected: return .nGreen
        case .needsApiKey: return Color(red: 1.0, green: 0.82, blue: 0.2)
        case .offlineError: return .nRed
        case .notConfigured: return Color.secondary.opacity(0.45)
        }
    }
}

struct AIProviderStatus: Equatable {
    var state: AIConnectionState
    var lastCheck: Date?
    var errorMessage: String?
    var isChecking: Bool = false

    static let initial = AIProviderStatus(state: .notConfigured)

    var tooltip: String {
        var lines = ["\(state.emoji) \(state.rawValue)"]
        if let lastCheck {
            lines.append("Last check: \(AIProviderStatus.checkFormatter.string(from: lastCheck))")
        } else {
            lines.append("Last check: —")
        }
        if let errorMessage, !errorMessage.isEmpty, state == .offlineError {
            lines.append("Error: \(errorMessage)")
        } else if state == .needsApiKey {
            lines.append("Add an API key to connect.")
        } else if state == .notConfigured {
            lines.append("Tap Enable to configure this provider.")
        }
        return lines.joined(separator: "\n")
    }

    private static let checkFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        return f
    }()
}

enum AIKeychain {
    static let service = "app.rnitro.ai"

    static func save(_ key: String, provider: AIProvider) {
        guard let plain = key.data(using: .utf8),
              let data = AES256SecureStore.encrypt(plain) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    static func load(provider: AIProvider) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let blob = item as? Data,
              let data = AES256SecureStore.decrypt(blob),
              let key = String(data: data, encoding: .utf8), !key.isEmpty else { return nil }
        if !AES256SecureStore.isEncrypted(blob) { save(key, provider: provider) }
        return key
    }

    static func delete(provider: AIProvider) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func hasKey(for provider: AIProvider) -> Bool { load(provider: provider) != nil }
}

enum AIKeyUtil {
    static func sanitize(_ key: String) -> String {
        var k = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if k.lowercased().hasPrefix("bearer ") {
            k = String(k.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return k
    }

    static func isUsableCloudKey(_ key: String) -> Bool {
        let k = sanitize(key)
        return !k.isEmpty && k != "local"
    }

    static func isEnabledLocal(_ key: String) -> Bool {
        !sanitize(key).isEmpty
    }

    static func isAuthFailure(_ message: String, status: Int = 0) -> Bool {
        if status == 401 || status == 403 { return true }
        let lower = message.lowercased()
        return lower.contains("authentication") || lower.contains("api key") ||
               lower.contains("apikey") || lower.contains("unauthorized") ||
               lower.contains("invalid key") || lower.contains("auth credentials")
    }
}

@MainActor
final class AIChatModel: ObservableObject {
    static let shared = AIChatModel()

    @Published var selectedProvider: AIProvider = .openai
    @Published var apiKeyDraft = ""
    @Published var messages: [ChatMessage] = [] {
        didSet { guard !suppressPersist else { return }; AIChatStore.save(messages, provider: selectedProvider) }
    }
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var showKeyEditor = false
    @Published var providerStatuses: [AIProvider: AIProviderStatus] = [:]

    private var keys: [AIProvider: String] = [:]
    private let providerDefaultsKey = "rnitro.ai.provider"
    private var suppressPersist = false
    private var statusTimer: Timer?

    private init() {
        for p in AIProvider.allCases {
            if let k = AIKeychain.load(provider: p) {
                if p.requiresApiKey && !AIKeyUtil.isUsableCloudKey(k) {
                    AIKeychain.delete(provider: p)
                } else {
                    keys[p] = AIKeyUtil.sanitize(k)
                }
            }
            providerStatuses[p] = AIProviderStatus.initial
        }
        if let saved = UserDefaults.standard.string(forKey: providerDefaultsKey),
           let p = AIProvider(rawValue: saved) {
            selectedProvider = p
        }
        loadMessages(for: selectedProvider)
        showKeyEditor = !hasSavedKey(for: selectedProvider)
        refreshLocalStatuses()
        startStatusMonitoring()
    }

    deinit {
        statusTimer?.invalidate()
    }

    func status(for provider: AIProvider) -> AIProviderStatus {
        providerStatuses[provider] ?? .initial
    }

    func startStatusMonitoring() {
        statusTimer?.invalidate()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refreshAllProviderStatuses() }
        }
        Task { await refreshAllProviderStatuses() }
    }

    private func refreshLocalStatuses() {
        for p in AIProvider.allCases {
            providerStatuses[p] = localStatus(for: p)
        }
    }

    private func localStatus(for provider: AIProvider) -> AIProviderStatus {
        if provider.requiresApiKey {
            guard let k = resolvedKey(for: provider), !k.isEmpty else {
                return AIProviderStatus(state: .needsApiKey)
            }
        } else if !hasSavedKey(for: provider) {
            return AIProviderStatus(state: .notConfigured)
        }
        return providerStatuses[provider] ?? AIProviderStatus(state: .notConfigured)
    }

    func refreshAllProviderStatuses() async {
        await withTaskGroup(of: Void.self) { group in
            for p in AIProvider.allCases {
                group.addTask { await self.refreshStatus(for: p) }
            }
        }
    }

    func refreshStatus(for provider: AIProvider) async {
        if provider.requiresApiKey {
            guard let k = resolvedKey(for: provider), !k.isEmpty else {
                providerStatuses[provider] = AIProviderStatus(state: .needsApiKey, lastCheck: Date())
                return
            }
        } else if !hasSavedKey(for: provider) {
            providerStatuses[provider] = AIProviderStatus(state: .notConfigured, lastCheck: Date())
            return
        }

        let rawKey = keys[provider] ?? AIKeychain.load(provider: provider) ?? "local"
        let apiKey = AIKeyUtil.sanitize(rawKey)
        var current = providerStatuses[provider] ?? AIProviderStatus(state: .notConfigured)
        current.isChecking = true
        providerStatuses[provider] = current

        let result = await Self.probe(provider: provider, apiKey: apiKey)
        let now = Date()
        switch result {
        case .success:
            providerStatuses[provider] = AIProviderStatus(state: .connected, lastCheck: now)
        case .failure(let error):
            let msg = error.localizedDescription
            let code = (error as NSError).code
            let state: AIConnectionState = provider.requiresApiKey && AIKeyUtil.isAuthFailure(msg, status: code)
                ? .needsApiKey : .offlineError
            providerStatuses[provider] = AIProviderStatus(
                state: state,
                lastCheck: now,
                errorMessage: msg
            )
        }
    }

    private func markProviderConnected(_ provider: AIProvider) {
        providerStatuses[provider] = AIProviderStatus(state: .connected, lastCheck: Date())
    }

    private func markProviderError(_ provider: AIProvider, message: String) {
        providerStatuses[provider] = AIProviderStatus(
            state: .offlineError,
            lastCheck: Date(),
            errorMessage: message
        )
    }

    private func loadMessages(for provider: AIProvider) {
        suppressPersist = true
        messages = AIChatStore.load(provider: provider)
        suppressPersist = false
    }

    func hasSavedKey(for provider: AIProvider) -> Bool {
        if provider.requiresApiKey {
            return resolvedKey(for: provider) != nil
        }
        guard let raw = keys[provider] ?? AIKeychain.load(provider: provider) else { return false }
        return AIKeyUtil.isEnabledLocal(raw)
    }

    var currentHasKey: Bool { hasSavedKey(for: selectedProvider) }

    private func resolvedKey(for provider: AIProvider) -> String? {
        guard let raw = keys[provider] ?? AIKeychain.load(provider: provider) else { return nil }
        let k = AIKeyUtil.sanitize(raw)
        if provider.requiresApiKey {
            return AIKeyUtil.isUsableCloudKey(k) ? k : nil
        }
        return k.isEmpty ? nil : k
    }

    func selectProvider(_ provider: AIProvider) {
        guard provider != selectedProvider else { return }
        AIChatStore.save(messages, provider: selectedProvider)
        selectedProvider = provider
        UserDefaults.standard.set(provider.rawValue, forKey: providerDefaultsKey)
        loadMessages(for: provider)
        showKeyEditor = !hasSavedKey(for: provider)
        apiKeyDraft = ""
        Task { await refreshStatus(for: provider) }
    }

    func saveApiKey() {
        let k = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if selectedProvider.requiresApiKey && k.isEmpty { return }
        let stored = k.isEmpty ? "local" : AIKeyUtil.sanitize(k)
        AIKeychain.save(stored, provider: selectedProvider)
        keys[selectedProvider] = stored
        showKeyEditor = false
        apiKeyDraft = ""
        Task { await refreshStatus(for: selectedProvider) }
    }

    func removeApiKey() {
        AIKeychain.delete(provider: selectedProvider)
        keys[selectedProvider] = nil
        showKeyEditor = true
        apiKeyDraft = ""
        messages = []
        inputText = ""
        providerStatuses[selectedProvider] = selectedProvider.requiresApiKey
            ? AIProviderStatus(state: .needsApiKey, lastCheck: Date())
            : AIProviderStatus(state: .notConfigured, lastCheck: Date())
    }

    func clearHistory() {
        messages = []
        inputText = ""
        AIChatStore.clear(provider: selectedProvider)
    }

    func appendToMessage(id: UUID, delta: String) {
        guard let idx = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[idx].text += delta
    }

    func replaceMessage(id: UUID, text: String, isError: Bool = false) {
        guard let idx = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[idx].text = text
        messages[idx].isError = isError
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        let provider = selectedProvider
        let apiKey: String
        if provider.requiresApiKey {
            guard let k = resolvedKey(for: provider) else {
                showKeyEditor = true
                providerStatuses[provider] = AIProviderStatus(state: .needsApiKey, lastCheck: Date())
                return
            }
            apiKey = k
        } else {
            guard hasSavedKey(for: provider) else {
                showKeyEditor = true
                return
            }
            apiKey = AIKeyUtil.sanitize(keys[provider] ?? AIKeychain.load(provider: provider) ?? "local")
        }
        keys[provider] = apiKey
        inputText = ""
        messages.append(ChatMessage(role: "user", text: text))
        let history = messages
        let replyId = UUID()
        messages.append(ChatMessage(id: replyId, role: "model", text: ""))
        isLoading = true
        Task {
            do {
                let reply: String
                if Self.supportsStreaming(provider) {
                    reply = try await Self.requestStreaming(
                        provider: provider, apiKey: apiKey, messages: history,
                        onDelta: { [weak self] delta in
                            Task { @MainActor in self?.appendToMessage(id: replyId, delta: delta) }
                        }
                    )
                    if messages.first(where: { $0.id == replyId })?.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
                        replaceMessage(id: replyId, text: reply)
                    }
                } else {
                    reply = try await Self.request(provider: provider, apiKey: apiKey, messages: history)
                    replaceMessage(id: replyId, text: reply)
                }
                markProviderConnected(provider)
            } catch {
                let msg = error.localizedDescription
                let code = (error as NSError).code
                replaceMessage(id: replyId, text: msg, isError: true)
                if AIKeyUtil.isAuthFailure(msg, status: code) {
                    let hint = provider.requiresApiKey
                        ? msg
                        : "\(msg)\n\nThis server requires an API key — open the Settings tab and paste the key from your local server."
                    providerStatuses[provider] = AIProviderStatus(
                        state: provider.requiresApiKey ? .needsApiKey : .offlineError,
                        lastCheck: Date(),
                        errorMessage: hint
                    )
                    showKeyEditor = true
                } else {
                    markProviderError(provider, message: msg)
                }
            }
            isLoading = false
        }
    }

    nonisolated private static func probe(provider: AIProvider, apiKey: String) async -> Result<Void, Error> {
        do {
            switch provider {
            case .openai:
                var req = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
                req.httpMethod = "GET"
                req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                req.timeoutInterval = 8
                try await validateHTTP(req, domain: "OpenAI", accept: [200])
            case .openRouter:
                var req = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/models")!)
                req.httpMethod = "GET"
                req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                req.timeoutInterval = 8
                try await validateHTTP(req, domain: "OpenRouter", accept: [200])
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    nonisolated private static func validateHTTP(_ req: URLRequest, domain: String, accept: [Int]) async throws {
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if accept.contains(http.statusCode) { return }
        if let err = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let e = err["error"] as? [String: Any], let msg = e["message"] as? String {
                throw NSError(domain: domain, code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            if let msg = err["message"] as? String {
                throw NSError(domain: domain, code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
        }
        throw NSError(domain: domain, code: http.statusCode,
                      userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
    }

        nonisolated private static func supportsStreaming(_ provider: AIProvider) -> Bool {
        switch provider {
        case .openai, .openRouter: return true
        default: return false
        }
    }

    nonisolated private static func request(provider: AIProvider, apiKey: String, messages: [ChatMessage]) async throws -> String {
        switch provider {
        case .openai: return try await requestOpenAI(apiKey: apiKey, messages: messages)
        case .openRouter: return try await requestOpenRouter(apiKey: apiKey, messages: messages)
        }
    }

    nonisolated private static func requestStreaming(
        provider: AIProvider, apiKey: String, messages: [ChatMessage],
        onDelta: @escaping (String) -> Void
    ) async throws -> String {
        switch provider {
        case .openai:
            return try await streamOpenAICompatible(
                url: "https://api.openai.com/v1/chat/completions", apiKey: apiKey, model: "gpt-4o-mini",
                messages: messages, domain: "OpenAI", requireAuth: true, onDelta: onDelta,
                extraHeaders: [:]
            )
        case .openRouter:
            return try await streamOpenAICompatible(
                url: "https://openrouter.ai/api/v1/chat/completions", apiKey: apiKey, model: "openrouter/auto",
                messages: messages, domain: "OpenRouter", requireAuth: true, onDelta: onDelta,
                extraHeaders: ["HTTP-Referer": "https://getrnitro.netlify.app", "X-Title": "rNitro"]
            )
        default:
            return try await request(provider: provider, apiKey: apiKey, messages: messages)
        }
    }

    nonisolated private static func streamOpenAICompatible(
        url: String, apiKey: String, model: String, messages: [ChatMessage], domain: String,
        requireAuth: Bool, onDelta: @escaping (String) -> Void,
        extraHeaders: [String: String]
    ) async throws -> String {
        let key = AIKeyUtil.sanitize(apiKey)
        if requireAuth && !AIKeyUtil.isUsableCloudKey(key) {
            throw NSError(domain: domain, code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Missing API key — open Settings and paste your \(domain) key."])
        }
        var req = URLRequest(url: URL(string: url)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if AIKeyUtil.isUsableCloudKey(key) {
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        for (k, v) in extraHeaders { req.setValue(v, forHTTPHeaderField: k) }
        req.timeoutInterval = 120
        let msgs: [[String: String]] = chatHistory(messages).map {
            ["role": $0.role == "user" ? "user" : "assistant", "content": $0.text]
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: ["model": model, "messages": msgs, "stream": true])
        let (bytes, resp) = try await URLSession.shared.bytes(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode != 200 {
            var collected = Data()
            for try await chunk in bytes { collected.append(chunk) }
            try parseAPIError(data: collected, status: http.statusCode, domain: domain)
            throw URLError(.badServerResponse)
        }
        var full = ""
        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let payload = String(line.dropFirst(6))
            if payload == "[DONE]" { break }
            guard let data = payload.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any],
                  let content = delta["content"] as? String, !content.isEmpty else { continue }
            full += content
            onDelta(content)
        }
        let trimmed = full.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw NSError(domain: domain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty response from \(domain)"])
        }
        return trimmed
    }

    nonisolated private static func chatHistory(_ messages: [ChatMessage]) -> [ChatMessage] {
        messages.filter { !$0.isError }
    }

    nonisolated private static func parseAPIError(data: Data, status: Int, domain: String) throws {
        if let err = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let e = err["error"] as? [String: Any], let msg = e["message"] as? String {
                throw NSError(domain: domain, code: status, userInfo: [NSLocalizedDescriptionKey: friendlyAuthMessage(msg, domain: domain, status: status)])
            }
            if let msg = err["message"] as? String {
                throw NSError(domain: domain, code: status, userInfo: [NSLocalizedDescriptionKey: friendlyAuthMessage(msg, domain: domain, status: status)])
            }
        }
        let fallback = status == 401 ? "Invalid or missing API key for \(domain)." : "HTTP \(status)"
        throw NSError(domain: domain, code: status, userInfo: [NSLocalizedDescriptionKey: fallback])
    }

    nonisolated private static func friendlyAuthMessage(_ msg: String, domain: String, status: Int) -> String {
        if AIKeyUtil.isAuthFailure(msg, status: status) {
            if domain == "OpenRouter" {
                return "Missing or invalid OpenRouter API key. Tap Change key and paste your key (starts with sk-or-)."
            }
            if domain == "LM Studio" {
                return "LM Studio requires an API key. Tap Change key and paste the token from LM Studio → Local Server."
            }
            return "Missing or invalid API key for \(domain). Tap Change key to update it."
        }
        return msg
    }

    nonisolated private static func requestGemini(apiKey: String, messages: [ChatMessage]) async throws -> String {
        let key = AIKeyUtil.sanitize(apiKey)
        guard AIKeyUtil.isUsableCloudKey(key) else {
            throw NSError(domain: "Gemini", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Missing API key — paste your Gemini key in Change key."])
        }
        var req = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent")!)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-goog-api-key")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60
        let contents: [[String: Any]] = chatHistory(messages).map { msg in
            ["role": msg.role == "user" ? "user" : "model", "parts": [["text": msg.text]]]
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: ["contents": contents])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode != 200 { try parseAPIError(data: data, status: http.statusCode, domain: "Gemini") }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let part = parts.first,
              let text = part["text"] as? String else {
            throw NSError(domain: "Gemini", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty response from Gemini"])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func requestOpenAI(apiKey: String, messages: [ChatMessage]) async throws -> String {
        let key = AIKeyUtil.sanitize(apiKey)
        guard AIKeyUtil.isUsableCloudKey(key) else {
            throw NSError(domain: "OpenAI", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Missing API key — paste your OpenAI key in Change key."])
        }
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 60
        let msgs: [[String: String]] = chatHistory(messages).map {
            ["role": $0.role == "user" ? "user" : "assistant", "content": $0.text]
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: ["model": "gpt-4o-mini", "messages": msgs])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode != 200 { try parseAPIError(data: data, status: http.statusCode, domain: "OpenAI") }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw NSError(domain: "OpenAI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty response from OpenAI"])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func requestAnthropic(apiKey: String, messages: [ChatMessage]) async throws -> String {
        let key = AIKeyUtil.sanitize(apiKey)
        guard AIKeyUtil.isUsableCloudKey(key) else {
            throw NSError(domain: "Anthropic", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Missing API key — paste your Anthropic key in Change key."])
        }
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.timeoutInterval = 60
        let msgs: [[String: String]] = chatHistory(messages).map {
            ["role": $0.role == "user" ? "user" : "assistant", "content": $0.text]
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": "claude-3-5-haiku-20241022",
            "max_tokens": 1024,
            "messages": msgs
        ])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode != 200 { try parseAPIError(data: data, status: http.statusCode, domain: "Anthropic") }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw NSError(domain: "Anthropic", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty response from Anthropic"])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func requestGroq(apiKey: String, messages: [ChatMessage]) async throws -> String {
        let key = AIKeyUtil.sanitize(apiKey)
        guard AIKeyUtil.isUsableCloudKey(key) else {
            throw NSError(domain: "Grok", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Missing API key — paste your Grok key in Change key."])
        }
        var req = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 60
        let msgs: [[String: String]] = chatHistory(messages).map {
            ["role": $0.role == "user" ? "user" : "assistant", "content": $0.text]
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: ["model": "llama-3.3-70b-versatile", "messages": msgs])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode != 200 { try parseAPIError(data: data, status: http.statusCode, domain: "Grok") }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw NSError(domain: "Grok", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty response from Grok"])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func requestOpenAICompatible(
        url: String, apiKey: String, model: String, messages: [ChatMessage], domain: String,
        extraHeaders: [String: String] = [:], requireAuth: Bool = false
    ) async throws -> String {
        let key = AIKeyUtil.sanitize(apiKey)
        if requireAuth && !AIKeyUtil.isUsableCloudKey(key) {
            throw NSError(domain: domain, code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Missing API key — open Change key and paste your \(domain) key."])
        }
        var req = URLRequest(url: URL(string: url)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if AIKeyUtil.isUsableCloudKey(key) {
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        } else if requireAuth {
            throw NSError(domain: domain, code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Missing Authentication header"])
        }
        for (k, v) in extraHeaders { req.setValue(v, forHTTPHeaderField: k) }
        req.timeoutInterval = 120
        let msgs: [[String: String]] = chatHistory(messages).map {
            ["role": $0.role == "user" ? "user" : "assistant", "content": $0.text]
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: ["model": model, "messages": msgs])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode != 200 { try parseAPIError(data: data, status: http.statusCode, domain: domain) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw NSError(domain: domain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty response from \(domain)"])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func requestDeepSeek(apiKey: String, messages: [ChatMessage]) async throws -> String {
        try await requestOpenAICompatible(
            url: "https://api.deepseek.com/v1/chat/completions",
            apiKey: apiKey,
            model: "deepseek-chat",
            messages: messages,
            domain: "DeepSeek",
            requireAuth: true
        )
    }

    nonisolated private static func requestOpenRouter(apiKey: String, messages: [ChatMessage]) async throws -> String {
        let key = AIKeyUtil.sanitize(apiKey)
        guard AIKeyUtil.isUsableCloudKey(key) else {
            throw NSError(domain: "OpenRouter", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Missing API key — paste your OpenRouter key (starts with sk-or-)."])
        }
        var req = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("https://getrnitro.netlify.app", forHTTPHeaderField: "HTTP-Referer")
        req.setValue("rNitro", forHTTPHeaderField: "X-Title")
        req.timeoutInterval = 120
        let msgs: [[String: String]] = chatHistory(messages).map {
            ["role": $0.role == "user" ? "user" : "assistant", "content": $0.text]
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": "openrouter/auto",
            "messages": msgs
        ])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode != 200 { try parseAPIError(data: data, status: http.statusCode, domain: "OpenRouter") }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw NSError(domain: "OpenRouter", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Empty response from OpenRouter"])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func requestLMStudio(apiKey: String, messages: [ChatMessage]) async throws -> String {
        let key = AIKeyUtil.sanitize(apiKey)
        do {
            return try await requestOpenAICompatible(
                url: "http://127.0.0.1:1234/v1/chat/completions",
                apiKey: key,
                model: "local-model",
                messages: messages,
                domain: "LM Studio"
            )
        } catch {
            let msg = error.localizedDescription
            if !AIKeyUtil.isUsableCloudKey(key) && AIKeyUtil.isAuthFailure(msg, status: (error as NSError).code) {
                throw NSError(domain: "LM Studio", code: 401, userInfo: [
                    NSLocalizedDescriptionKey: "LM Studio requires an API key. Tap Change key and paste the key from LM Studio → Local Server → API token."
                ])
            }
            throw error
        }
    }

    nonisolated private static func requestOllama(apiKey: String, messages: [ChatMessage], model: String) async throws -> String {
        var req = URLRequest(url: URL(string: "http://127.0.0.1:11434/api/chat")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 120
        let msgs: [[String: String]] = chatHistory(messages).map {
            ["role": $0.role == "user" ? "user" : "assistant", "content": $0.text]
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "messages": msgs,
            "stream": false
        ])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode != 200 { try parseAPIError(data: data, status: http.statusCode, domain: "Ollama") }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw NSError(domain: "Ollama", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty response — is Ollama running? Try: ollama pull \(model)"])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ProviderStatusIndicator: View {
    let status: AIProviderStatus

    var body: some View {
        ZStack {
            Circle()
                .fill(status.state.color)
                .frame(width: 6, height: 6)
            if status.isChecking {
                Circle()
                    .stroke(Color.accent.opacity(0.7), lineWidth: 1)
                    .frame(width: 9, height: 9)
            }
        }
        .help(status.tooltip)
        .accessibilityLabel(status.state.rawValue)
    }
}

struct AIProviderPicker: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject var chat: AIChatModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(AIProvider.allCases) { p in
                    Button(action: { chat.selectProvider(p) }) {
                        HStack(spacing: 5) {
                            Text(p.rawValue)
                            ProviderStatusIndicator(status: chat.status(for: p))
                        }
                        .font(rNitroFont(.caption, metrics: metrics, weight: chat.selectedProvider == p ? .semibold : .regular))
                        .foregroundColor(chat.selectedProvider == p ? .accent : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(chat.selectedProvider == p ? Color.accent.opacity(0.12) : Color.clear)
                        .overlay(Capsule().stroke(chat.selectedProvider == p ? Color.accent.opacity(0.5) : Color.border.opacity(0.4), lineWidth: 0.5))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

enum SettingsSection: String, CaseIterable, Identifiable {
    case ai, appearance, menubar, monitor, alerts, general
    var id: String { rawValue }

    var label: String {
        switch self {
        case .ai: return "AI"
        case .appearance: return "Appearance"
        case .menubar: return "Menubar"
        case .monitor: return "Monitor"
        case .alerts: return "Alerts"
        case .general: return "General"
        }
    }

    var icon: String {
        switch self {
        case .ai: return "sparkles"
        case .appearance: return "paintbrush"
        case .menubar: return "menubar.rectangle"
        case .monitor: return "gauge"
        case .alerts: return "bell.badge"
        case .general: return "gearshape"
        }
    }
}

struct SettingsView: View {
    @Environment(\.uiMetrics) private var metrics
    @State private var section: SettingsSection = .ai

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Settings")
                    .font(rNitroFont(.title, metrics: metrics, weight: .semibold))
                Text("AI keys, monitor layout, menubar, alerts, and startup options.")
                    .font(rNitroFont(.caption, metrics: metrics))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, metrics.hPad)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(SettingsSection.allCases) { s in
                        Button(action: { section = s }) {
                            HStack(spacing: 5) {
                                Image(systemName: s.icon)
                                    .font(.system(size: 11, weight: .semibold))
                                Text(s.label)
                                    .font(rNitroFont(.caption, metrics: metrics, weight: section == s ? .semibold : .regular))
                            }
                            .foregroundColor(section == s ? .accent : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(section == s ? Color.accent.opacity(0.14) : Color.card.opacity(0.35))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(section == s ? Color.accent.opacity(0.45) : Color.border.opacity(0.35), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, metrics.hPad)
            }
            .padding(.bottom, 8)

            MinimalDivider().padding(.horizontal, metrics.hPad)

            Group {
                switch section {
                case .ai: SettingsAISection()
                case .appearance: SettingsAppearanceSection()
                case .menubar: SettingsMenubarSection()
                case .monitor: SettingsMonitorSection()
                case .alerts: SettingsAlertsSection()
                case .general: SettingsGeneralSection()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.bg)
        .onReceive(NotificationCenter.default.publisher(for: .rNitroOpenMainWindow)) { note in
            if let raw = note.userInfo?["settingsSection"] as? String,
               let s = SettingsSection(rawValue: raw) {
                section = s
            }
        }
    }
}

struct SettingsAISection: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var chat = AIChatModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AIProviderPicker(chat: chat).padding(.horizontal, metrics.hPad).padding(.top, 10).padding(.bottom, 8)
            MinimalDivider().padding(.horizontal, metrics.hPad)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("AI Providers")
                        .font(rNitroFont(.body, metrics: metrics, weight: .semibold))
                    Text("API keys are encrypted in Keychain. Cloud providers need a key; LM Studio, Ollama, and Hermes use Enable.")
                        .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        ProviderStatusIndicator(status: chat.status(for: chat.selectedProvider))
                        Text(chat.status(for: chat.selectedProvider).state.rawValue)
                            .font(rNitroFont(.label, metrics: metrics, weight: .semibold))
                            .foregroundColor(chat.status(for: chat.selectedProvider).state.color)
                        Spacer()
                        MinimalButton(
                            title: chat.status(for: chat.selectedProvider).isChecking ? "Testing…" : "Test connection",
                            tint: .nBlue,
                            disabled: chat.status(for: chat.selectedProvider).isChecking,
                            action: { Task { await chat.refreshStatus(for: chat.selectedProvider) } }
                        )
                    }
                    Text(chat.selectedProvider.setupHint)
                        .font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                    if chat.selectedProvider.requiresApiKey {
                        SecureField("API key", text: $chat.apiKeyDraft)
                            .textFieldStyle(.plain)
                            .font(rNitroFont(.body, metrics: metrics))
                            .padding(10)
                            .background(Color.card)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.border.opacity(0.6), lineWidth: 1))
                    } else {
                        SecureField("API key (optional)", text: $chat.apiKeyDraft)
                            .textFieldStyle(.plain)
                            .font(rNitroFont(.body, metrics: metrics))
                            .padding(10)
                            .background(Color.card)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.border.opacity(0.6), lineWidth: 1))
                    }
                    HStack(spacing: 10) {
                        MinimalButton(
                            title: chat.selectedProvider.requiresApiKey ? "Save Key" : "Enable",
                            action: { chat.saveApiKey() }
                        )
                        if chat.hasSavedKey(for: chat.selectedProvider) {
                            Button("Remove Key") { chat.removeApiKey() }
                                .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.nRed).buttonStyle(.plain)
                        }
                    }
                    Link("Get a key: \(chat.selectedProvider.keyHint)", destination: URL(string: chat.selectedProvider.keyURL)!)
                        .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.accent)
                    Text("Privacy: keys stay on this Mac. Chat messages are sent only to the provider you pick.")
                        .font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                }
                .padding(.horizontal, metrics.hPad).padding(.vertical, 14)
            }
        }
        .onAppear {
            chat.startStatusMonitoring()
            chat.apiKeyDraft = ""
        }
        .onChange(of: chat.selectedProvider) { _, _ in chat.apiKeyDraft = "" }
    }
}

struct SettingsAppearanceSection: View {
    @Environment(\.uiMetrics) private var metrics
    @AppStorage(MonitorPreferences.uiStyleKey) private var uiStyleRaw = MonitorUIStyle.modern.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Monitor appearance")
                    .font(rNitroFont(.body, metrics: metrics, weight: .semibold))
                Text("Modern uses iStats-style accordion sections. Legacy is the compact classic layout.")
                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                Picker("Monitor UI", selection: $uiStyleRaw) {
                    ForEach(MonitorUIStyle.allCases) { style in
                        Text(style.label).tag(style.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, metrics.hPad).padding(.vertical, 14)
        }
    }
}

struct SettingsMenubarSection: View {
    @Environment(\.uiMetrics) private var metrics
    @AppStorage(MonitorPreferences.menuBarLayoutKey) private var menuBarLayoutRaw = MenuBarLayout.inline.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Menu bar icon")
                    .font(rNitroFont(.body, metrics: metrics, weight: .semibold))
                Text("Choose layout and which stats appear in the top-right menubar.")
                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                Picker("Menu Bar Layout", selection: $menuBarLayoutRaw) {
                    ForEach(MenuBarLayout.allCases) { layout in
                        Text(layout.label).tag(layout.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: menuBarLayoutRaw) { _, _ in
                    if let layout = MenuBarLayout(rawValue: menuBarLayoutRaw) {
                        MenuBarConfig.setLayout(layout)
                    }
                }
                ForEach(MenuBarSlot.allCases) { slot in
                    Toggle(isOn: Binding(
                        get: { MenuBarConfig.isSlotEnabled(slot) },
                        set: { MenuBarConfig.setSlot(slot, enabled: $0) }
                    )) {
                        Text(slot.label).font(rNitroFont(.label, metrics: metrics))
                    }
                    .toggleStyle(.switch)
                }
            }
            .padding(.horizontal, metrics.hPad).padding(.vertical, 14)
        }
    }
}

struct SettingsMonitorSection: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var net = NetworkMonitor.shared
    @ObservedObject private var weather = WeatherService.shared
    @ObservedObject private var stress = StressTester.shared
    @ObservedObject private var bench = BenchmarkRunner.shared
    @AppStorage(MonitorPreferences.stressKey) private var showStressUI = true
    @AppStorage(MonitorPreferences.benchmarkKey) private var showBenchmarkUI = true
    @AppStorage(MonitorPreferences.networkKey) private var showNetworkUI = true
    @AppStorage(MonitorPreferences.soloModeKey) private var soloMode = false
    @AppStorage(MonitorPreferences.showWeatherKey) private var showWeather = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Monitor sections")
                    .font(rNitroFont(.body, metrics: metrics, weight: .semibold))
                Text("Control which panels and tools appear on the Monitor tab.")
                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                Toggle(isOn: $showStressUI) {
                    Text("Show Stress Test").font(rNitroFont(.label, metrics: metrics))
                }
                .toggleStyle(.switch)
                .onChange(of: showStressUI) { _, on in if !on { stress.stop() } }
                Toggle(isOn: $showBenchmarkUI) {
                    Text("Show Benchmark").font(rNitroFont(.label, metrics: metrics))
                }
                .toggleStyle(.switch).disabled(bench.isRunning)
                Toggle(isOn: $showNetworkUI) {
                    Text("Show Network").font(rNitroFont(.label, metrics: metrics))
                }
                .toggleStyle(.switch)
                if RNITRO_FEATURE_BETA_UI {
                    Toggle(isOn: $soloMode) {
                        Text("Solo Mode (one panel open)").font(rNitroFont(.label, metrics: metrics))
                    }
                    .toggleStyle(.switch)
                    Toggle(isOn: $showWeather) {
                        Text("Show weather on Network").font(rNitroFont(.label, metrics: metrics))
                    }
                    .toggleStyle(.switch)
                    Text("Visible panels")
                        .font(rNitroFont(.label, metrics: metrics, weight: .semibold))
                        .padding(.top, 4)
                    ForEach(MonitorPanel.allCases.filter { $0 != .cleaner }) { panel in
                        Toggle(isOn: Binding(
                            get: { UserDefaults.standard.object(forKey: "rnitro.panelVisible.\(panel.rawValue)") == nil ? true : UserDefaults.standard.bool(forKey: "rnitro.panelVisible.\(panel.rawValue)") },
                            set: { UserDefaults.standard.set($0, forKey: "rnitro.panelVisible.\(panel.rawValue)") }
                        )) {
                            Text(panel.title).font(rNitroFont(.caption, metrics: metrics))
                        }
                        .toggleStyle(.switch)
                    }
                }
            }
            .padding(.horizontal, metrics.hPad).padding(.vertical, 14)
        }
        .onAppear { refreshWeather() }
        .onChange(of: net.wifiSSID) { _, _ in refreshWeather() }
        .onChange(of: showWeather) { _, _ in refreshWeather() }
    }

    private func refreshWeather() {
        let key = net.wifiSSID.isEmpty ? "wired-\(net.interfaceName)" : net.wifiSSID
        weather.refresh(forNetworkKey: key, enabled: showWeather)
    }
}

struct SettingsAlertsSection: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var advisor = SystemAdvisorModel.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("System Advisor alerts")
                    .font(rNitroFont(.body, metrics: metrics, weight: .semibold))
                Text("Warning thresholds and notification behavior for the Advisor tab.")
                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                Text("Warning thresholds")
                    .font(rNitroFont(.label, metrics: metrics, weight: .semibold))
                thresholdRow("Temp warn °C", value: $advisor.thresholds.tempWarning, range: 55...95, step: 1)
                thresholdRow("Temp critical °C", value: $advisor.thresholds.tempCritical, range: 65...105, step: 1)
                thresholdRow("CPU %", value: $advisor.thresholds.cpuWarning, range: 50...100, step: 1)
                thresholdRow("RAM %", value: $advisor.thresholds.ramWarning, range: 50...100, step: 1)
                thresholdRow("GPU %", value: $advisor.thresholds.gpuWarning, range: 50...100, step: 1)
                thresholdRow("Battery low %", value: $advisor.thresholds.batteryLow, range: 5...40, step: 1)
                Toggle(isOn: $advisor.thresholds.proactiveEnabled) {
                    Text("Proactive alerts in chat").font(rNitroFont(.label, metrics: metrics))
                }
                .toggleStyle(.switch)
                .onChange(of: advisor.thresholds.proactiveEnabled) { _, _ in advisor.refreshThresholds() }
                Toggle(isOn: $advisor.thresholds.criticalTempBannersEnabled) {
                    Text("macOS banners for critical temps").font(rNitroFont(.label, metrics: metrics))
                }
                .toggleStyle(.switch)
                .onChange(of: advisor.thresholds.criticalTempBannersEnabled) { _, _ in advisor.refreshThresholds() }
            }
            .padding(.horizontal, metrics.hPad).padding(.vertical, 14)
        }
        .onChange(of: advisor.thresholds.tempWarning) { _, _ in advisor.refreshThresholds() }
        .onChange(of: advisor.thresholds.tempCritical) { _, _ in advisor.refreshThresholds() }
        .onChange(of: advisor.thresholds.cpuWarning) { _, _ in advisor.refreshThresholds() }
        .onChange(of: advisor.thresholds.ramWarning) { _, _ in advisor.refreshThresholds() }
        .onChange(of: advisor.thresholds.gpuWarning) { _, _ in advisor.refreshThresholds() }
        .onChange(of: advisor.thresholds.batteryLow) { _, _ in advisor.refreshThresholds() }
    }

    private func thresholdRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double) -> some View {
        HStack {
            Text(label).font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
            Spacer()
            Slider(value: value, in: range, step: step).frame(maxWidth: 200)
            Text("\(Int(value.wrappedValue))")
                .font(rNitroFont(.caption, metrics: metrics, weight: .semibold))
                .frame(width: 28, alignment: .trailing)
        }
    }
}

struct SettingsGeneralSection: View {
    @Environment(\.uiMetrics) private var metrics
    @State private var launchAtLogin = LaunchAtLoginManager.isEnabled()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("General")
                    .font(rNitroFont(.body, metrics: metrics, weight: .semibold))
                if #available(macOS 13.0, *) {
                    Toggle(isOn: $launchAtLogin) {
                        Text("Launch at Login").font(rNitroFont(.label, metrics: metrics))
                    }
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { _, _ in
                        if !LaunchAtLoginManager.setEnabled(launchAtLogin) {
                            launchAtLogin = LaunchAtLoginManager.isEnabled()
                        }
                    }
                } else {
                    Text("Launch at Login requires macOS 13 or later.")
                        .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                }
                MonitorRow(label: "Version", value: UpdateChecker.displayLabel(CURRENT_VERSION))
            }
            .padding(.horizontal, metrics.hPad).padding(.vertical, 14)
        }
        .onAppear { launchAtLogin = LaunchAtLoginManager.isEnabled() }
    }
}

struct AIChatView: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var chat = AIChatModel.shared
    var compact: Bool = false

    var body: some View {
        Group {
            if !chat.currentHasKey {
                needsSetupPanel
            } else {
                chatPanel
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg)
        .onAppear { chat.startStatusMonitoring() }
    }

    private var needsSetupPanel: some View {
        VStack(spacing: 14) {
            Text("AI Chat").font(rNitroFont(.title, metrics: metrics, weight: .semibold))
            AIProviderPicker(chat: chat)
            Text("Set up \(chat.selectedProvider.rawValue) before chatting.")
                .font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary).multilineTextAlignment(.center)
            if compact {
                popoverMiniKeySetup
            } else {
                Text("Open the Settings tab to save API keys and test connections.")
                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary).multilineTextAlignment(.center)
                MinimalButton(title: "Open Settings", action: openSettingsTab)
            }
        }
        .padding(compact ? 12 : 20)
    }

    private var popoverMiniKeySetup: some View {
        VStack(spacing: 10) {
            if chat.selectedProvider.requiresApiKey {
                SecureField("API key", text: $chat.apiKeyDraft)
                    .textFieldStyle(.plain)
                    .font(rNitroFont(.body, metrics: metrics))
                    .padding(8)
                    .background(Color.card)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.border.opacity(0.6), lineWidth: 1))
            }
            MinimalButton(
                title: chat.selectedProvider.requiresApiKey ? "Save Key" : "Enable",
                action: { chat.saveApiKey() }
            )
            Button("Open main window → Settings") { openSettingsInMainWindow() }
                .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.accent).buttonStyle(.plain)
        }
    }

    private func openSettingsTab() {
        NotificationCenter.default.post(name: .rNitroOpenMainWindow, object: nil, userInfo: ["tab": AppTab.settings.rawValue, "settingsSection": SettingsSection.ai.rawValue])
    }

    private func openSettingsInMainWindow() {
        NotificationCenter.default.post(name: .rNitroOpenMainWindow, object: nil, userInfo: ["tab": AppTab.settings.rawValue, "settingsSection": SettingsSection.ai.rawValue])
    }

    private var chatPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(chat.selectedProvider.rawValue).font(rNitroFont(metrics.compact ? .label : .body, metrics: metrics, weight: .semibold))
                ProviderStatusIndicator(status: chat.status(for: chat.selectedProvider))
                if !compact {
                    Text(chat.status(for: chat.selectedProvider).state.rawValue)
                        .font(rNitroFont(.micro, metrics: metrics))
                        .foregroundColor(chat.status(for: chat.selectedProvider).state.color)
                }
                Spacer()
                if !chat.messages.isEmpty {
                    Button("Clear") { chat.clearHistory() }
                        .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary).buttonStyle(.plain)
                }
            }
            .padding(.horizontal, compact ? 10 : 14).padding(.vertical, compact ? 6 : 8)
            if !compact {
                Text("History is saved on this Mac. Messages go to \(chat.selectedProvider.rawValue) — manage keys in Settings.")
                    .font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                    .padding(.horizontal, 14).padding(.bottom, 6)
            }
            AIProviderPicker(chat: chat).padding(.horizontal, compact ? 10 : 14).padding(.bottom, compact ? 6 : 8)
            MinimalDivider().padding(.horizontal, compact ? 10 : 14)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if chat.messages.isEmpty {
                            Text("Ask anything — powered by \(chat.selectedProvider.modelLabel).")
                                .font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        ForEach(chat.messages) { msg in
                            chatBubble(msg).id(msg.id)
                        }
                    }
                    .padding(compact ? 10 : 14)
                }
                .onReceive(chat.$messages) { messages in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            MinimalDivider().padding(.horizontal, 14)

            HStack(spacing: 8) {
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
            }
            .padding(compact ? 8 : 12)
        }
    }

    private func chatBubble(_ msg: ChatMessage) -> some View {
        let display = msg.text.isEmpty && chat.isLoading && msg.role != "user"
            ? "…"
            : msg.text
        return HStack {
            if msg.role == "user" { Spacer(minLength: metrics.bubbleSpacer) }
            Text(display)
                .font(rNitroFont(.label, metrics: metrics))
                .foregroundColor(msg.isError ? .nRed : (msg.role == "user" ? .primary : .secondary))
                .padding(10)
                .background(msg.role == "user" ? Color.accent.opacity(0.15) : Color.card)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.border.opacity(0.35), lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            if msg.role != "user" { Spacer(minLength: metrics.bubbleSpacer) }
        }
    }
}

// ── System Advisor: client-side specs assistant + customizable warnings ─────
struct AdvisorThresholds: Codable, Equatable {
    var tempWarning: Double = 80
    var tempCritical: Double = 92
    var cpuWarning: Double = 85
    var ramWarning: Double = 88
    var gpuWarning: Double = 90
    var batteryLow: Double = 20
    var proactiveEnabled: Bool = true
    var criticalTempBannersEnabled: Bool = true

    static let storageKey = "rnitro.advisor.thresholds"

    enum CodingKeys: String, CodingKey {
        case tempWarning, tempCritical, cpuWarning, ramWarning, gpuWarning, batteryLow
        case proactiveEnabled, criticalTempBannersEnabled
    }

    init(
        tempWarning: Double = 80,
        tempCritical: Double = 92,
        cpuWarning: Double = 85,
        ramWarning: Double = 88,
        gpuWarning: Double = 90,
        batteryLow: Double = 20,
        proactiveEnabled: Bool = true,
        criticalTempBannersEnabled: Bool = true
    ) {
        self.tempWarning = tempWarning
        self.tempCritical = tempCritical
        self.cpuWarning = cpuWarning
        self.ramWarning = ramWarning
        self.gpuWarning = gpuWarning
        self.batteryLow = batteryLow
        self.proactiveEnabled = proactiveEnabled
        self.criticalTempBannersEnabled = criticalTempBannersEnabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tempWarning = try c.decodeIfPresent(Double.self, forKey: .tempWarning) ?? 80
        tempCritical = try c.decodeIfPresent(Double.self, forKey: .tempCritical) ?? 92
        cpuWarning = try c.decodeIfPresent(Double.self, forKey: .cpuWarning) ?? 85
        ramWarning = try c.decodeIfPresent(Double.self, forKey: .ramWarning) ?? 88
        gpuWarning = try c.decodeIfPresent(Double.self, forKey: .gpuWarning) ?? 90
        batteryLow = try c.decodeIfPresent(Double.self, forKey: .batteryLow) ?? 20
        proactiveEnabled = try c.decodeIfPresent(Bool.self, forKey: .proactiveEnabled) ?? true
        criticalTempBannersEnabled = try c.decodeIfPresent(Bool.self, forKey: .criticalTempBannersEnabled) ?? true
    }

    static func load() -> AdvisorThresholds {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode(AdvisorThresholds.self, from: data) else {
            return AdvisorThresholds()
        }
        return saved
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}

enum AdvisorNotificationCenter {
    private static var lastBannerAt: [String: Date] = [:]
    private static let bannerCooldown: TimeInterval = 120

    static func configure() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    static func postCriticalTemp(current: Double, limit: Double) {
        let body = String(
            format: "CPU is %.1f°C — above your %.0f°C critical limit. Ease load or improve cooling.",
            current, limit
        )
        deliver(id: "rnitro.temp.critical", title: "rNitro — Critical Temperature", body: body)
    }

    static func postMacOSThermalCritical(temp: Double, stateLabel: String) {
        let body = String(
            format: "macOS reports %@ thermal pressure. CPU at %.1f°C.",
            stateLabel, temp
        )
        deliver(id: "rnitro.thermal.critical", title: "rNitro — Thermal Critical", body: body)
    }

    private static func deliver(id: String, title: String, body: String) {
        let now = Date()
        if let last = lastBannerAt[id], now.timeIntervalSince(last) < bannerCooldown { return }
        lastBannerAt[id] = now

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(id).\(Int(now.timeIntervalSince1970))",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.15, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }
}

enum AdvisorWarningKind: String, CaseIterable, Hashable {
    case tempWarning, tempCritical, cpuHigh, ramHigh, gpuHigh, batteryLow, thermalPressure
}

struct SystemSnapshot {
    let machineModel: String
    let osVersion: String
    let cpuName: String
    let physicalCores: Int
    let logicalCores: Int
    let efficiencyCores: Int
    let cpuUsage: Double
    let temperature: Double
    let tempSource: String
    let thermalState: ProcessInfo.ThermalState
    let smcSensorCount: Int
    let baseClockGHz: Double
    let boostClockGHz: Double
    let packagePowerW: Double
    let gpuUsage: Double
    let ramUsedGB: Double
    let ramTotalGB: Double
    let ramPercent: Double
    let memoryPressure: String
    let diskUsedPercent: Double
    let diskFreeGB: Double
    let diskVolumeName: String
    let batteryPresent: Bool
    let batteryPercent: Int
    let batteryCharging: Bool
    let batteryOnAC: Bool
    let lowPowerModeEnabled: Bool
    let networkDownMbps: Double
    let networkUpMbps: Double
    let uptimeHours: Double
    let load1: Double

    static func capture(
        cpu: CPUMonitor,
        gpu: GPUMonitor,
        bat: BatteryMonitor,
        net: NetworkMonitor
    ) -> SystemSnapshot {
        var model = "Mac"
        var sz = 0
        sysctlbyname("hw.model", nil, &sz, nil, 0)
        if sz > 0 {
            var buf = [CChar](repeating: 0, count: sz)
            sysctlbyname("hw.model", &buf, &sz, nil, 0)
            model = String(cString: buf)
        }
        return SystemSnapshot(
            machineModel: model,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            cpuName: cpu.cpuName,
            physicalCores: cpu.physicalCores,
            logicalCores: cpu.logicalCores,
            efficiencyCores: cpu.efficiencyCoreCount,
            cpuUsage: cpu.totalUsage,
            temperature: cpu.temperature,
            tempSource: cpu.tempSource,
            thermalState: cpu.thermalState,
            smcSensorCount: cpu.smcSensorCount,
            baseClockGHz: cpu.baseClock,
            boostClockGHz: cpu.boostClock,
            packagePowerW: cpu.packagePowerWatts,
            gpuUsage: gpu.usage,
            ramUsedGB: cpu.memoryUsedGB,
            ramTotalGB: cpu.memoryTotalGB,
            ramPercent: cpu.memoryUsedPercent,
            memoryPressure: cpu.memoryPressure,
            diskUsedPercent: cpu.diskUsedPercent,
            diskFreeGB: cpu.diskFreeGB,
            diskVolumeName: cpu.diskVolumeName,
            batteryPresent: bat.isPresent,
            batteryPercent: bat.levelPercent,
            batteryCharging: bat.isCharging,
            batteryOnAC: bat.isOnAC,
            lowPowerModeEnabled: cpu.isLowPowerModeEnabled,
            networkDownMbps: net.downloadMbps,
            networkUpMbps: net.uploadMbps,
            uptimeHours: cpu.systemUptime / 3600.0,
            load1: cpu.loadAverage1
        )
    }

    func specsSummary() -> String {
        let chip = cpuName.isEmpty ? machineModel : cpuName
        return """
        \(chip) · \(machineModel)
        \(physicalCores)P+\(max(0, logicalCores - physicalCores))E cores · \(String(format: "%.1f", ramTotalGB)) GB RAM
        macOS \(osVersion)
        """
    }

    func specsDetail() -> String {
        let thermal = CPUMonitor.thermalLabel(thermalState)
        var lines = [
            "Machine: \(machineModel)",
            "Chip: \(cpuName)",
            "Cores: \(physicalCores) performance + \(efficiencyCores) efficiency (\(logicalCores) logical)",
            "Clock: \(String(format: "%.2f", baseClockGHz))–\(String(format: "%.2f", boostClockGHz)) GHz",
            "RAM: \(String(format: "%.1f", ramUsedGB)) / \(String(format: "%.1f", ramTotalGB)) GB (\(String(format: "%.0f", ramPercent))%) · pressure \(memoryPressure)",
            "Storage: \(diskVolumeName) · \(String(format: "%.0f", diskUsedPercent))% used · \(String(format: "%.1f", diskFreeGB)) GB free",
            "Temp: \(String(format: "%.1f", temperature))°C via \(tempSource) · macOS thermal \(thermal)",
            "CPU: \(String(format: "%.0f", cpuUsage))% · GPU: \(String(format: "%.0f", gpuUsage))% · package \(String(format: "%.1f", packagePowerW)) W",
            "Load (1m): \(String(format: "%.2f", load1)) · uptime \(String(format: "%.1f", uptimeHours)) h",
        ]
        if batteryPresent {
            let src = batteryOnAC ? "AC power" : (batteryCharging ? "charging" : "battery")
            lines.append("Battery: \(batteryPercent)% (\(src))")
        }
        if lowPowerModeEnabled {
            lines.append("Low Power Mode: ON — macOS may reduce CPU clocks and background activity")
        }
        if networkDownMbps > 0.05 || networkUpMbps > 0.05 {
            lines.append("Network: ↓\(String(format: "%.1f", networkDownMbps)) ↑\(String(format: "%.1f", networkUpMbps)) Mbps")
        }
        if smcSensorCount > 0 {
            lines.append("SMC sensors: \(smcSensorCount) temperature keys resolved")
        }
        return lines.joined(separator: "\n")
    }

    func tempAdvice(thresholds: AdvisorThresholds) -> String {
        let thermal = CPUMonitor.thermalLabel(thermalState)
        var lines = [
            "CPU temperature: \(String(format: "%.1f", temperature))°C (\(tempSource))",
            "macOS thermal state: \(thermal)",
            "Your limits: warn \(Int(thresholds.tempWarning))°C · critical \(Int(thresholds.tempCritical))°C",
        ]
        if temperature >= thresholds.tempCritical {
            lines.append("Status: CRITICAL — reduce load, improve airflow, or pause heavy tasks.")
        } else if temperature >= thresholds.tempWarning {
            lines.append("Status: above your warning threshold — watch for throttling.")
        } else if thermalState == .serious || thermalState == .critical {
            lines.append("Status: macOS reports elevated thermal pressure even though the gauge is below your custom limits.")
        } else {
            lines.append("Status: within your configured limits.")
        }
        if tempSource.contains("Estimate") {
            lines.append("Note: reading is interpolated — SMC keys unavailable or low on this sample.")
        }
        return lines.joined(separator: "\n")
    }
}

@MainActor
final class SystemAdvisorModel: ObservableObject {
    static let shared = SystemAdvisorModel()

    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var thresholds = AdvisorThresholds.load()
    @Published var showSettings = false
    @Published var activeWarnings: Set<AdvisorWarningKind> = []

    private var evalTimer: Timer?
    private var lastWarningPosted: [AdvisorWarningKind: Date] = [:]
    private let warningCooldown: TimeInterval = 90
    private let historyKey = "rnitro.advisor.history"
    private var didWelcome = false

    private init() {
        loadHistory()
    }

    func startMonitoring() {
        evalTimer?.invalidate()
        guard thresholds.proactiveEnabled else { return }
        let t = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.evaluateWarnings() }
        }
        RunLoop.main.add(t, forMode: .common)
        evalTimer = t
        evaluateWarnings()
    }

    func stopMonitoring() {
        evalTimer?.invalidate()
        evalTimer = nil
    }

    func onAppear() {
        if !didWelcome && messages.isEmpty {
            didWelcome = true
            postWelcome()
        }
        startMonitoring()
    }

    func refreshThresholds() {
        thresholds.save()
        startMonitoring()
    }

    private func currentSnapshot() -> SystemSnapshot {
        SystemSnapshot.capture(
            cpu: CPUMonitor.shared,
            gpu: GPUMonitor.shared,
            bat: BatteryMonitor.shared,
            net: NetworkMonitor.shared
        )
    }

    private func postWelcome() {
        let snap = currentSnapshot()
        appendMessage(role: "advisor", text: """
        Hi — I'm your rNitro System Advisor. I read live specs from this Mac and can warn you when temps, CPU, RAM, or GPU cross limits you set.

        \(snap.specsSummary())

        Ask: "my specs", "is my temp ok?", "memory", or tap ⚙ for warning thresholds.
        """)
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        appendMessage(role: "user", text: text)
        inputText = ""
        let reply = answerQuery(text)
        appendMessage(role: "advisor", text: reply)
    }

    func clearHistory() {
        messages = []
        UserDefaults.standard.removeObject(forKey: historyKey)
        didWelcome = false
        postWelcome()
    }

    private func appendMessage(role: String, text: String, isError: Bool = false) {
        messages.append(ChatMessage(role: role, text: text, isError: isError))
        if messages.count > 120 { messages.removeFirst(messages.count - 120) }
        persistHistory()
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let saved = try? JSONDecoder().decode([ChatMessage].self, from: data) else { return }
        messages = saved
        didWelcome = !messages.isEmpty
    }

    private func persistHistory() {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    private func matches(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }

    func answerQuery(_ raw: String) -> String {
        let t = raw.lowercased()
        let snap = currentSnapshot()
        let th = thresholds

        if matches(t, ["spec", "hardware", "my mac", "computer", "chip", "model", "what am i", "machine", "system info"]) {
            return snap.specsDetail()
        }
        if matches(t, ["temp", "temperature", "hot", "overheat", "thermal", "cool", "heat"]) {
            return snap.tempAdvice(thresholds: th)
        }
        if matches(t, ["cpu", "processor", "usage", "load", "core"]) {
            return """
            CPU: \(String(format: "%.0f", snap.cpuUsage))% across \(snap.logicalCores) threads
            Load average (1m): \(String(format: "%.2f", snap.load1))
            Package power: \(String(format: "%.1f", snap.packagePowerW)) W
            Clock estimate: \(String(format: "%.2f", snap.boostClockGHz)) GHz
            Your CPU alert threshold: \(Int(th.cpuWarning))%
            \(snap.cpuUsage >= th.cpuWarning ? "Status: above your CPU warning level." : "Status: within your CPU warning level.")
            """
        }
        if matches(t, ["ram", "memory", "mem"]) {
            return """
            Memory: \(String(format: "%.1f", snap.ramUsedGB)) / \(String(format: "%.1f", snap.ramTotalGB)) GB (\(String(format: "%.0f", snap.ramPercent))%)
            Pressure: \(snap.memoryPressure)
            Your RAM alert threshold: \(Int(th.ramWarning))%
            \(snap.ramPercent >= th.ramWarning ? "Tip: quit unused apps or check Activity Monitor for memory hogs." : "Status: within your RAM warning level.")
            """
        }
        if matches(t, ["gpu", "graphics", "metal"]) {
            return """
            GPU utilization: \(String(format: "%.0f", snap.gpuUsage))%
            Your GPU alert threshold: \(Int(th.gpuWarning))%
            \(snap.gpuUsage >= th.gpuWarning ? "Status: GPU is busy — normal during games/video export." : "Status: within your GPU warning level.")
            """
        }
        if matches(t, ["battery", "power", "charge", "plug"]) {
            guard snap.batteryPresent else { return "No battery detected — desktop Mac or battery info unavailable." }
            let src = snap.batteryOnAC ? "on AC power" : (snap.batteryCharging ? "charging" : "on battery")
            return """
            Battery: \(snap.batteryPercent)% (\(src))
            Low-battery alert: \(Int(th.batteryLow))%
            \(snap.batteryPercent <= Int(th.batteryLow) && !snap.batteryOnAC ? "Status: below your low-battery threshold — plug in soon." : "Status: battery level OK vs your threshold.")
            """
        }
        if matches(t, ["disk", "storage", "ssd", "free space"]) {
            return """
            Volume: \(snap.diskVolumeName)
            Used: \(String(format: "%.0f", snap.diskUsedPercent))% · free \(String(format: "%.1f", snap.diskFreeGB)) GB
            \(snap.diskFreeGB < 20 ? "Tip: less than 20 GB free can slow macOS — clear caches or move files." : "Status: plenty of free space.")
            """
        }
        if matches(t, ["network", "wifi", "internet", "download", "upload"]) {
            return """
            Network throughput (recent sample):
            Download: \(String(format: "%.1f", snap.networkDownMbps)) Mbps
            Upload: \(String(format: "%.1f", snap.networkUpMbps)) Mbps
            """
        }
        if matches(t, ["warn", "alert", "threshold", "limit", "custom", "setting"]) {
            return """
            Your warning thresholds:
            • Temp warn \(Int(th.tempWarning))°C · critical \(Int(th.tempCritical))°C
            • CPU \(Int(th.cpuWarning))% · RAM \(Int(th.ramWarning))% · GPU \(Int(th.gpuWarning))%
            • Battery low \(Int(th.batteryLow))%
            • Proactive alerts: \(th.proactiveEnabled ? "on" : "off")
            • Critical temp banners: \(th.criticalTempBannersEnabled ? "on" : "off")

            Tap ⚙ in the Advisor tab to change these. I post alerts here when values cross your limits (90s cooldown per alert type). Critical temps also trigger macOS notification banners when enabled.
            """
        }
        if matches(t, ["help", "what can", "how do"]) {
            return """
            I can answer questions about YOUR Mac using live rNitro readings:
            • specs / hardware
            • temperature & thermal state
            • CPU, RAM, GPU, battery, disk, network
            • your custom warning thresholds

            Proactive warnings appear automatically when proactive alerts are enabled in Settings → Alerts. Critical temperatures can also show macOS notification banners.
            """
        }
        return """
        I'm not sure about that. Try:
        • "my specs"
        • "is my temp ok?"
        • "memory" / "cpu" / "gpu"
        • "warnings" (see your thresholds)
        Or tap ⚙ to customize temperature and usage alerts.
        """
    }

    func evaluateWarnings() {
        guard thresholds.proactiveEnabled else {
            activeWarnings = []
            return
        }
        let snap = currentSnapshot()
        var next = Set<AdvisorWarningKind>()

        if snap.temperature >= thresholds.tempCritical { next.insert(.tempCritical) }
        else if snap.temperature >= thresholds.tempWarning { next.insert(.tempWarning) }

        if snap.cpuUsage >= thresholds.cpuWarning { next.insert(.cpuHigh) }
        if snap.ramPercent >= thresholds.ramWarning { next.insert(.ramHigh) }
        if snap.gpuUsage >= thresholds.gpuWarning { next.insert(.gpuHigh) }

        if snap.batteryPresent && !snap.batteryOnAC && snap.batteryPercent <= Int(thresholds.batteryLow) {
            next.insert(.batteryLow)
        }
        if snap.thermalState == .serious || snap.thermalState == .critical {
            next.insert(.thermalPressure)
        }

        let now = Date()
        for kind in next {
            guard shouldPost(kind, at: now) else { continue }
            if let text = warningText(kind: kind, snap: snap) {
                let role = (kind == .tempCritical || kind == .thermalPressure) ? "critical" : "warning"
                appendMessage(role: role, text: text, isError: role == "critical")
                lastWarningPosted[kind] = now
                postCriticalBannerIfNeeded(kind: kind, snap: snap)
            }
        }
        activeWarnings = next
    }

    private func postCriticalBannerIfNeeded(kind: AdvisorWarningKind, snap: SystemSnapshot) {
        guard thresholds.criticalTempBannersEnabled else { return }
        switch kind {
        case .tempCritical:
            AdvisorNotificationCenter.postCriticalTemp(current: snap.temperature, limit: thresholds.tempCritical)
        case .thermalPressure where snap.thermalState == .critical:
            AdvisorNotificationCenter.postMacOSThermalCritical(
                temp: snap.temperature,
                stateLabel: CPUMonitor.thermalLabel(snap.thermalState)
            )
        default:
            break
        }
    }

    private func shouldPost(_ kind: AdvisorWarningKind, at now: Date) -> Bool {
        guard let last = lastWarningPosted[kind] else { return true }
        return now.timeIntervalSince(last) >= warningCooldown
    }

    private func warningText(kind: AdvisorWarningKind, snap: SystemSnapshot) -> String? {
        switch kind {
        case .tempCritical:
            return "CRITICAL: CPU temp \(String(format: "%.1f", snap.temperature))°C exceeds your \(Int(thresholds.tempCritical))°C limit. Ease load or improve cooling."
        case .tempWarning:
            return "Warning: CPU temp \(String(format: "%.1f", snap.temperature))°C is above your \(Int(thresholds.tempWarning))°C warning threshold."
        case .cpuHigh:
            return "Warning: CPU usage \(String(format: "%.0f", snap.cpuUsage))% exceeded your \(Int(thresholds.cpuWarning))% threshold."
        case .ramHigh:
            return "Warning: RAM usage \(String(format: "%.0f", snap.ramPercent))% exceeded your \(Int(thresholds.ramWarning))% threshold."
        case .gpuHigh:
            return "Warning: GPU usage \(String(format: "%.0f", snap.gpuUsage))% exceeded your \(Int(thresholds.gpuWarning))% threshold."
        case .batteryLow:
            return "Warning: Battery at \(snap.batteryPercent)% — below your \(Int(thresholds.batteryLow))% low-battery threshold. Plug in if you can."
        case .thermalPressure:
            return "Warning: macOS reports thermal pressure (\(CPUMonitor.thermalLabel(snap.thermalState))). CPU may throttle soon."
        }
    }
}

struct SystemAdvisorView: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var advisor = SystemAdvisorModel.shared
    var compact: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            advisorHeader
            chatArea
            inputBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg)
        .onAppear { advisor.onAppear() }
    }

    private var advisorHeader: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("System Advisor").font(rNitroFont(metrics.compact ? .label : .body, metrics: metrics, weight: .semibold))
                    if CPUMonitor.shared.isLowPowerModeEnabled {
                        LowPowerModeBadge(compact: true)
                    }
                    if !advisor.activeWarnings.isEmpty {
                        Circle().fill(Color.nOrange).frame(width: 7, height: 7)
                    }
                }
                Text("Live specs · alert thresholds in Settings → Alerts")
                    .font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
            }
            Spacer()
            if !advisor.messages.isEmpty {
                Button("Clear") { advisor.clearHistory() }
                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary).buttonStyle(.plain)
            }
            if !compact {
                Button("Alert settings") { openAlertsSettings() }
                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.accent).buttonStyle(.plain)
            }
        }
        .padding(.horizontal, compact ? 10 : 14)
        .padding(.vertical, compact ? 6 : 8)
    }

    private func openAlertsSettings() {
        NotificationCenter.default.post(
            name: .rNitroOpenMainWindow,
            object: nil,
            userInfo: ["tab": AppTab.settings.rawValue, "settingsSection": SettingsSection.alerts.rawValue]
        )
    }

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(advisor.messages) { msg in
                        advisorBubble(msg).id(msg.id)
                    }
                }
                .padding(compact ? 10 : 14)
            }
            .onReceive(advisor.$messages) { messages in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private func advisorBubble(_ msg: ChatMessage) -> some View {
        let isUser = msg.role == "user"
        let isWarn = msg.role == "warning"
        let isCrit = msg.role == "critical" || msg.isError
        let bg: Color = isCrit ? Color.nRed.opacity(0.18) : (isWarn ? Color.nOrange.opacity(0.15) : (isUser ? Color.accent.opacity(0.15) : Color.card))
        let fg: Color = isCrit ? .nRed : (isWarn ? .nOrange : (isUser ? .primary : .secondary))
        return HStack {
            if isUser { Spacer(minLength: metrics.bubbleSpacer) }
            Text(msg.text)
                .font(rNitroFont(.label, metrics: metrics))
                .foregroundColor(fg)
                .padding(10)
                .background(bg)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.border.opacity(0.35), lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            if !isUser { Spacer(minLength: metrics.bubbleSpacer) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask about your Mac…", text: $advisor.inputText)
                .textFieldStyle(.plain)
                .font(rNitroFont(.body, metrics: metrics))
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.border.opacity(0.5), lineWidth: 1))
                .onSubmit { advisor.sendMessage() }
            MinimalButton(
                title: "Send",
                disabled: advisor.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                action: { advisor.sendMessage() }
            )
            .fixedSize()
        }
        .padding(compact ? 8 : 12)
    }
}

enum ContentLayout { case window, popover }

struct UsageBarRow: View {
    @Environment(\.uiMetrics) private var metrics
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
                    Text(label).font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", usedPercent)).font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
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
                .font(rNitroFont(.caption, metrics: metrics))
                .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

struct StatCell: View {
    @Environment(\.uiMetrics) private var metrics
    let title: String; let value: String; let unit: String; let color: Color
    var action: (() -> Void)? = nil
    var body: some View {
        Button(action: { action?() }) {
            VStack(spacing: 3) {
                Text(title).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary).tracking(0.5)
                    .lineLimit(1).minimumScaleFactor(0.85)
                Text(value).font(rNitroFont(.statValue, metrics: metrics, weight: .semibold)).foregroundColor(color)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(unit).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary.opacity(0.8))
                    .lineLimit(1).minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

struct ExpandedStatPanel: View {
    @Environment(\.uiMetrics) private var metrics
    let title: String
    let value: String
    let unit: String
    let subtitle: String?
    let color: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            VStack(spacing: 5) {
                Text(title)
                    .font(rNitroFont(.label, metrics: metrics))
                    .foregroundColor(.secondary)
                    .tracking(0.6)
                    .lineLimit(1)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(rNitroFont(.title, metrics: metrics, weight: .semibold))
                        .foregroundColor(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(rNitroFont(.body, metrics: metrics))
                            .foregroundColor(.secondary.opacity(0.85))
                            .lineLimit(1)
                    }
                }
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(rNitroFont(.caption, metrics: metrics))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .frame(maxWidth: .infinity, minHeight: metrics.compact ? 64 : 76)
            .padding(.vertical, metrics.compact ? 6 : 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

struct LowPowerModeBadge: View {
    @Environment(\.uiMetrics) private var metrics
    var compact: Bool = false

    private var accent: Color { Color(red: 0.55, green: 0.88, blue: 0.42) }

    var body: some View {
        HStack(spacing: compact ? 3 : 4) {
            Image(systemName: "leaf.fill")
                .font(.system(size: compact ? 9 : 10, weight: .semibold))
            Text(compact ? "LP" : "Low Power")
        }
        .font(rNitroFont(compact ? .micro : .caption, metrics: metrics, weight: .semibold))
        .foregroundColor(accent)
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(accent.opacity(0.14))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(accent.opacity(0.45), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .help("macOS Low Power Mode is on — CPU clocks and background work may be reduced.")
    }
}

struct BatteryCpuPowerRow: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject var bat: BatteryMonitor
    @ObservedObject var monitor: CPUMonitor
    var onBatteryTap: (() -> Void)? = nil
    var onCpuPowerTap: (() -> Void)? = nil

    private var chargeUnit: String {
        bat.isCharging ? "charging" : (bat.isOnAC ? "plugged in" : (bat.isPresent ? "on battery" : "desktop"))
    }

    private var cpuSubtitle: String {
        guard bat.isPresent else { return String(format: "%.0f%% load", monitor.totalUsage) }
        return bat.isCharging ? "charging" : (bat.isOnAC ? "on AC" : "on battery")
    }

    var body: some View {
        HStack(alignment: .top, spacing: metrics.compact ? 8 : 12) {
            ExpandedStatPanel(
                title: "BATTERY",
                value: bat.isPresent ? "\(bat.levelPercent)" : "—",
                unit: "%",
                subtitle: bat.remainingTimeText.map { "left \($0)" },
                color: bat.isCharging ? .nGreen : .accent,
                action: onBatteryTap
            )
            ExpandedStatPanel(
                title: "CHARGE",
                value: bat.isPresent ? bat.chargeRateText : "N/A",
                unit: "",
                subtitle: chargeUnit,
                color: bat.isCharging ? .nOrange : .secondary,
                action: onBatteryTap
            )
            ExpandedStatPanel(
                title: "CPU",
                value: String(format: "%.1f", monitor.packagePowerWatts),
                unit: "W",
                subtitle: cpuSubtitle,
                color: Color.usage(monitor.totalUsage),
                action: onCpuPowerTap
            )
        }
        .frame(maxWidth: .infinity)
    }
}

struct NetworkMonitorRow: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject var net: NetworkMonitor

    var body: some View {
        HStack(spacing: metrics.compact ? 8 : 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(HardwareLabelMapper.networkInterface(net.interfaceName)).font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                Text(net.isAvailable ? net.interfaceName : "No link")
                    .font(rNitroFont(.caption, metrics: metrics))
                    .foregroundColor(.secondary.opacity(0.85))
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            HStack(spacing: metrics.compact ? 10 : 14) {
                HStack(spacing: 4) {
                    Text("↓").font(rNitroFont(.caption, metrics: metrics, weight: .semibold)).foregroundColor(.accent)
                    Text(NetworkMonitor.formatSpeed(net.downloadMbps))
                        .font(rNitroFont(.label, metrics: metrics, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                HStack(spacing: 4) {
                    Text("↑").font(rNitroFont(.caption, metrics: metrics, weight: .semibold)).foregroundColor(.nGreen)
                    Text(NetworkMonitor.formatSpeed(net.uploadMbps))
                        .font(rNitroFont(.label, metrics: metrics, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatDetailPopup: View {
    @Environment(\.uiMetrics) private var metrics
    let kind: StatDetailKind
    @ObservedObject var monitor: CPUMonitor
    @ObservedObject var battery: BatteryMonitor
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    private func close() {
        if let onClose { onClose() } else { dismiss() }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(popupTitle).font(rNitroFont(.headline, metrics: metrics, weight: .semibold))
                Spacer()
                Button("Close", action: close)
                    .font(rNitroFont(.body, metrics: metrics))
                    .foregroundColor(.secondary)
                    .buttonStyle(.plain)
            }
            MinimalDivider()
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if kind == .cpuPower {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CPU power (last ~60s)")
                                .font(rNitroFont(.caption, metrics: metrics))
                                .foregroundColor(.secondary)
                            PowerGraphView(
                                history: monitor.powerHistory,
                                color: Color.usage(monitor.totalUsage),
                                maxWatts: max(
                                    CPUMonitor.chipPowerCeiling(monitor.cpuName) * 1.2,
                                    monitor.powerHistory.max() ?? 0,
                                    8
                                )
                            )
                            .frame(height: metrics.graphHeight)
                        }
                        MinimalDivider()
                    }
                    ForEach(detailRows, id: \.0) { row in
                        HStack(alignment: .top, spacing: 10) {
                            Text(row.0).font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary).frame(minWidth: 72, maxWidth: 120, alignment: .leading)
                            Text(row.1).font(rNitroFont(.label, metrics: metrics)).frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(minWidth: 260, idealWidth: 340, maxWidth: 420, minHeight: 300, idealHeight: 400, maxHeight: 520)
        .background(Color.bg)
        .contentShape(Rectangle())
    }

    private var popupTitle: String {
        switch kind {
        case .clock: return "Clock Speed Details"
        case .temperature: return "Temperature Details"
        case .cores: return "Core & Thread Details"
        case .memory: return "Memory Details"
        case .storage: return "Storage Details"
        case .battery: return "Battery Details"
        case .cpuPower: return "SoC Power Details"
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
                ("Nominal Range", "42–97 °C (scales with CPU load)"),
                ("Fair Range", "48–86 °C under moderate thermal pressure"),
                ("Serious/Critical", "58–90 °C — thermal throttling likely")
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
                ("Pressure", monitor.memoryPressure),
                ("Wired", String(format: "%.1f GB", monitor.memoryWiredGB)),
                ("Compressed", String(format: "%.1f GB", monitor.memoryCompressedGB)),
                ("Swap", String(format: "%.1f GB", monitor.memorySwapGB)),
                ("Source", "host_statistics64 (active + wired + compressed)")
            ]
        case .battery:
            var rows: [(String, String)] = [
                ("Level", battery.isPresent ? "\(battery.levelPercent)%" : "N/A"),
                ("Power Source", battery.powerSource),
                ("AC Connected", battery.isOnAC ? "Yes" : "No"),
                ("Charging", battery.isCharging ? "Yes" : "No"),
                ("Charge Rate", battery.chargeRateText)
            ]
            if battery.chargeWatts > 0 {
                rows.append(("Adapter Power", String(format: "%.1f W", battery.chargeWatts)))
            }
            if let eta = battery.timeToFullMinutes, eta > 0 {
                rows.append(("Time to Full", "\(eta) min"))
            }
            if let rem = battery.remainingTimeText {
                rows.append(("Time Remaining", rem))
            }
            if monitor.isLowPowerModeEnabled {
                rows.append(("Low Power Mode", "On — clocks/background work may be reduced"))
            }
            rows.append(("Source", "pmset + ioreg (macOS)"))
            return rows
        case .cpuPower:
            let measured = monitor.packagePowerSource.contains("measured")
            let ceiling = CPUMonitor.chipPowerCeiling(monitor.cpuName)
            var rows: [(String, String)] = [
                ("CPU Power", String(format: "%.1f W", monitor.packagePowerWatts)),
            ]
            if measured {
                rows.append(("GPU Power", String(format: "%.1f W", monitor.gpuPowerWatts)))
                rows.append(("ANE Power", String(format: "%.1f W", monitor.anePowerWatts)))
                rows.append(("SoC Total", String(format: "%.1f W", monitor.socPowerWatts)))
            }
            rows += [
                ("Reading", measured ? "Measured (IOReport)" : "Estimated from load"),
                ("Data Source", monitor.packagePowerSource),
                ("CPU Load", String(format: "%.1f%%", monitor.totalUsage)),
                ("Thermal State", CPUMonitor.thermalLabel(monitor.thermalState)),
                ("Chip", monitor.cpuName),
                ("Typical Ceiling", String(format: "~%.0f W", ceiling)),
                ("IOReport", IOReportPowerReader.shared.isAvailable ? "Available" : "Unavailable (using estimate)")
            ]
            if measured {
                rows.append(("Method", "Apple Energy Model (CPU + GPU + ANE, no sudo)"))
            } else {
                rows.append(("Method", "Load × clock × chip profile estimate"))
            }
            rows.append(("Boost Clock", String(format: "%.0f MHz", monitor.boostClock)))
            if battery.isPresent {
                rows.append(("Power Context", battery.isOnAC ? "Plugged in" : (battery.isCharging ? "Charging" : "On battery")))
            }
            if monitor.isLowPowerModeEnabled {
                rows.append(("Low Power Mode", "On — expect lower clocks under load"))
            }
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

enum FontRole {
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
    .custom(RNITRO_UI_FONT, size: metrics.size(role)).weight(weight)
}

struct MetricsReader<Content: View>: View {
    let layout: ContentLayout
    @ViewBuilder let content: (UIMetrics) -> Content

    var body: some View {
        GeometryReader { geo in
            let metrics = UIMetrics.forWidth(geo.size.width, layout: layout)
            content(metrics)
                .frame(width: geo.size.width, height: geo.size.height)
                .environment(\.uiMetrics, metrics)
        }
    }
}

struct ResponsiveStatGrid<Content: View>: View {
    @Environment(\.uiMetrics) private var metrics
    @ViewBuilder let content: () -> Content

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: metrics.statCellMin), spacing: 0)],
            spacing: 8,
            content: content
        )
    }
}

enum MonitorPreferences {
    static let soloModeKey = "rnitro.soloMode"
    static let classicScrollKey = "rnitro.classicScrollMode"
    static let showWeatherKey = "rnitro.showWeather"

    static let stressKey = "rnitro.showStressUI"
    static let benchmarkKey = "rnitro.showBenchmarkUI"
    static let networkKey = "rnitro.showNetworkUI"
    static let menuBarModeKey = "rnitro.menuBarMode"
    static let menuBarLayoutKey = "rnitro.menuBarLayout"
    static let menuBarSlotsKey = "rnitro.menuBarSlots"
    static let uiStyleKey = "rnitro.uiStyle"
    static let launchAtLoginKey = "rnitro.launchAtLogin"
    static let firstLaunchTipsKey = "rnitro.firstLaunchTipsSeen"
}

enum FirstLaunchTips {
    static var shouldShow: Bool {
        !UserDefaults.standard.bool(forKey: MonitorPreferences.firstLaunchTipsKey)
    }

    static func markSeen() {
        UserDefaults.standard.set(true, forKey: MonitorPreferences.firstLaunchTipsKey)
    }
}

struct FirstLaunchTipsSheet: View {
    @Environment(\.uiMetrics) private var metrics
    @Binding var isPresented: Bool

    private func tipRow(_ n: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n)
                .font(rNitroFont(.caption, metrics: metrics, weight: .bold))
                .foregroundColor(.accent)
                .frame(width: 20, height: 20)
                .background(Color.accent.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(rNitroFont(.label, metrics: metrics, weight: .semibold))
                Text(detail).font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to rNitro")
                .font(rNitroFont(.title, metrics: metrics, weight: .semibold))
            Text("Quick start — takes 10 seconds.")
                .font(rNitroFont(.caption, metrics: metrics))
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 12) {
                tipRow("1", "Find the menubar icon", "rNitro lives in the top-right menu bar. Click it anytime for live CPU, temp, and per-core stats.")
                tipRow("2", "First launch on macOS", "If Gatekeeper blocks the app: right-click rNitro.app → Open → Open once. No admin password needed for the App ZIP.")
                tipRow("3", "Recommended install", "App ZIP from getrnitro.netlify.app — unzip, drag to Applications, then use right-click → Open if prompted.")
            }
            Button(action: {
                FirstLaunchTips.markSeen()
                isPresented = false
            }) {
                Text("Got it — open monitor")
                    .font(rNitroFont(.body, metrics: metrics, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .background(Color.accent.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(20)
        .frame(maxWidth: 360)
        .background(Color.bg)
    }
}

enum MonitorUIStyle: String, CaseIterable, Identifiable {
    case modern, legacy

    var id: String { rawValue }

    var label: String {
        switch self {
        case .modern: return "Modern (iStats-style)"
        case .legacy: return "Legacy"
        }
    }
}

enum LaunchAtLoginManager {
    static func isEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return UserDefaults.standard.bool(forKey: MonitorPreferences.launchAtLoginKey)
    }

    @discardableResult
    static func setEnabled(_ on: Bool) -> Bool {
        guard #available(macOS 13.0, *) else { return false }
        do {
            if on { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            UserDefaults.standard.set(on, forKey: MonitorPreferences.launchAtLoginKey)
            return true
        } catch {
            return false
        }
    }
}

enum MenuBarSlot: String, CaseIterable, Identifiable {
    case cpu, temp, ram, power, network, battery, btc

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cpu: return "CPU"
        case .temp: return "Temp"
        case .ram: return "RAM"
        case .power: return "Power"
        case .network: return "Network"
        case .battery: return "Battery"
        case .btc: return "Bitcoin"
        }
    }

    var shortLabel: String {
        switch self {
        case .cpu: return "CPU"
        case .temp: return "TEMP"
        case .ram: return "RAM"
        case .power: return "PWR"
        case .network: return "NET"
        case .battery: return "BAT"
        case .btc: return "BTC"
        }
    }
}

enum MenuBarLayout: String, CaseIterable, Identifiable {
    case combined, inline, minimal

    var id: String { rawValue }

    var label: String {
        switch self {
        case .combined: return "Compact"
        case .inline: return "Inline"
        case .minimal: return "Minimal"
        }
    }
}

enum MenuBarConfig {
    static let defaultSlots: [MenuBarSlot] = [.cpu, .temp, .power]

    static var layout: MenuBarLayout {
        MenuBarLayout(rawValue: UserDefaults.standard.string(forKey: MonitorPreferences.menuBarLayoutKey) ?? "") ?? .inline
    }

    static func setLayout(_ layout: MenuBarLayout) {
        UserDefaults.standard.set(layout.rawValue, forKey: MonitorPreferences.menuBarLayoutKey)
        NotificationCenter.default.post(name: .menuBarModeChanged, object: nil)
    }

    static var enabledSlots: [MenuBarSlot] {
        if let saved = UserDefaults.standard.stringArray(forKey: MonitorPreferences.menuBarSlotsKey) {
            let slots = saved.compactMap(MenuBarSlot.init(rawValue:))
            if !slots.isEmpty { return slots }
        }
        if let legacy = UserDefaults.standard.string(forKey: MonitorPreferences.menuBarModeKey) {
            switch legacy {
            case "full": return [.btc, .cpu, .temp]
            case "cpuTemp": return [.cpu, .temp]
            case "cpuOnly": return [.cpu]
            case "cpuPower": return [.cpu, .power]
            case "battery": return [.battery]
            case "minimal": return [.cpu]
            default: break
            }
        }
        return defaultSlots
    }

    static func setSlot(_ slot: MenuBarSlot, enabled: Bool) {
        var slots = enabledSlots
        if enabled {
            if !slots.contains(slot) { slots.append(slot) }
        } else {
            slots.removeAll { $0 == slot }
        }
        if slots.isEmpty { slots = [.cpu] }
        UserDefaults.standard.set(slots.map(\.rawValue), forKey: MonitorPreferences.menuBarSlotsKey)
        NotificationCenter.default.post(name: .menuBarModeChanged, object: nil)
    }

    static func isSlotEnabled(_ slot: MenuBarSlot) -> Bool {
        enabledSlots.contains(slot)
    }
}

extension Notification.Name {
    static let menuBarModeChanged = Notification.Name("rnitro.menuBarModeChanged")
}

enum MenuBarStatusFormatter {
    static func slotLabel(_ slot: MenuBarSlot) -> String {
        let cpu = CPUMonitor.shared
        let bat = BatteryMonitor.shared
        let net = NetworkMonitor.shared
        switch slot {
        case .cpu: return "\(Int(cpu.totalUsage.rounded()))%"
        case .temp: return "\(Int(cpu.temperature.rounded()))°"
        case .ram: return "\(Int(cpu.memoryUsedPercent.rounded()))%"
        case .power: return String(format: "%.1fW", cpu.packagePowerWatts)
        case .network:
            if !net.isAvailable { return "—" }
            return "↓\(NetworkMonitor.formatSpeed(net.downloadMbps).replacingOccurrences(of: " ", with: ""))"
        case .battery:
            guard bat.isPresent else { return "—" }
            return bat.isCharging ? "\(bat.levelPercent)%⚡" : "\(bat.levelPercent)%"
        case .btc:
            if let p = BTCPriceMonitor.shared.priceUSD {
                return String(format: "$%.0fk", p / 1000)
            }
            return "…"
        }
    }

    static func render(layout: MenuBarLayout) -> String {
        let slots = MenuBarConfig.enabledSlots
        let cpu = CPUMonitor.shared
        switch layout {
        case .minimal:
            return "\(Int(cpu.totalUsage.rounded()))%"
        case .inline, .combined:
            // Single-line values only — stacked labels clip in the macOS menu bar.
            if slots.isEmpty { return "\(Int(cpu.totalUsage.rounded()))%" }
            return slots.map { slotLabel($0) }.joined(separator: " · ")
        }
    }
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
    private var workers: [DispatchWorkItem] = []
    private let queue = DispatchQueue(label: "rnitro.stresstest", attributes: .concurrent)

    private init() { stop() }

    func start() {
        guard !isRunning else { return }
        stop()
        isRunning = true
        stopFlag = false
        elapsedSeconds = 0

        let threadCount = max(1, CPUMonitor.shared.logicalCores)
        workers.removeAll(keepingCapacity: true)
        for _ in 0..<threadCount {
            var item: DispatchWorkItem!
            item = DispatchWorkItem { [weak self] in
                var x: Double = 1.0001
                while let self, !self.stopFlag, !(item?.isCancelled ?? true) {
                    for _ in 0..<50_000 { x = (x * 1.0000001).squareRoot() }
                }
                _ = x
            }
            workers.append(item)
            queue.async(execute: item)
        }

        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        stopFlag = true
        isRunning = false
        timer?.invalidate()
        timer = nil
        elapsedSeconds = 0
        for w in workers { w.cancel() }
        workers.removeAll()
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
    var appBytes: Int64?
    var lastUsed: Date?
    var leftovers: [AppLeftover] = []
    var leftoversLoaded = false

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
    @Published var displayedApps: [InstalledApp] = []
    @Published var isScanning = false
    @Published var search = ""
    @Published var sort: AppCleanerSort = .lastUsed
    @Published var leftoversReadyForPath: String?
    @Published var isEnrichingLastUsed = false
    private var scanGeneration = 0

    func scan() {
        scanGeneration += 1
        let generation = scanGeneration
        isScanning = true
        DispatchQueue.global(qos: .userInitiated).async {
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
                    let app = InstalledApp(
                        id: path, name: name, path: path, bundleId: bid, icon: icon,
                        appBytes: nil, lastUsed: nil, leftovers: [], leftoversLoaded: false
                    )
                    found.append(app)
                }
            }
            DispatchQueue.main.async {
                guard generation == self.scanGeneration else { return }
                self.apps = found
                self.isScanning = false
                self.rebuildDisplayed()
                self.enrichInBackground(generation: generation)
            }
        }
    }

    func rebuildDisplayed() {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var list = apps
        if !q.isEmpty {
            list = list.filter {
                $0.name.lowercased().contains(q)
                    || $0.bundleId.lowercased().contains(q)
                    || $0.path.lowercased().contains(q)
            }
        }
        switch sort {
        case .lastUsed:
            list.sort { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
        case .name:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .size:
            list.sort {
                let a = Int64($0.appBytes ?? 0) + $0.totalLeftoverBytes
                let b = Int64($1.appBytes ?? 0) + $1.totalLeftoverBytes
                return a > b
            }
        }
        displayedApps = list
    }

    func patchApp(path: String, appBytes: Int64? = nil, lastUsed: Date? = nil,
                  leftovers: [AppLeftover]? = nil, leftoversLoaded: Bool? = nil) {
        guard let idx = apps.firstIndex(where: { $0.path == path }) else { return }
        var updated = apps[idx]
        if let appBytes { updated.appBytes = appBytes }
        if let lastUsed { updated.lastUsed = lastUsed }
        if let leftovers { updated.leftovers = leftovers }
        if let leftoversLoaded {
            updated.leftoversLoaded = leftoversLoaded
            if leftoversLoaded { leftoversReadyForPath = path }
        }
        var copy = apps
        copy[idx] = updated
        apps = copy
        rebuildDisplayed()
    }

    func removeApp(path: String) {
        apps.removeAll { $0.path == path }
        rebuildDisplayed()
    }

    func loadLeftovers(for app: InstalledApp) {
        guard !app.leftoversLoaded else { return }
        let path = app.path
        let generation = scanGeneration
        DispatchQueue.global(qos: .utility).async {
            let leftovers = Self.findLeftovers(bundleId: app.bundleId, appName: app.name)
            DispatchQueue.main.async {
                guard generation == self.scanGeneration else { return }
                self.patchApp(path: path, leftovers: leftovers, leftoversLoaded: true)
            }
        }
    }

    private func enrichInBackground(generation: Int) {
        let snapshot: [(path: String, bundleId: String)] = apps.map { ($0.path, $0.bundleId) }
        guard !snapshot.isEmpty else { return }
        DispatchQueue.global(qos: .utility).async {
            let sizeQueue = DispatchQueue(label: "rnitro.appcleaner.size", attributes: .concurrent)
            let group = DispatchGroup()
            let sem = DispatchSemaphore(value: 4)
            for item in snapshot {
                group.enter()
                sizeQueue.async {
                    defer { group.leave() }
                    sem.wait()
                    defer { sem.signal() }
                    let bytes = Self.fastPathBytes(item.path)
                    DispatchQueue.main.async {
                        guard generation == self.scanGeneration else { return }
                        self.patchApp(path: item.path, appBytes: bytes)
                    }
                }
            }
            group.wait()

            DispatchQueue.main.async {
                guard generation == self.scanGeneration else { return }
                self.isEnrichingLastUsed = true
            }
            let dateQueue = DispatchQueue(label: "rnitro.appcleaner.dates", attributes: .concurrent)
            for item in snapshot {
                group.enter()
                dateQueue.async {
                    defer { group.leave() }
                    sem.wait()
                    defer { sem.signal() }
                    let date = Self.resolveLastUsed(path: item.path, bundleId: item.bundleId)
                    DispatchQueue.main.async {
                        guard generation == self.scanGeneration else { return }
                        if let date { self.patchApp(path: item.path, lastUsed: date) }
                    }
                }
            }
            group.wait()
            DispatchQueue.main.async {
                guard generation == self.scanGeneration else { return }
                self.isEnrichingLastUsed = false
            }
        }
    }

    static func fastPathBytes(_ path: String) -> Int64 {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/du")
        proc.arguments = ["-sk", path]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        guard (try? proc.run()) != nil else { return modDateBytes(path) }
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return modDateBytes(path) }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let line = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\t").first,
              let kb = Int64(line) else { return modDateBytes(path) }
        return kb * 1024
    }

    private static func modDateBytes(_ path: String) -> Int64 {
        guard let sz = (try? FileManager.default.attributesOfItem(atPath: path))?[.size] as? Int64 else { return 0 }
        return sz
    }

    private static let lastUsedFormatters: [DateFormatter] = {
        let fmts = ["yyyy-MM-dd HH:mm:ss Z", "yyyy-MM-dd HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ssZ"]
        return fmts.map {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = $0
            return f
        }
    }()

    static func resolveLastUsed(path: String, bundleId: String) -> Date? {
        var candidates: [Date] = []
        let keys = ["kMDItemLastUsedDate", "kMDItemContentAccessDate"]
        for key in keys {
            if let d = mdlsDate(path: path, attribute: key) { candidates.append(d) }
        }
        if let bundle = Bundle(path: path), let exe = bundle.executableURL?.path {
            for key in keys {
                if let d = mdlsDate(path: exe, attribute: key) { candidates.append(d) }
            }
        }
        for spotPath in spotlightPaths(bundleId: bundleId) where spotPath != path {
            for key in keys {
                if let d = mdlsDate(path: spotPath, attribute: key) { candidates.append(d) }
            }
        }
        return candidates.max()
    }

    private static func mdlsDate(path: String, attribute: String) -> Date? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/mdls")
        proc.arguments = ["-name", attribute, "-raw", path]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        try? proc.run()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty, raw != "(null)" else { return nil }
        for f in lastUsedFormatters {
            if let d = f.date(from: raw) { return d }
        }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: raw) { return d }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: raw)
    }

    private static func spotlightPaths(bundleId: String) -> [String] {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        proc.arguments = ["kMDItemCFBundleIdentifier == '\(bundleId)'"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        try? proc.run()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let raw = String(data: data, encoding: .utf8) else { return [] }
        return raw.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    static func findLeftovers(bundleId: String, appName: String) -> [AppLeftover] {
        let home = NSHomeDirectory()
        let candidates: [(String, String)] = [
            ("\(home)/Library/Caches/\(bundleId)", "Caches"),
            ("\(home)/Library/Preferences/\(bundleId).plist", "Preferences"),
            ("\(home)/Library/Application Support/\(appName)", "Application Support"),
            ("\(home)/Library/Containers/\(bundleId)", "Container"),
        ]
        var out: [AppLeftover] = []
        let fm = FileManager.default
        for (path, label) in candidates where fm.fileExists(atPath: path) {
            out.append(AppLeftover(id: path, path: path, label: label, bytes: fastPathBytes(path)))
        }
        return out
    }

    func moveToTrash(_ paths: [String]) -> String? {
        let fm = FileManager.default
        for p in paths {
            let url = URL(fileURLWithPath: p)
            do { try fm.trashItem(at: url, resultingItemURL: nil) }
            catch { return "Could not move \(p) to Trash" }
        }
        return nil
    }
}

struct AppCleanerView: View {
    @Environment(\.uiMetrics) private var metrics
    @StateObject private var model = AppCleanerModel()
    @State private var selected: InstalledApp?
    @State private var selectedLeftovers: Set<String> = []
    @State private var alertMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TextField("Search apps", text: $model.search)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Picker("Sort", selection: $model.sort) {
                    ForEach(AppCleanerSort.allCases) { s in Text(s.rawValue).tag(s) }
                }
                .pickerStyle(.menu)
                .frame(width: 110)
                MinimalButton(title: model.isScanning ? "Scanning…" : "Rescan", tint: .nBlue, disabled: model.isScanning, action: { model.scan() })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if model.isScanning {
                Text("Scanning…").font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
            } else if model.displayedApps.isEmpty {
                Text(model.search.isEmpty ? "No apps found" : "No matches for \"\(model.search)\"")
                    .font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(model.displayedApps) { app in
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
                                    Text(app.appBytes.map(Self.formatBytes) ?? "…")
                                        .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, metrics.hPad).padding(.vertical, 12)
        .onAppear {
            if model.apps.isEmpty { model.scan() }
            else { model.rebuildDisplayed() }
        }
        .onChange(of: model.search) { _, _ in model.rebuildDisplayed() }
        .onChange(of: model.sort) { _, _ in model.rebuildDisplayed() }
        .onChange(of: model.leftoversReadyForPath) { _, path in
            guard let path, selected?.path == path,
                  let cur = model.apps.first(where: { $0.path == path }) else { return }
            selectedLeftovers = Set(cur.leftovers.map(\.id))
            selected = cur
        }
        .sheet(item: $selected) { app in
            cleanerDetail(model.apps.first(where: { $0.id == app.id }) ?? app)
        }
        .alert("App Cleaner", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: { Text(alertMessage ?? "") }
    }

    private func openDetail(_ app: InstalledApp) {
        selected = app
        selectedLeftovers = Set(app.leftovers.map(\.id))
        if !app.leftoversLoaded {
            model.loadLeftovers(for: app)
        }
    }

    private func cleanerDetail(_ app: InstalledApp) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(app.name).font(rNitroFont(.title, metrics: metrics, weight: .semibold))
            Text(app.path).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
            if !app.leftoversLoaded {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.75)
                    Text("Scanning leftovers…").font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                }
            } else if app.leftovers.isEmpty {
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
        paths += app.leftovers.filter { selectedLeftovers.contains($0.id) }.map(\.path)
        if let err = model.moveToTrash(paths) { alertMessage = err }
        else {
            alertMessage = includeApp ? "Moved \(app.name) to Trash" : "Removed selected files"
            selected = nil
            if includeApp {
                model.removeApp(path: app.path)
            } else {
                let remaining = app.leftovers.filter { !selectedLeftovers.contains($0.id) }
                model.patchApp(path: app.path, leftovers: remaining, leftoversLoaded: true)
            }
        }
    }

    private func relativeLastUsed(_ date: Date?) -> String {
        if date == nil {
            return model.isEnrichingLastUsed ? "Last opened (macOS): checking…" : "Last opened (macOS): unknown"
        }
        guard let date else { return "Last opened (macOS): unknown" }
        let rel = RelativeDateTimeFormatter()
        rel.unitsStyle = .short
        let ago = rel.localizedString(for: date, relativeTo: Date())
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return "Last opened (macOS) \(ago) · \(fmt.string(from: date))"
    }

    static func formatBytes(_ b: Int64) -> String {
        if b >= 1_073_741_824 { return String(format: "%.1f GB", Double(b) / 1_073_741_824) }
        if b >= 1_048_576 { return String(format: "%.1f MB", Double(b) / 1_048_576) }
        if b >= 1024 { return String(format: "%.0f KB", Double(b) / 1024) }
        return "\(b) B"
    }
}

extension InstalledApp: Hashable {
    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
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
        default: return "rnitro.sectionExpanded.\(rawValue)"
        }
    }

    static func visiblePanels() -> [MonitorPanel] {
        let order = UserDefaults.standard.stringArray(forKey: "rnitro.panelOrder") ?? allCases.map(\.rawValue)
        return order.compactMap { raw in
            guard let p = MonitorPanel(rawValue: raw) else { return nil }
            let key = "rnitro.panelVisible.\(p.rawValue)"
            if UserDefaults.standard.object(forKey: key) == nil { return p }
            return UserDefaults.standard.bool(forKey: key) ? p : nil
        }
    }
}

struct AppTabSidebar: View {
    @Environment(\.uiMetrics) private var metrics
    let tabs: [AppTab]
    @Binding var tab: AppTab
    var advisorHasWarnings: Bool
    let compact: Bool

    var body: some View {
        VStack(spacing: 4) {
            ForEach(tabs) { t in
                Button(action: { tab = t }) {
                    HStack(spacing: 8) {
                        Image(systemName: t.icon)
                            .frame(width: 16)
                        if !compact {
                            Text(t.rawValue)
                                .font(rNitroFont(.label, metrics: metrics, weight: tab == t ? .semibold : .regular))
                        }
                        if t == .advisor && advisorHasWarnings {
                            Circle().fill(Color.nOrange).frame(width: 6, height: 6)
                        }
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(tab == t ? .accent : .secondary)
                    .padding(.horizontal, compact ? 6 : 10)
                    .padding(.vertical, 8)
                    .background(tab == t ? Color.accent.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .frame(width: compact ? 48 : 156)
        .background(Color.card.opacity(0.35))
    }
}

@MainActor
final class HowItWorksModel: ObservableObject {
    @Published var stableId = "v8.3.2-Final-arm64"
    @Published var betaId = CURRENT_VERSION
    @Published var linuxId = "v0.1-Linux-Beta-Pre-release-x64"
    @Published var windowsId = "v4.2.2-Windows-Final-x86"
    @Published var lastFetched: Date?

    func refresh() {
        var req = URLRequest(url: UPDATE_CHECK_URL)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 8
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let data = data,
                  let info = try? JSONDecoder().decode(VersionInfo.self, from: data) else { return }
            Task { @MainActor in
                self?.stableId = info.latest
                if let beta = info.beta { self?.betaId = beta }
                self?.lastFetched = Date()
            }
        }.resume()
    }
}

private struct HowStatusPill: View {
    @Environment(\.uiMetrics) private var metrics
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(rNitroFont(.micro, metrics: metrics, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.5))
            .clipShape(Capsule())
    }
}

private struct HowItWorksScrollTable: View {
    @Environment(\.uiMetrics) private var metrics
    let minWidth: CGFloat
    let headers: [String]
    let columnWidths: [CGFloat]
    let rows: [[AnyView]]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(headers.indices, id: \.self) { i in
                        howTableCell(width: columnWidths[i], weight: .semibold, color: .secondary) {
                            Text(headers[i])
                        }
                    }
                }
                .background(Color.card.opacity(0.55))
                MinimalDivider()
                ForEach(rows.indices, id: \.self) { ri in
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(rows[ri].indices, id: \.self) { ci in
                            howTableCell(width: columnWidths[ci]) {
                                rows[ri][ci]
                            }
                        }
                    }
                    if ri < rows.count - 1 { MinimalDivider() }
                }
            }
            .frame(minWidth: minWidth, alignment: .leading)
        }
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.border.opacity(0.45), lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func howTableCell<Content: View>(
        width: CGFloat,
        weight: Font.Weight = .regular,
        color: Color = .primary.opacity(0.9),
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .font(rNitroFont(.micro, metrics: metrics, weight: weight))
            .foregroundColor(color)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct HowItWorksView: View {
    @Environment(\.uiMetrics) private var metrics
    @StateObject private var model = HowItWorksModel()

    private let platformWidths: [CGFloat] = [118, 132, 96, 168, 142, 132, 228]
    private let formatWidths: [CGFloat] = [128, 72, 196, 176, 156]
    private let flowWidths: [CGFloat] = [168, 420]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How everything works")
                        .font(rNitroFont(.title, metrics: metrics, weight: .semibold))
                    Text("Platforms, download formats, and updates — same tables as getrnitro.netlify.app.")
                        .font(rNitroFont(.caption, metrics: metrics))
                        .foregroundColor(.secondary)
                }

                howSectionTitle("Platforms & channels at a glance")
                Text("New here? macOS Stable App ZIP for daily monitoring, or macOS Beta App ZIP for every AI provider.")
                    .font(rNitroFont(.micro, metrics: metrics))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HowItWorksScrollTable(
                    minWidth: 1016,
                    headers: ["Platform", "Version", "Status", "Recommended download", "Install location", "Updates", "What you get"],
                    columnWidths: platformWidths,
                    rows: platformRows
                )

                howSectionTitle("Download formats")
                HowItWorksScrollTable(
                    minWidth: 728,
                    headers: ["Format", "Platform", "What it is", "Gatekeeper / runtime", "When to use"],
                    columnWidths: formatWidths,
                    rows: formatRows
                )

                howSectionTitle("End-to-end flow")
                HowItWorksScrollTable(
                    minWidth: 588,
                    headers: ["Step", "What happens"],
                    columnWidths: flowWidths,
                    rows: flowRows
                )

                HStack(spacing: 10) {
                    MinimalButton(title: "Open website", tint: .accent) {
                        NSWorkspace.shared.open(UPDATE_PAGE_URL)
                    }
                    MinimalButton(title: "GitHub releases", tint: .nBlue) {
                        if let url = URL(string: "https://github.com/ilikemacos/rNitro/releases") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, metrics.hPad)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.bg)
        .onAppear { model.refresh() }
    }

    private var platformRows: [[AnyView]] {
        let linuxGold = Color(red: 0.91, green: 0.66, blue: 0.22)
        return [
            [
                AnyView(platformLabel("macOS", channel: "Stable", accent: .nGreen)),
                AnyView(Text(model.stableId)),
                AnyView(HowStatusPill(label: "Active", color: .nGreen)),
                AnyView(howCode("rNitro-\(model.stableId).zip")),
                AnyView(howCode("~/Applications/rNitro.app")),
                AnyView(Text("In-app updater on launch")),
                AnyView(Text("CPU monitor, benchmark, stress test, System Advisor, App Cleaner; AI chat: OpenAI + OpenRouter only"))
            ],
            [
                AnyView(platformLabel("macOS", channel: "Beta", accent: .nOrange)),
                AnyView(Text(model.betaId)),
                AnyView(HowStatusPill(label: "Experimental", color: .nOrange)),
                AnyView(howCode("rNitro-\(model.betaId).zip")),
                AnyView(howCode("~/Applications/rNitro.app")),
                AnyView(Text("In-app — Install Final or Install Beta")),
                AnyView(Text("Everything in Stable plus all AI providers, temp banners, AES-256 keys, first-launch tips. You're on \(UpdateChecker.displayLabel(CURRENT_VERSION))."))
            ],
            [
                AnyView(platformLabel("Linux", channel: "Pre-release", accent: linuxGold)),
                AnyView(Text(model.linuxId)),
                AnyView(HowStatusPill(label: "Pre-release", color: linuxGold)),
                AnyView(howCode("rNitro-\(model.linuxId).tar.gz")),
                AnyView(howCode("~/.local/share/rnitro")),
                AnyView(Text("Checks version.json on launch")),
                AnyView(Text("GTK4 app: Monitor, Advisor, Chat, Cleaner; x86_64; needs Python 3.10+, GTK 4, libadwaita"))
            ],
            [
                AnyView(platformLabel("Windows", channel: "Legacy", accent: .nBlue)),
                AnyView(Text(model.windowsId)),
                AnyView(HowStatusPill(label: "Deprecated", color: .secondary)),
                AnyView(howCode("rNitro-\(model.windowsId).exe")),
                AnyView(howCode("%LOCALAPPDATA%\\rNitro")),
                AnyView(Text("Manual — website or GitHub")),
                AnyView(Text("Tray monitor only (CPU, temp, RAM, BTC); no AI chat or Cleaner; .NET 8 runtime for EXE"))
            ]
        ]
    }

    private var formatRows: [[AnyView]] {
        [
            [
                AnyView(formatLabel("App ZIP", recommended: true)),
                AnyView(Text("macOS")),
                AnyView(Text("Pre-built rNitro.app — unzip and drag to Applications")),
                AnyView(Text("Right-click → Open once if Gatekeeper blocks it")),
                AnyView(Text("Fastest path; no admin password"))
            ],
            [
                AnyView(formatLabel("PKG")),
                AnyView(Text("macOS")),
                AnyView(Text("Installer package → Applications")),
                AnyView(Text("System Settings → Privacy & Security → Open if blocked")),
                AnyView(Text("One double-click install; needs admin password"))
            ],
            [
                AnyView(formatLabel("DMG")),
                AnyView(Text("macOS")),
                AnyView(Text("Disk image — drag app to Applications")),
                AnyView(Text("Same as App ZIP on first open")),
                AnyView(Text("Familiar Mac workflow"))
            ],
            [
                AnyView(formatLabel(".sh shell installer")),
                AnyView(Text("macOS")),
                AnyView(Text("Full Swift source compiled locally with swiftc")),
                AnyView(Text("No prebuilt binary — you read the script first")),
                AnyView(Text("Maximum trust; ~30s compile on your Mac"))
            ],
            [
                AnyView(formatLabel("Tarball + .sh")),
                AnyView(Text("Linux")),
                AnyView(Text("Python/GTK source tree + install-rNitro-linux.sh")),
                AnyView(Text("Installer checks deps and sets up a venv")),
                AnyView(Text("Pre-release; also on GitHub Releases"))
            ],
            [
                AnyView(formatLabel("EXE / .ps1")),
                AnyView(Text("Windows")),
                AnyView(Text("Pre-built tray app or PowerShell compile via csc.exe")),
                AnyView(Text(".NET 8 Desktop Runtime for EXE")),
                AnyView(Text("Legacy only — macOS or Linux recommended"))
            ]
        ]
    }

    private var flowRows: [[AnyView]] {
        [
            [AnyView(Text("Pick your platform tab")), AnyView(Text("macOS, Linux, or Windows — the site auto-detects your OS"))],
            [AnyView(Text("Accept Terms & Conditions")), AnyView(Text("Required once per browser session before any download"))],
            [AnyView(Text("Download recommended file")), AnyView(Text("Green/orange/cyan/gold cards on each tab — sizes shown on buttons"))],
            [AnyView(Text("Install")), AnyView(Text("Follow the How to install steps on the website for your tab"))],
            [AnyView(Text("Updates")), AnyView(Text("macOS: in-app prompt → pick Final or Beta → download ZIP → restart. Linux: checks version.json. Windows: manual."))],
            [AnyView(Text("In-app guide")), AnyView(Text("Open this How it works tab anytime; Settings has subtabs for AI, appearance, menubar, monitor, alerts, and general."))],
            [AnyView(Text("GitHub mirror")), AnyView(Text("All current builds also on GitHub Releases"))]
        ]
    }

    private func howSectionTitle(_ text: String) -> some View {
        Text(text)
            .font(rNitroFont(.body, metrics: metrics, weight: .semibold))
            .foregroundColor(.cyan)
            .padding(.top, 6)
    }

    private func platformLabel(_ platform: String, channel: String, accent: Color) -> some View {
        HStack(spacing: 0) {
            Text(platform)
                .font(rNitroFont(.micro, metrics: metrics, weight: .semibold))
                .foregroundColor(accent)
            Text(" · \(channel)")
                .font(rNitroFont(.micro, metrics: metrics, weight: .medium))
                .foregroundColor(.primary.opacity(0.9))
        }
    }

    private func formatLabel(_ title: String, recommended: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(rNitroFont(.micro, metrics: metrics, weight: .semibold))
            if recommended {
                Text("(recommended)")
                    .font(rNitroFont(.micro, metrics: metrics))
                    .foregroundColor(.nGreen)
            }
        }
    }

    private func howCode(_ text: String) -> some View {
        Text(text)
            .font(.system(size: metrics.base * 0.72, weight: .regular, design: .monospaced))
            .foregroundColor(.primary.opacity(0.88))
    }
}

struct ContentView: View {
    @Environment(\.uiMetrics) private var metrics
    let tabs: [AppTab]
    var layout: ContentLayout = .window
    @ObservedObject private var m = CPUMonitor.shared
    @ObservedObject private var bat = BatteryMonitor.shared
    @ObservedObject private var net = NetworkMonitor.shared
    @ObservedObject private var gpu = GPUMonitor.shared
    @ObservedObject private var disk = DiskActivityMonitor.shared
    @ObservedObject private var sensors = SensorsMonitor.shared
    @ObservedObject private var btc = BTCPriceMonitor.shared
    @ObservedObject private var stress = StressTester.shared
    @ObservedObject private var bench = BenchmarkRunner.shared
    @ObservedObject private var advisor = SystemAdvisorModel.shared
    @State private var statDetail: StatDetailKind? = nil
    @State private var tab: AppTab = .monitor
    @AppStorage(MonitorPreferences.stressKey) private var showStressUI = true
    @AppStorage(MonitorPreferences.benchmarkKey) private var showBenchmarkUI = true
    @AppStorage(MonitorPreferences.networkKey) private var showNetworkUI = true
    @AppStorage(MonitorPreferences.uiStyleKey) private var uiStyleRaw = MonitorUIStyle.modern.rawValue
    @State private var showFirstLaunchTips = FirstLaunchTips.shouldShow
    @AppStorage(MonitorPreferences.showWeatherKey) private var showWeather = true
    @ObservedObject private var weather = WeatherService.shared

    private func toggleStatDetail(_ kind: StatDetailKind) {
        statDetail = statDetail == kind ? nil : kind
    }

    var body: some View {
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
            .sheet(isPresented: $showFirstLaunchTips) {
                FirstLaunchTipsSheet(isPresented: $showFirstLaunchTips)
            }
            .onAppear {
                if FirstLaunchTips.shouldShow { showFirstLaunchTips = true }
            }
            .onChange(of: showFirstLaunchTips) { _, showing in
                if !showing { FirstLaunchTips.markSeen() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .rNitroOpenMainWindow)) { note in
                guard layout == .window else { return }
                if let raw = note.userInfo?["tab"] as? String, let t = AppTab(rawValue: raw) {
                    tab = t
                }
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.canBecomeMain {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    private var rootContent: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.bg
                if layout == .window { Color.bg.ignoresSafeArea() }
                Group {
                    if tabs.count > 1 {
                        HStack(alignment: .top, spacing: 0) {
                            AppTabSidebar(
                                tabs: tabs,
                                tab: $tab,
                                advisorHasWarnings: !advisor.activeWarnings.isEmpty,
                                compact: layout == .popover
                            )
                            MinimalDivider()
                            tabContent
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .layoutPriority(1)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    } else {
                        tabContent
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .clipped()

                if layout == .popover, let kind = statDetail {
                    Color.black.opacity(0.35)
                        .onTapGesture { statDetail = nil }
                    StatDetailPopup(kind: kind, monitor: m, battery: bat, onClose: { statDetail = nil })
                        .frame(maxWidth: 400)
                        .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if layout == .popover {
                popoverOpenWindowFooter
            }
        }
    }

    private var popoverOpenWindowFooter: some View {
        VStack(spacing: 0) {
            MinimalDivider()
            Button(action: {
                NotificationCenter.default.post(name: .rNitroOpenMainWindow, object: nil, userInfo: ["tab": AppTab.monitor.rawValue])
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "macwindow")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Open main window")
                        .font(rNitroFont(.caption, metrics: metrics, weight: .medium))
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .background(Color.card.opacity(0.6))
    }

    @ViewBuilder
    private var tabContent: some View {
        Group {
            switch tab {
            case .chat:
                AIChatView(compact: layout == .popover)
            case .advisor:
                SystemAdvisorView(compact: layout == .popover)
            case .cleaner:
                AppCleanerView()
            case .settings:
                SettingsView()
            case .howItWorks:
                HowItWorksView()
            case .monitor:
                if uiStyleRaw == MonitorUIStyle.legacy.rawValue {
                    legacyMonitorTab
                } else {
                    modernMonitorTab
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var modernMonitorTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text(m.cpuName)
                        .font(rNitroFont(.caption, metrics: metrics))
                        .foregroundColor(.secondary)
                        .lineLimit(1).truncationMode(.tail)
                    Spacer()
                    if m.isLowPowerModeEnabled {
                        LowPowerModeBadge(compact: true)
                    }
                    Text(CURRENT_VERSION)
                        .font(rNitroFont(.micro, metrics: metrics))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, metrics.hPad).padding(.top, 10).padding(.bottom, 6)

                MonitorSection(
                    title: "Battery & Power",
                    accent: .nGreen,
                    summary: bat.isPresent ? "\(bat.levelPercent)%" : String(format: "%.1fW", m.packagePowerWatts),
                    sparkline: m.powerHistory,
                    sparkMax: max(m.powerHistory.max() ?? 1, CPUMonitor.chipPowerCeiling(m.cpuName)),
                    storageKey: "rnitro.sectionExpanded.battery"
                ) {
                    BatteryCpuPowerRow(
                        bat: bat, monitor: m,
                        onBatteryTap: bat.isPresent ? { toggleStatDetail(.battery) } : nil,
                        onCpuPowerTap: { toggleStatDetail(.cpuPower) }
                    )
                    if m.isLowPowerModeEnabled {
                        MonitorRow(
                            label: "Low Power Mode",
                            value: "On",
                            valueColor: Color(red: 0.55, green: 0.88, blue: 0.42)
                        )
                    }
                    PowerGraphView(
                        history: m.powerHistory,
                        color: Color.usage(m.totalUsage),
                        maxWatts: max(CPUMonitor.chipPowerCeiling(m.cpuName) * 1.2, m.powerHistory.max() ?? 0, 8)
                    )
                    .frame(height: metrics.graphHeight)
                }

                MonitorSection(
                    title: "CPU",
                    accent: .accent,
                    summary: String(format: "%.0f%%", m.totalUsage),
                    sparkline: m.usageHistory,
                    storageKey: "rnitro.sectionExpanded.cpu"
                ) {
                    GraphView(history: m.usageHistory, color: Color.usage(m.totalUsage))
                        .frame(height: metrics.graphHeight)
                    MonitorRow(label: "Usage", value: String(format: "%.1f%%", m.totalUsage), valueColor: Color.usage(m.totalUsage))
                    MonitorRow(label: "Load avg", value: String(format: "%.2f · %.2f · %.2f", m.loadAverage1, m.loadAverage5, m.loadAverage15))
                    MonitorRow(label: "Uptime", value: CPUMonitor.formatUptime(m.systemUptime))
                    MonitorRow(label: "Clock", value: String(format: "%.0f / %.0f MHz", m.baseClock, m.boostClock))
                    Button(action: { toggleStatDetail(.temperature) }) {
                        MonitorRow(label: "Temperature", value: String(format: "%.0f °C", m.temperature), valueColor: Color.temp(m.temperature))
                    }.buttonStyle(.plain)
                    VStack(spacing: 4) {
                        ForEach(Array(m.cores.enumerated()), id: \.offset) { i, core in
                            let eff = i < m.efficiencyCoreCount
                            let cIdx = eff ? i : i - m.efficiencyCoreCount
                            CoreRow(core: core, index: i, isEfficiency: eff, clusterIndex: cIdx)
                        }
                    }
                }

                MonitorSection(
                    title: "GPU",
                    accent: .nGreen,
                    summary: String(format: "%.0f%%", gpu.usage),
                    sparkline: gpu.usageHistory,
                    storageKey: "rnitro.sectionExpanded.gpu"
                ) {
                    GraphView(history: gpu.usageHistory, color: Color.usage(gpu.usage))
                        .frame(height: metrics.graphHeight)
                    MonitorRow(label: "Usage", value: String(format: "%.1f%%", gpu.usage), valueColor: Color.usage(gpu.usage))
                    MonitorRow(label: "Power", value: String(format: "%.1f W", m.gpuPowerWatts))
                }

                MonitorSection(
                    title: "Memory",
                    accent: .nPurple,
                    summary: String(format: "%.0f%%", m.memoryUsedPercent),
                    sparkline: m.memoryHistory,
                    storageKey: "rnitro.sectionExpanded.memory"
                ) {
                    UsageBarRow(label: "RAM", usedGB: m.memoryUsedGB, freeGB: m.memoryFreeGB,
                                totalGB: m.memoryTotalGB, usedPercent: m.memoryUsedPercent,
                                action: { toggleStatDetail(.memory) })
                    MonitorRow(label: "Pressure", value: m.memoryPressure, valueColor: Color.pressure(m.memoryPressure))
                    MonitorRow(label: "Wired", value: String(format: "%.1f GB", m.memoryWiredGB))
                    MonitorRow(label: "Compressed", value: String(format: "%.1f GB", m.memoryCompressedGB))
                    MonitorRow(label: "Swap used", value: String(format: "%.1f GB", m.memorySwapGB))
                }

                MonitorSection(
                    title: "Disk",
                    accent: .nOrange,
                    summary: String(format: "%.0f%%", m.diskUsedPercent),
                    sparkline: disk.activityHistory,
                    sparkMax: max(disk.activityHistory.max() ?? 1, 10),
                    storageKey: "rnitro.sectionExpanded.disk"
                ) {
                    UsageBarRow(label: "SSD · \(m.diskVolumeName)", usedGB: m.diskUsedGB, freeGB: m.diskFreeGB,
                                totalGB: m.diskTotalGB, usedPercent: m.diskUsedPercent,
                                action: { toggleStatDetail(.storage) })
                    MiniGraphView(history: disk.activityHistory, color: .nOrange, maxValue: max(disk.activityHistory.max() ?? 1, 10))
                        .frame(height: 28)
                    MonitorRow(label: "Read", value: String(format: "%.1f MB/s", disk.readMBps))
                    MonitorRow(label: "Write", value: String(format: "%.1f MB/s", disk.writeMBps))
                }

                if showNetworkUI {
                    MonitorSection(
                        title: "Network",
                        accent: .nBlue,
                        summary: net.isAvailable ? NetworkMonitor.formatSpeed(net.downloadMbps) : "—",
                        sparkline: net.downloadHistory,
                        sparkMax: max(net.downloadHistory.max() ?? 1, 100),
                        storageKey: "rnitro.sectionExpanded.network"
                    ) {
                        NetworkMonitorRow(net: net)
                        MonitorRow(label: "IP", value: net.localIP)
                        if !net.wifiSSID.isEmpty {
                            MonitorRow(label: "Wi-Fi", value: net.wifiSSID)
                        }

                        if showWeather, let w = weather.snapshot {
                            MonitorRow(label: "Weather", value: String(format: "%.0f°C %@", w.tempC, w.condition))
                            MonitorRow(label: "Location", value: w.city)
                        } else if showWeather && weather.isLoading {
                            MonitorRow(label: "Weather", value: "Loading…")
                        }

                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Download").font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                                MiniGraphView(history: net.downloadHistory, color: .accent, maxValue: max(net.downloadHistory.max() ?? 1, 100))
                                    .frame(height: 24)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Upload").font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                                MiniGraphView(history: net.uploadHistory, color: .nGreen, maxValue: max(net.uploadHistory.max() ?? 1, 100))
                                    .frame(height: 24)
                            }
                        }
                    }
                }

                MonitorSection(
                    title: "Sensors",
                    accent: .nOrange,
                    summary: sensors.entries.isEmpty ? "—" : "\(sensors.entries.count) readings",
                    storageKey: "rnitro.sectionExpanded.sensors"
                ) {
                    if sensors.entries.isEmpty {
                        MonitorRow(label: "Status", value: "No temperature or fan sensors found")
                        MonitorRow(label: "Tip", value: "SMC keys vary by chip — CPU temp still shown above")
                    } else {
                        let groups = Dictionary(grouping: sensors.entries, by: { $0.group })
                        ForEach(["Temperatures", "Fans"], id: \.self) { group in
                            if let items = groups[group] {
                                Text(group).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                                ForEach(items) { entry in
                                    VStack(alignment: .leading, spacing: 0) {
                                        MonitorRow(label: entry.name, value: "\(entry.value) \(entry.unit)")
                                        Text(entry.rawKey).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary.opacity(0.6))
                                    }
                                }
                            }
                        }
                    }
                }

                MonitorSection(
                    title: "Tools",
                    accent: .secondary,
                    summary: "Stress & Benchmark",
                    storageKey: "rnitro.sectionExpanded.settings"
                ) {
                    if let price = btc.priceUSD {
                        MonitorRow(label: "Bitcoin", value: String(format: "$%.0f", price))
                    }
                    HStack {
                        Text("Stress Test").font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                        Spacer()
                        MinimalButton(
                            title: stress.isRunning ? "Stop" : "Start",
                            tint: stress.isRunning ? .nRed : .nOrange,
                            disabled: bench.isRunning,
                            action: { stress.isRunning ? stress.stop() : stress.start() }
                        )
                    }
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Benchmark").font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                            Text("1-core \(bench.singleCoreScore.map { String(format: "%.0f", $0) } ?? "—") · multi \(bench.multiCoreScore.map { String(format: "%.0f", $0) } ?? "—")")
                                .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                        }
                        Spacer()
                        MinimalButton(
                            title: bench.isRunning ? "Running…" : "Run",
                            disabled: bench.isRunning || stress.isRunning,
                            action: { bench.run() }
                        )
                    }
                }
                .padding(.bottom, 12)
                .onAppear {
                    SectionExpansionStore.migrateExtrasKey()
                    let key = net.wifiSSID.isEmpty ? "wired-\(net.interfaceName)" : net.wifiSSID
                    weather.refresh(forNetworkKey: key, enabled: showWeather)
                }
            }
        }
        .onChange(of: net.wifiSSID) { _, _ in
            let key = net.wifiSSID.isEmpty ? "wired-\(net.interfaceName)" : net.wifiSSID
            weather.refresh(forNetworkKey: key, enabled: showWeather)
        }
        .onChange(of: showWeather) { _, on in
            let key = net.wifiSSID.isEmpty ? "wired-\(net.interfaceName)" : net.wifiSSID
            weather.refresh(forNetworkKey: key, enabled: on)
        }
        .clipped()
    }


    private var legacyMonitorTab: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("rNitro").font(rNitroFont(.title, metrics: metrics, weight: .semibold))
                        Text(m.cpuName).font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                            .lineLimit(1).truncationMode(.tail)
                        Text(CURRENT_VERSION).font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary.opacity(0.75))
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        if m.isLowPowerModeEnabled {
                            LowPowerModeBadge(compact: true)
                        }
                        Circle().fill(Color.nGreen).frame(width: 5, height: 5)
                        Text("Live").font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, metrics.hPad).padding(.top, 12).padding(.bottom, 14)

                MinimalDivider().padding(.horizontal, 16)

                ResponsiveStatGrid {
                    StatCell(title: "BASE", value: String(format: "%.0f", m.baseClock), unit: "MHz", color: .primary, action: { toggleStatDetail(.clock) })
                    StatCell(title: "BOOST", value: String(format: "%.0f", m.boostClock), unit: "MHz", color: .accent, action: { toggleStatDetail(.clock) })
                    StatCell(title: "TEMP", value: String(format: "%.0f", m.temperature), unit: "°C", color: Color.temp(m.temperature), action: { toggleStatDetail(.temperature) })
                    StatCell(title: "CORES", value: "\(m.logicalCores)", unit: "threads", color: .nGreen, action: { toggleStatDetail(.cores) })
                }
                .padding(.vertical, 12).padding(.horizontal, metrics.compact ? 6 : 8)

                MinimalDivider().padding(.horizontal, 16)

                BatteryCpuPowerRow(
                    bat: bat, monitor: m,
                    onBatteryTap: bat.isPresent ? { toggleStatDetail(.battery) } : nil,
                    onCpuPowerTap: { toggleStatDetail(.cpuPower) }
                )
                .padding(.vertical, 12).padding(.horizontal, metrics.compact ? 6 : 8)

                if showNetworkUI {
                    MinimalDivider().padding(.horizontal, 16)
                    NetworkMonitorRow(net: net)
                        .padding(.vertical, 10).padding(.horizontal, metrics.compact ? 10 : 16)
                }

                MinimalDivider().padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("CPU").font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f%%", m.totalUsage))
                            .font(rNitroFont(.headline, metrics: metrics, weight: .semibold))
                            .foregroundColor(Color.usage(m.totalUsage))
                    }
                    GraphView(history: m.usageHistory, color: Color.usage(m.totalUsage))
                        .frame(height: metrics.graphHeight)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)

                MinimalDivider().padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {
                    UsageBarRow(label: "RAM", usedGB: m.memoryUsedGB, freeGB: m.memoryFreeGB,
                                totalGB: m.memoryTotalGB, usedPercent: m.memoryUsedPercent,
                                action: { toggleStatDetail(.memory) })
                    UsageBarRow(label: "SSD · \(m.diskVolumeName)", usedGB: m.diskUsedGB, freeGB: m.diskFreeGB,
                                totalGB: m.diskTotalGB, usedPercent: m.diskUsedPercent,
                                action: { toggleStatDetail(.storage) })
                }
                .padding(.horizontal, 16).padding(.vertical, 14)

                MinimalDivider().padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Cores").font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                        Spacer()
                        Text("\(m.physicalCores)P / \(m.logicalCores)L")
                            .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                    }
                    VStack(spacing: 6) {
                        ForEach(Array(m.cores.enumerated()), id: \.offset) { i, core in
                            CoreRow(core: core, index: i)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)

                if showStressUI {
                    MinimalDivider().padding(.horizontal, 16)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Stress").font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                            if stress.isRunning {
                                Text(String(format: "%02d:%02d", stress.elapsedSeconds / 60, stress.elapsedSeconds % 60))
                                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
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
                }

                if showBenchmarkUI {
                    MinimalDivider().padding(.horizontal, 16)
                    VStack(spacing: 10) {
                        HStack {
                            Text("Benchmark").font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                            Spacer()
                            if bench.isRunning {
                                Text(bench.stage).font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                            }
                        }
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
                    .padding(.horizontal, 16).padding(.vertical, 14)
                }

                MinimalDivider().padding(.horizontal, 16)

                if let price = btc.priceUSD {
                    MinimalDivider().padding(.horizontal, 16)
                    MonitorRow(label: "Bitcoin", value: String(format: "$%.0f", price))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                }
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
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var cpu = CPUMonitor.shared
    @ObservedObject private var gpu = GPUMonitor.shared
    var body: some View {
        HStack(spacing:14) {
            hudStat("CPU", String(format:"%.0f%%", min(100, cpu.totalUsage)), Color.usage(min(100, cpu.totalUsage)))
            hudStat("GPU", String(format:"%.0f%%", min(100, gpu.usage)), Color.usage(min(100, gpu.usage)))
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
            Text(value).font(rNitroFont(.headline, metrics: metrics, weight: .bold)).foregroundColor(color)
            Text(label).font(rNitroFont(.micro, metrics: metrics, weight: .semibold)).foregroundColor(.white.opacity(0.6)).tracking(1)
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


// ── Menu bar icon (light/dark appearance) ───────────────────────────────────
// Bundled icon-light.png / icon-dark.png swap when macOS toggles light/dark.
// Integration point: AppDelegate attaches this to the NSStatusItem button.
final class MenuBarIconManager {
    static let shared = MenuBarIconManager()

    private var lightImage: NSImage?
    private var darkImage: NSImage?
    private weak var button: NSButton?
    private var themeObserver: NSObjectProtocol?

    private init() {
        lightImage = Self.loadResource("icon-light")
        darkImage = Self.loadResource("icon-dark")
    }

    func attach(to button: NSButton) {
        self.button = button
        refresh(for: button)
        if let themeObserver {
            DistributedNotificationCenter.default().removeObserver(themeObserver)
        }
        themeObserver = DistributedNotificationCenter.default.addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, let button = self.button else { return }
            self.refresh(for: button)
        }
    }

    func refresh(for button: NSButton) {
        guard let image = resolvedImage(for: button) else {
            button.image = nil
            return
        }
        button.image = image
        button.imagePosition = .imageLeading
    }

    private func resolvedImage(for view: NSView) -> NSImage? {
        let best = view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        let useLightIcon = (best == .darkAqua)
        return useLightIcon ? lightImage : darkImage
    }

    private static func loadResource(_ name: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let img = NSImage(contentsOf: url) else { return nil }
        img.size = NSSize(width: 18, height: 18)
        img.isTemplate = false
        return img
    }
}

enum FontRegistrar {
    static func registerVarelaRound() {
        let candidates = [
            Bundle.main.url(forResource: "VarelaRound", withExtension: "ttf", subdirectory: "Fonts"),
            Bundle.main.url(forResource: "VarelaRound", withExtension: "ttf")
        ]
        for url in candidates.compactMap({ $0 }) {
            var err: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &err) { return }
        }
    }
}

// Adds a live CPU% readout in the menu bar, independent of whether the main
// window is open. Clicking it opens a compact popover with the same
// real-time data (shares CPUMonitor.shared, so nothing is duplicated).
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var subscriptions = Set<AnyCancellable>()
    private var hotkeyMonitor: Any?
    private var modeObserver: NSObjectProtocol?
    private var powerModeObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        FontRegistrar.registerVarelaRound()
        UpdateChecker.checkOnLaunch()
        BTCPriceMonitor.shared.start()
        NetworkMonitor.shared.start()
        MonitorActivity.setPopoverOpen(false)
        UNUserNotificationCenter.current().delegate = self
        AdvisorNotificationCenter.configure()
        SystemAdvisorModel.shared.startMonitoring()

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(togglePopover)
        statusItem = item
        if let button = item.button {
            MenuBarIconManager.shared.attach(to: button)
        }
        updateStatusTitle()

        let refresh: () -> Void = { [weak self] in self?.updateStatusTitle() }
        let main = DispatchQueue.main
        CPUMonitor.shared.$totalUsage.receive(on: main).sink { _ in refresh() }.store(in: &subscriptions)
        CPUMonitor.shared.$temperature.receive(on: main).sink { _ in refresh() }.store(in: &subscriptions)
        CPUMonitor.shared.$packagePowerWatts.receive(on: main).sink { _ in refresh() }.store(in: &subscriptions)
        CPUMonitor.shared.$memoryUsedPercent.receive(on: main).sink { _ in refresh() }.store(in: &subscriptions)
        NetworkMonitor.shared.$downloadMbps.receive(on: main).sink { _ in refresh() }.store(in: &subscriptions)
        BatteryMonitor.shared.$levelPercent.receive(on: main).sink { _ in refresh() }.store(in: &subscriptions)
        BatteryMonitor.shared.$isCharging.receive(on: main).sink { _ in refresh() }.store(in: &subscriptions)
        BatteryMonitor.shared.$isOnAC.receive(on: main).sink { _ in refresh() }.store(in: &subscriptions)
        BatteryMonitor.shared.$timeRemainingMinutes.receive(on: main).sink { _ in refresh() }.store(in: &subscriptions)
        BatteryMonitor.shared.$timeToFullMinutes.receive(on: main).sink { _ in refresh() }.store(in: &subscriptions)
        BTCPriceMonitor.shared.$priceUSD.receive(on: main).sink { _ in refresh() }.store(in: &subscriptions)

        modeObserver = NotificationCenter.default.addObserver(
            forName: .menuBarModeChanged, object: nil, queue: .main
        ) { [weak self] _ in self?.updateStatusTitle() }

        powerModeObserver = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            let lpm = CPUMonitor.readLowPowerModeEnabled()
            CPUMonitor.shared.isLowPowerModeEnabled = lpm
            self?.updateStatusTitle()
        }
        CPUMonitor.shared.$isLowPowerModeEnabled.receive(on: main).sink { _ in refresh() }.store(in: &subscriptions)

        let popoverSize = NSSize(width: 360, height: 580)
        let popoverView = ContentView(tabs: AppTab.popoverTabs, layout: .popover)
            .frame(minWidth: 320, idealWidth: 360, maxWidth: 420, minHeight: 480, idealHeight: 580, maxHeight: 720)
            .clipped()
        let hosting = NSHostingController(rootView: popoverView)
        hosting.view.wantsLayer = true
        hosting.view.layer?.masksToBounds = true
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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    @objc private func togglePopover() {
        guard let event = NSApp.currentEvent, let button = statusItem?.button else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            let overlayTitle = OverlayWindowController.shared.isVisible ? "Hide Game Overlay (⌥⇧O)" : "Show Game Overlay (⌥⇧O)"
            menu.addItem(withTitle: overlayTitle, action: #selector(toggleOverlay), keyEquivalent: "")
            menu.addItem(withTitle: "Launch App with FPS HUD…", action: #selector(launchWithHUD), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            let layoutMenu = NSMenu()
            let layoutItem = NSMenuItem(title: "Menu Bar Layout", action: nil, keyEquivalent: "")
            layoutItem.submenu = layoutMenu
            let currentLayout = MenuBarConfig.layout
            for layout in MenuBarLayout.allCases {
                let item = NSMenuItem(title: layout.label, action: #selector(setMenuBarLayout(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = layout.rawValue
                item.state = layout == currentLayout ? .on : .off
                layoutMenu.addItem(item)
            }
            menu.addItem(layoutItem)
            let slotsMenu = NSMenu()
            let slotsItem = NSMenuItem(title: "Menu Bar Slots", action: nil, keyEquivalent: "")
            slotsItem.submenu = slotsMenu
            for slot in MenuBarSlot.allCases {
                let item = NSMenuItem(title: slot.label, action: #selector(toggleMenuBarSlot(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = slot.rawValue
                item.state = MenuBarConfig.isSlotEnabled(slot) ? .on : .off
                slotsMenu.addItem(item)
            }
            menu.addItem(slotsItem)
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
            MonitorActivity.setPopoverOpen(false)
        } else {
            pop.show(relativeTo: .zero, of: button, preferredEdge: .minY)
            pop.contentViewController?.view.window?.makeKey()
            MonitorActivity.setPopoverOpen(true)
        }
    }

    @objc private func toggleOverlay() { OverlayWindowController.shared.toggle() }

    @objc private func setMenuBarLayout(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let layout = MenuBarLayout(rawValue: raw) else { return }
        MenuBarConfig.setLayout(layout)
        updateStatusTitle()
    }

    @objc private func toggleMenuBarSlot(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let slot = MenuBarSlot(rawValue: raw) else { return }
        MenuBarConfig.setSlot(slot, enabled: !MenuBarConfig.isSlotEnabled(slot))
        updateStatusTitle()
    }

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
        guard let button = statusItem?.button else { return }
        MenuBarIconManager.shared.refresh(for: button)
        button.title = MenuBarStatusFormatter.render(layout: MenuBarConfig.layout)
        if button.image != nil {
            button.imagePosition = .imageLeading
        }
    }

    // Safety net: make sure stress-test threads never keep spinning after
    // the app has quit — they check stopFlag on their own, but this
    // guarantees the flag actually gets set even on unexpected termination.
    func applicationWillTerminate(_ notification: Notification) {
        if let modeObserver { NotificationCenter.default.removeObserver(modeObserver) }
        if let powerModeObserver { NotificationCenter.default.removeObserver(powerModeObserver) }
        if let hotkeyMonitor { NSEvent.removeMonitor(hotkeyMonitor) }
        subscriptions.removeAll()
        CPUMonitor.shared.stopMonitoring()
        BatteryMonitor.shared.stopMonitoring()
        NetworkMonitor.shared.stop()
        GPUMonitor.shared.stop()
        DiskActivityMonitor.shared.stop()
        SensorsMonitor.shared.stop()
        StressTester.shared.stop()
        OverlayWindowController.shared.hide()
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
            ContentView(tabs: AppTab.windowTabs, layout: .window)
                .frame(minWidth:360,idealWidth:520,maxWidth:.infinity,minHeight:480,idealHeight:700,maxHeight:.infinity)
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
    -framework Security \
    -framework CryptoKit \
    -lIOReport \
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

INSTALLER_DIR="$(cd "$(dirname "$0")" && pwd)"

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
    <key>CFBundleVersion</key><string>8.3.4-Beta-arm64</string>
    <key>CFBundleShortVersionString</key><string>8.3.4-Beta-arm64</string>
    <key>ATSApplicationFontsPath</key><string>Fonts</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>LSMinimumSystemVersion</key><string>12.0</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSExceptionDomains</key>
        <dict>
            <key>localhost</key>
            <dict><key>NSExceptionAllowsInsecureHTTPLoads</key><true/></dict>
            <key>127.0.0.1</key>
            <dict><key>NSExceptionAllowsInsecureHTTPLoads</key><true/></dict>
        </dict>
    </dict>
</dict>
</plist>
PLIST
chmod 644 "$APP_DEST/Contents/Info.plist"

# ── Bundle Varela Round font ──────────────────────────────────────────────────
echo "🔤 Installing Varela Round font..."
FONT_DIR="$APP_DEST/Contents/Resources/Fonts"
mkdir -p "$FONT_DIR"
UI_FONT="$FONT_DIR/VarelaRound.ttf"
UI_FONT_SRC=""
for candidate in \
  "$INSTALLER_DIR/VarelaRound.ttf" \
  "$INSTALLER_DIR/fonts/VarelaRound.ttf" \
  "$HOME/Downloads/VarelaRound.ttf" \
  "$HOME/rnitro-site-work/rnitro-site/VarelaRound.ttf" \
  "$HOME/rnitro-site-work/rnitro-site/fonts/VarelaRound.ttf" \
  "$HOME/Applications/rNitro.app/Contents/Resources/Fonts/VarelaRound.ttf"; do
  if [[ -f "$candidate" ]]; then
    UI_FONT_SRC="$candidate"
    break
  fi
done
if [[ -n "$UI_FONT_SRC" ]]; then
  cp "$UI_FONT_SRC" "$UI_FONT"
else
  echo "⚠️  VarelaRound.ttf not found beside installer (non-fatal); UI will fall back to system font."
fi
[[ -f "$UI_FONT" ]] && chmod 644 "$UI_FONT"

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

# ── Menu bar icons (light/dark for appearance switching) ─────────────────────
echo "🎨 Generating menu bar icons..."

cat > "$WORK_DIR/generate_menubar_icons.swift" << 'MBICONEOF'
import Cocoa

func drawBolt(in ctx: CGContext, size: CGFloat, fill: CGColor) {
    let bolt = CGMutablePath()
    bolt.move(to: CGPoint(x: size * 0.58, y: size * 0.86))
    bolt.addLine(to: CGPoint(x: size * 0.40, y: size * 0.50))
    bolt.addLine(to: CGPoint(x: size * 0.50, y: size * 0.50))
    bolt.addLine(to: CGPoint(x: size * 0.42, y: size * 0.14))
    bolt.addLine(to: CGPoint(x: size * 0.62, y: size * 0.50))
    bolt.addLine(to: CGPoint(x: size * 0.50, y: size * 0.50))
    bolt.closeSubpath()
    ctx.setFillColor(fill)
    ctx.addPath(bolt)
    ctx.fillPath()
}

func renderIcon(fill: CGColor, outPath: String) -> Bool {
    let size: CGFloat = 36
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
    ctx.clear(CGRect(x: 0, y: 0, width: size, height: size))
    drawBolt(in: ctx, size: size, fill: fill)
    image.unlockFocus()
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { return false }
    do {
        try png.write(to: URL(fileURLWithPath: outPath))
        return true
    } catch { return false }
}

guard CommandLine.arguments.count >= 3 else { exit(1) }
let mode = CommandLine.arguments[1]
let out = CommandLine.arguments[2]
let color: CGColor
switch mode {
case "light":
    color = CGColor(red: 0.92, green: 0.95, blue: 1.0, alpha: 1.0)
case "dark":
    color = CGColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0)
default:
    exit(1)
}
exit(renderIcon(fill: color, outPath: out) ? 0 : 1)
MBICONEOF

MB_LIGHT="$WORK_DIR/icon-light.png"
MB_DARK="$WORK_DIR/icon-dark.png"
if swift "$WORK_DIR/generate_menubar_icons.swift" light "$MB_LIGHT" \
   && swift "$WORK_DIR/generate_menubar_icons.swift" dark "$MB_DARK"; then
  cp "$MB_LIGHT" "$APP_DEST/Contents/Resources/icon-light.png"
  cp "$MB_DARK" "$APP_DEST/Contents/Resources/icon-dark.png"
  chmod 644 "$APP_DEST/Contents/Resources/icon-light.png" "$APP_DEST/Contents/Resources/icon-dark.png"
  echo "✅ Menu bar icons generated."
else
  echo "⚠️  Menu bar icon rendering failed (non-fatal); text-only menu bar will be used."
fi

# ── Security: sign only after the bundle is fully assembled. Never edit
#    Info.plist after codesign — that invalidates the signature and Gatekeeper
#    reports the app as "damaged and can't be opened".
if sign_app_bundle "$APP_DEST"; then
  if codesign --verify --deep --strict "$APP_DEST" 2>/dev/null; then
    echo "✅ Code signature verified."
  else
    echo "⚠️  Code signature verification failed."
  fi
else
  echo "⚠️  Ad-hoc code signing failed; Gatekeeper may block launch."
fi

xattr -cr "$APP_DEST" 2>/dev/null || true
BINARY_HASH="$(shasum -a 256 "$APP_DEST/Contents/MacOS/rNitro" | awk '{print $1}')"
echo "🔒 Binary SHA-256 (reference): $BINARY_HASH"

echo ""
echo "✅ rNitro installed to $APP_DEST"
echo "🚀 Launching..."
xattr -cr "$APP_DEST" 2>/dev/null || true
open "$APP_DEST"
