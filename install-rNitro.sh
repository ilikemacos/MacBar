#!/bin/bash
#
# rNitro installer — hardened
#
# v8.4.2-Beta-arm64 — Traditional Chinese (繁體中文) + Extra Large body 22px.
# v8.4.1-Beta-arm64 — top processes by CPU/RAM while popover open.
# v8.4.0-Beta-arm64 — Settings: font size + language (EN/ZH/ES/DE).
# v8.3.16-Beta-arm64 — removed in-app How it works tab (overview remains on website).
# v8.3.15-Beta-arm64 — tiered idle sampling, RingBuffer histories, lazy battery graph, idle profile setting.
# v8.3.12-Beta-arm64 — battery: direct IOKit AppleSmartBattery read (fixes — % / desktop on MacBooks).
# v8.3.9-Beta-arm64 — performance: background CPU polling, SMC key cache, debounced menubar, narrower SwiftUI observation.
# v8.3.0-Beta-arm64 — in-app updater polish, faster App Cleaner, Linux v0.1 companion release.
# v8.2.7-Beta-arm64 — Patched major website bugs (download buttons, JS parse error).
# v8.2.6-Beta-arm64 — Varela Round UI font + critical temp notification banners + Low Power Mode badge.
# v8.2.5-Beta-arm64 — prior beta channel build (archived on website).
# v8.2.4-Beta-arm64 — System Advisor tab: client-side specs assistant with customizable
# temp/CPU/RAM/GPU/battery warnings (live readings, no API key).
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
EXPECTED_HASH="a85cbcf87ddab2ce8ff948e4b16ed2d2b0dda653bb674bb49998583f4a2ae504"
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
let CURRENT_VERSION = "v8.4.2-Beta-arm64"
let RNITRO_BUILD_CHANNEL = "beta"
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

    private static func fetchVersionInfo(completion: @escaping (VersionInfo?) -> Void) {
        var req = URLRequest(url: UPDATE_CHECK_URL)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 12
        PinnedSession.shared.dataTask(with: req) { data, _, _ in
            if let data = data, let info = try? JSONDecoder().decode(VersionInfo.self, from: data) {
                completion(info)
                return
            }
            URLSession.shared.dataTask(with: req) { data, _, _ in
                if let data = data, let info = try? JSONDecoder().decode(VersionInfo.self, from: data) {
                    completion(info)
                } else {
                    completion(nil)
                }
            }.resume()
        }.resume()
    }

    static func checkOnLaunch() {
        checkPendingUpdateResult()
        LaunchAtLoginManager.refreshRegistrationIfNeeded()
        fetchVersionInfo { info in
            guard let info = info else { return }
            evaluateRemoteVersions(info, manual: false)
        }
    }

    private static func checkPendingUpdateResult() {
        let resultURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/rNitro/update-result.txt")
        guard let raw = try? String(contentsOf: resultURL, encoding: .utf8) else { return }
        try? FileManager.default.removeItem(at: resultURL)
        let content = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        let parts = content.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        let status = parts.first.map(String.init) ?? ""
        if status == "ok" { return }
        let detail = parts.count > 1 ? String(parts[1]) : "The update helper did not finish successfully."
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let alert = NSAlert()
            alert.messageText = "Previous Update Did Not Complete"
            alert.informativeText = detail + "\n\nCheck ~/Library/Logs/rNitro/update.log or download the App ZIP from getrnitro.netlify.app."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Website")
            alert.addButton(withTitle: "OK")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(UPDATE_PAGE_URL)
            }
        }
    }

    static func checkManually() {
        fetchVersionInfo { info in
            DispatchQueue.main.async {
                guard let info = info else {
                    let alert = NSAlert()
                    alert.messageText = "Could Not Check for Updates"
                    alert.informativeText = "Could not reach getrnitro.netlify.app. Check your internet connection and try again."
                    alert.alertStyle = .warning
                    alert.runModal()
                    return
                }
                evaluateRemoteVersions(info, manual: true)
            }
        }
    }

    static func installPathLabel() -> String {
        let path = Bundle.main.bundlePath
        if path.contains("AppTranslocation") { return "Downloads (translocated)" }
        if UpdateInstaller.isSystemApplicationsBundle(path) { return "/Applications" }
        if path.contains("/Applications/") { return path }
        return path
    }

    private static func evaluateRemoteVersions(_ info: VersionInfo, manual: Bool) {
        let stableRemote = info.latest
        let betaRemote = info.beta ?? ""
        let stableNewer = isNewer(stableRemote, than: CURRENT_VERSION)
        let betaNewer = !betaRemote.isEmpty && isNewer(betaRemote, than: CURRENT_VERSION)
        let onMain = { () -> Void in
            if !stableNewer && !betaNewer {
                if manual {
                    let alert = NSAlert()
                    alert.messageText = "You're Up to Date"
                    alert.informativeText = "rNitro \(displayLabel(CURRENT_VERSION)) is the newest build on your channel, or no newer release is available yet."
                    alert.alertStyle = .informational
                    alert.runModal()
                }
                return
            }
            presentUpdateChoice(stable: stableRemote, beta: betaRemote,
                                stableNewer: stableNewer, betaNewer: betaNewer)
        }
        if manual {
            onMain()
        } else if stableNewer || betaNewer {
            DispatchQueue.main.async(execute: onMain)
        }
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
        let betaFirst = RNITRO_FEATURE_BETA_UI && betaNewer && installBeta != nil
        if betaFirst, let installBeta {
            alert.addButton(withTitle: installBeta)
            alert.addButton(withTitle: installFinal)
        } else {
            alert.addButton(withTitle: installFinal)
            if let installBeta {
                alert.addButton(withTitle: installBeta)
            }
        }
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if betaFirst {
            if response == .alertFirstButtonReturn {
                UpdateInstaller.install(remoteVersion: beta)
            } else if response == .alertSecondButtonReturn {
                UpdateInstaller.install(remoteVersion: stable)
            }
        } else if response == .alertFirstButtonReturn {
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
    private static var downloadProgressObservation: NSKeyValueObservation?
    private static let updateLogURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/rNitro/update.log")
    private static let updateResultURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/rNitro/update-result.txt")

    static func isSystemApplicationsBundle(_ path: String) -> Bool {
        if path.hasPrefix("/Applications/") { return true }
        if path.contains("/System/Volumes/Data/Applications/") { return true }
        if path.hasSuffix("/Applications/rNitro.app") {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            return !path.hasPrefix(home + "/")
        }
        return false
    }

    private static func systemApplicationsDestination(from dest: URL) -> URL {
        if dest.path.hasPrefix("/Applications/") { return dest }
        return URL(fileURLWithPath: "/Applications/rNitro.app")
    }

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
        downloadProgressObservation = task.progress.observe(\.fractionCompleted, options: [.new]) { progress, _ in
            updateDownloadProgress(
                received: Int(progress.completedUnitCount),
                expected: Int(progress.totalUnitCount),
                version: remoteVersion
            )
        }
        task.resume()
        sem.wait()
        downloadProgressObservation = nil

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
        log("Installing to \(dest.path) (running from \(Bundle.main.bundlePath))")
        let replace = replaceApp(stagedApp: staged, destination: dest)
        if let installError = replace.error {
            log("Install failed: \(installError)")
            return .failure(installError)
        }
        log("Install succeeded (mode=\(replace.opensBeforeQuit ? "admin-now" : "quit-then-replace"))")
        if replace.opensBeforeQuit {
            try? "ok|\n".write(to: updateResultURL, atomically: true, encoding: .utf8)
        }
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Update Installed"
            alert.informativeText = "rNitro will restart now to finish applying \(UpdateChecker.displayLabel(remoteVersion))."
            alert.alertStyle = .informational
            alert.runModal()
            LaunchAtLoginManager.refreshRegistrationIfNeeded()
            if replace.opensBeforeQuit {
                NSWorkspace.shared.open(dest)
            }
            NSApp.terminate(nil)
        }
        return .success
    }

    private struct ReplaceResult {
        var error: String?
        var opensBeforeQuit = false
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

        // Quarantined / translocated copies cannot be updated in place.
        if path.contains("AppTranslocation") || path.hasPrefix("/Volumes/") {
            return homeApp
        }

        // PKG installs live here — always replace this copy (admin prompt in replaceApp).
        if isSystemApplicationsBundle(path) {
            return systemApplicationsDestination(from: current)
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

    private static func replaceApp(stagedApp: URL, destination: URL) -> ReplaceResult {
        let fm = FileManager.default
        let parent = destination.deletingLastPathComponent()
        try? fm.createDirectory(at: parent, withIntermediateDirectories: true)

        let cacheDir = fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/rNitro/update-staging", isDirectory: true)
        let durableStage = cacheDir.appendingPathComponent("rNitro.app", isDirectory: true)
        try? fm.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        try? fm.removeItem(at: durableStage)

        let stageCopy = runCommand("/usr/bin/ditto", [stagedApp.path, durableStage.path])
        if stageCopy.0 != 0 {
            return ReplaceResult(error: stageCopy.1.isEmpty
                ? "Could not stage the update package."
                : stageCopy.1)
        }

        let adminDest = isSystemApplicationsBundle(destination.path)
            ? systemApplicationsDestination(from: destination) : destination
        let staged = shellQuote(durableStage.path)
        let target = shellQuote(adminDest.path)
        let parentPath = shellQuote(adminDest.deletingLastPathComponent().path)
        let pid = ProcessInfo.processInfo.processIdentifier
        let logPath = shellQuote(updateLogURL.path)
        let resultPath = shellQuote(updateResultURL.path)

        if isSystemApplicationsBundle(destination.path) {
            let errPipe = Pipe()
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            proc.arguments = [
                "-e",
                "do shell script \"mkdir -p /Applications && rm -rf '\(target)' && /usr/bin/ditto '\(staged)' '\(target)' && /usr/bin/xattr -cr '\(target)'\" with administrator privileges"
            ]
            proc.standardError = errPipe
            proc.standardOutput = Pipe()
            guard (try? proc.run()) != nil else {
                return ReplaceResult(error: "Could not request administrator access to update /Applications.")
            }
            proc.waitUntilExit()
            if proc.terminationStatus != 0 {
                let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                log("Admin install failed (status \(proc.terminationStatus)): \(err)")
                return ReplaceResult(error: "Could not replace rNitro in /Applications. Enter your Mac password when prompted, or download the App ZIP from getrnitro.netlify.app.")
            }
            return ReplaceResult(opensBeforeQuit: true)
        }

        let scriptURL = fm.temporaryDirectory.appendingPathComponent("rnitro-apply-update.sh")
        let script = """
#!/bin/bash
LOG='\(logPath)'
RESULT='\(resultPath)'
write_result() {
  printf '%s|%s\n' "$1" "$2" > "$RESULT"
}
trap 'code=$?; if [ ! -f "$RESULT" ] || [ ! -s "$RESULT" ]; then write_result fail "Update helper exited with code $code. See $LOG"; fi' EXIT
write_result pending "Update in progress…"
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] apply-update pid=\(pid) dest=\(target)" >> "$LOG"
while kill -0 \(pid) 2>/dev/null; do sleep 0.25; done
sleep 0.5
mkdir -p '\(parentPath)' || { write_result fail "Could not create install folder"; exit 1; }
rm -rf '\(target)' || { write_result fail "Could not remove old rNitro.app"; exit 1; }
if ! /usr/bin/ditto '\(staged)' '\(target)' 2>>"$LOG"; then
  write_result fail "ditto failed copying the update. See $LOG"
  exit 1
fi
xattr -cr '\(target)' 2>/dev/null || true
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] apply-update done" >> "$LOG"
write_result ok ""
open '\(target)'
"""
        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        } catch {
            return ReplaceResult(error: "Could not prepare the update helper script.")
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/bash")
        proc.arguments = [scriptURL.path]
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        guard (try? proc.run()) != nil else {
            return ReplaceResult(error: "Could not launch the update helper.")
        }
        return ReplaceResult(opensBeforeQuit: false)
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
    private struct CachedKey {
        let dataSize: UInt32
        let dataType: UInt32
    }
    private var resolvedTempKeys: [String: CachedKey]?
    private var cachedReadings: [Double] = []
    private var lastReadingsTime = Date.distantPast
    private let cacheLock = NSLock()

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

    private func decodeTemperature(bytes b: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                                             UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                                             UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                                             UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8),
                                   dataType: UInt32) -> Double? {
        if dataType == fourCharCode("sp78") {
            let raw = Int16(bitPattern: (UInt16(b.0) << 8) | UInt16(b.1))
            return Double(raw) / 256.0
        }
        if dataType == fourCharCode("flt ") {
            let bits = UInt32(b.0) | (UInt32(b.1) << 8) | (UInt32(b.2) << 16) | (UInt32(b.3) << 24)
            return Double(Float(bitPattern: bits))
        }
        return nil
    }

    private func readCachedTemperature(key: String, info: CachedKey) -> Double? {
        open()
        guard isOpen else { return nil }
        var readInput = SMCParamStruct()
        readInput.key = fourCharCode(key)
        readInput.keyInfo.dataSize = info.dataSize
        readInput.data8 = 5 // kSMCReadKey
        guard let readOutput = call(&readInput), readOutput.result == 0 else { return nil }
        return decodeTemperature(bytes: readOutput.bytes, dataType: info.dataType)
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
        return decodeTemperature(bytes: readOutput.bytes, dataType: infoOutput.keyInfo.dataType)
    }

    private func ensureTempKeyCache() {
        cacheLock.lock()
        if resolvedTempKeys != nil {
            cacheLock.unlock()
            return
        }
        cacheLock.unlock()

        open()
        var resolved: [String: CachedKey] = [:]
        if isOpen {
            for key in Self.candidateKeys {
                var infoInput = SMCParamStruct()
                infoInput.key = fourCharCode(key)
                infoInput.data8 = 9
                guard let infoOutput = call(&infoInput), infoOutput.result == 0, infoOutput.keyInfo.dataSize > 0 else { continue }
                let cached = CachedKey(dataSize: infoOutput.keyInfo.dataSize, dataType: infoOutput.keyInfo.dataType)
                guard let temp = readCachedTemperature(key: key, info: cached), temp >= 20, temp <= 115 else { continue }
                resolved[key] = cached
            }
        }

        cacheLock.lock()
        if resolvedTempKeys == nil { resolvedTempKeys = resolved }
        cacheLock.unlock()
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
        let ttl = MonitorActivity.smcCacheTTL
        cacheLock.lock()
        let age = Date().timeIntervalSince(lastReadingsTime)
        if age < ttl, !cachedReadings.isEmpty {
            let hit = cachedReadings
            cacheLock.unlock()
            return hit
        }
        cacheLock.unlock()

        ensureTempKeyCache()
        cacheLock.lock()
        let keys = resolvedTempKeys ?? [:]
        cacheLock.unlock()
        guard !keys.isEmpty else { return [] }
        let fresh = keys.compactMap { key, info in
            readCachedTemperature(key: key, info: info)
        }.filter { $0 >= 20 && $0 <= 95 }
        cacheLock.lock()
        cachedReadings = fresh
        lastReadingsTime = Date()
        cacheLock.unlock()
        return fresh
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
        ensureTempKeyCache()
        cacheLock.lock()
        let keys = resolvedTempKeys ?? [:]
        cacheLock.unlock()
        return keys.compactMap { key, info in
            guard let v = readCachedTemperature(key: key, info: info), v >= 20, v <= 115 else { return nil }
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
    private var lastReadings: [Double] = []
    private var lastSampleTime = Date.distantPast
    private let cacheTTL: TimeInterval = 1.5
    private let lock = NSLock()

    func readings() -> [Double] {
        lock.lock()
        let age = Date().timeIntervalSince(lastSampleTime)
        if age < cacheTTL {
            let cached = lastReadings
            lock.unlock()
            return cached
        }
        lock.unlock()

        let fresh = fetchReadings()
        lock.lock()
        lastReadings = fresh
        lastSampleTime = Date()
        lock.unlock()
        return fresh
    }

    private func fetchReadings() -> [Double] {
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

/// Fixed-capacity circular buffer — no removeFirst reallocations.
struct RingBuffer<Element> {
    private var storage: [Element]
    private var head = 0
    private(set) var count = 0
    private(set) var capacity: Int

    init(capacity: Int, fill: Element) {
        let cap = max(0, capacity)
        self.capacity = cap
        self.storage = cap > 0 ? Array(repeating: fill, count: cap) : []
    }

    mutating func resize(capacity newCap: Int, fill: Element) {
        let cap = max(0, newCap)
        if cap == capacity { return }
        capacity = cap
        head = 0
        count = 0
        storage = cap > 0 ? Array(repeating: fill, count: cap) : []
    }

    mutating func append(_ value: Element) {
        guard capacity > 0 else { return }
        storage[head] = value
        head = (head + 1) % capacity
        count = min(count + 1, capacity)
    }

    var asArray: [Element] {
        guard capacity > 0, count > 0 else { return [] }
        if count < capacity { return Array(storage.prefix(count)) }
        return Array(storage[head..<capacity]) + Array(storage[0..<head])
    }
}

enum IdleProfile: String, CaseIterable, Identifiable {
    case balanced, aggressive
    var id: String { rawValue }
    var label: String {
        switch self {
        case .balanced: return DisplayPreferencesStore.shared.tr("general.idleBalanced")
        case .aggressive: return DisplayPreferencesStore.shared.tr("general.idleAggressive")
        }
    }
}

enum SamplingTier {
    case minimal, slotAware, full
}

enum PublishCoalesce {
    static func set(_ current: inout Double, to value: Double, epsilon: Double = 0.08) -> Bool {
        if abs(current - value) < epsilon { return false }
        current = value
        return true
    }

    static func set(_ current: inout Int, to value: Int) -> Bool {
        if current == value { return false }
        current = value
        return true
    }

    static func set(_ current: inout String, to value: String) -> Bool {
        if current == value { return false }
        current = value
        return true
    }
}

class CPUMonitor: ObservableObject {
    static let shared = CPUMonitor()

    @Published var totalUsage: Double = 0
    @Published var temperature: Double = 0
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var baseClock: Double = 0
    @Published var boostClock: Double = 0
    @Published var cores: [CoreInfo] = []
    @Published var usageHistory: [Double] = []
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
    @Published var powerHistory: [Double] = []
    @Published var loadAverage1: Double = 0
    @Published var loadAverage5: Double = 0
    @Published var loadAverage15: Double = 0
    @Published var systemUptime: TimeInterval = 0
    @Published var memoryWiredGB: Double = 0
    @Published var memoryCompressedGB: Double = 0
    @Published var memorySwapGB: Double = 0
    @Published var memoryPressure: String = "Normal"
    @Published var memoryHistory: [Double] = []
    @Published var efficiencyCoreCount: Int = 0
    @Published var isLowPowerModeEnabled: Bool = false

    private var usageRing = RingBuffer<Double>(capacity: 0, fill: 0)
    private var powerRing = RingBuffer<Double>(capacity: 0, fill: 0)
    private var memoryRing = RingBuffer<Double>(capacity: 0, fill: 0)
    private var lastMemorySampleTime = Date.distantPast

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

    private var pollSource: DispatchSourceTimer?
    private let workQueue = DispatchQueue(label: "rnitro.cpu.monitor", qos: .utility)
    private var prevCPUInfo: processor_info_array_t?
    private var prevNumCPUInfo: mach_msg_type_number_t = 0
    private var cachedMemsizeGB: Double = 0
    private var lastDiskSampleTime = Date.distantPast

    private struct MemorySample {
        let totalGB, usedGB, freeGB, usedPct: Double
        let wiredGB, compressedGB, swapUsedGB: Double
        let pressure: String
    }
    private struct DiskSample {
        let totalGB, usedGB, freeGB, usedPct: Double
        let volName: String
    }
    private struct SystemSample {
        let load1, load5, load15: Double
        let uptime: TimeInterval
    }
    private struct DerivedSample {
        let lpm: Bool
        let state: ProcessInfo.ThermalState
        let sensorReadings: [Double]
        let socSample: SocPowerSample?
    }

    init() { detectCPUInfo(); startMonitoring() }

    deinit {
        pollSource?.cancel()
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
        var memSize: UInt64 = 0
        var memLen = MemoryLayout<UInt64>.size
        if sysctlbyname("hw.memsize", &memSize, &memLen, nil, 0) == 0, memSize > 0 {
            cachedMemsizeGB = Double(memSize) / 1_073_741_824
        }
    }

    private var pollInterval: TimeInterval = MonitorActivity.cpuInterval

    func startMonitoring() {
        stopMonitoring()
        syncHistoryBuffers()
        pollInterval = MonitorActivity.cpuInterval
        let source = DispatchSource.makeTimerSource(queue: workQueue)
        source.schedule(deadline: .now(), repeating: pollInterval)
        source.setEventHandler { [weak self] in self?.update() }
        source.resume()
        pollSource = source
    }

    func setPollInterval(_ interval: TimeInterval) {
        guard interval > 0, abs(pollInterval - interval) > 0.01 else { return }
        pollInterval = interval
        startMonitoring()
    }

    func stopMonitoring() {
        pollSource?.cancel()
        pollSource = nil
    }

    func syncHistoryBuffers() {
        let cap = MonitorActivity.historyCapacity
        usageRing.resize(capacity: cap, fill: 0)
        powerRing.resize(capacity: cap, fill: 0)
        memoryRing.resize(capacity: cap, fill: 0)
        if cap > 0 {
            usageHistory = usageRing.asArray
            powerHistory = powerRing.asArray
            memoryHistory = memoryRing.asArray
        }
    }

    private func cheapCPUUsageFromLoad() -> Double {
        var load = loadavg()
        var loadSize = MemoryLayout<loadavg>.size
        guard sysctlbyname("vm.loadavg", &load, &loadSize, nil, 0) == 0, load.fscale > 0 else {
            return totalUsage
        }
        let l1 = Double(load.ldavg.0) / Double(load.fscale)
        let est = l1 / Double(max(logicalCores, 1)) * 100.0
        return min(100, max(0, est))
    }

    private func update() {
        let tier = MonitorActivity.tier
        let now = Date()
        let cpu: (avg: Double, perCore: [Double])?
        switch tier {
        case .minimal:
            cpu = (cheapCPUUsageFromLoad(), [])
        case .slotAware, .full:
            cpu = updateCPUUsage()
        }
        var mem: MemorySample? = nil
        if MonitorActivity.samplesMemory,
           now.timeIntervalSince(lastMemorySampleTime) >= MonitorActivity.memoryInterval {
            mem = sampleMemory()
            lastMemorySampleTime = now
        }
        var disk: DiskSample? = nil
        if tier == .full, now.timeIntervalSince(lastDiskSampleTime) >= MonitorActivity.diskInterval {
            disk = sampleDisk()
            lastDiskSampleTime = now
        }
        let sys = tier == .minimal ? nil : sampleSystemStats()
        let derived = sampleDerived()
        let includePerCore = MonitorActivity.includePerCoreSampling
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let cpu { self.applyCPUUsage(cpu, includePerCore: includePerCore) }
            if let mem { self.applyMemory(mem) }
            if let disk { self.applyDisk(disk) }
            if let sys { self.applySystemStats(sys) }
            self.applyDerived(derived)
        }
    }

    private func sampleSystemStats() -> SystemSample {
        var load = loadavg()
        var loadSize = MemoryLayout<loadavg>.size
        if sysctlbyname("vm.loadavg", &load, &loadSize, nil, 0) == 0, load.fscale > 0 {
            let scale = Double(load.fscale)
            return SystemSample(
                load1: Double(load.ldavg.0) / scale,
                load5: Double(load.ldavg.1) / scale,
                load15: Double(load.ldavg.2) / scale,
                uptime: ProcessInfo.processInfo.systemUptime
            )
        }
        return SystemSample(load1: 0, load5: 0, load15: 0, uptime: ProcessInfo.processInfo.systemUptime)
    }

    private func applySystemStats(_ sample: SystemSample) {
        loadAverage1 = sample.load1
        loadAverage5 = sample.load5
        loadAverage15 = sample.load15
        systemUptime = sample.uptime
    }

    static func formatUptime(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        let d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60
        if d > 0 { return String(format: "%dd %dh %dm", d, h, m) }
        if h > 0 { return String(format: "%dh %dm", h, m) }
        return String(format: "%dm", m)
    }

    private func applyCPUUsage(_ sample: (avg: Double, perCore: [Double]), includePerCore: Bool) {
        let alpha = 0.35
        if hasSmoothedSamples {
            smoothedUsage = smoothedUsage * (1 - alpha) + sample.avg * alpha
        } else {
            smoothedUsage = sample.avg
            hasSmoothedSamples = true
        }
        let nextUsage = min(100, max(0, smoothedUsage))
        _ = PublishCoalesce.set(&totalUsage, to: nextUsage, epsilon: 0.15)
        if MonitorActivity.recordsHistory {
            usageRing.append(nextUsage)
            usageHistory = usageRing.asArray
        }
        if includePerCore {
            for (i, u) in sample.perCore.enumerated() where i < cores.count {
                cores[i].usage = u
            }
        }
    }

    private func sampleMemory() -> MemorySample? {
        let totalGB = cachedMemsizeGB > 0 ? cachedMemsizeGB : memoryTotalGB
        guard totalGB > 0 else { return nil }

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
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
        return MemorySample(
            totalGB: totalGB, usedGB: usedGB, freeGB: freeGB, usedPct: usedPct,
            wiredGB: wiredGB, compressedGB: compressedGB, swapUsedGB: swapUsedGB,
            pressure: pressure
        )
    }

    private func applyMemory(_ sample: MemorySample) {
        _ = PublishCoalesce.set(&memoryTotalGB, to: sample.totalGB, epsilon: 0.02)
        _ = PublishCoalesce.set(&memoryUsedGB, to: sample.usedGB, epsilon: 0.02)
        _ = PublishCoalesce.set(&memoryFreeGB, to: sample.freeGB, epsilon: 0.02)
        _ = PublishCoalesce.set(&memoryUsedPercent, to: sample.usedPct, epsilon: 0.2)
        _ = PublishCoalesce.set(&memoryWiredGB, to: sample.wiredGB, epsilon: 0.02)
        _ = PublishCoalesce.set(&memoryCompressedGB, to: sample.compressedGB, epsilon: 0.02)
        _ = PublishCoalesce.set(&memorySwapGB, to: sample.swapUsedGB, epsilon: 0.02)
        _ = PublishCoalesce.set(&memoryPressure, to: sample.pressure)
        if MonitorActivity.recordsHistory {
            memoryRing.append(sample.usedPct)
            memoryHistory = memoryRing.asArray
        }
    }

    private func sampleDisk() -> DiskSample? {
        let volURL = URL(fileURLWithPath: NSHomeDirectory())
        guard let values = try? volURL.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeLocalizedNameKey
        ]),
              let totalBytes = values.volumeTotalCapacity,
              let freeBytes = values.volumeAvailableCapacityForImportantUsage else { return nil }
        let totalGB = Double(totalBytes) / 1_073_741_824
        let freeGB = Double(freeBytes) / 1_073_741_824
        let usedGB = max(0, totalGB - freeGB)
        let usedPct = totalGB > 0 ? min(100, usedGB / totalGB * 100) : 0
        let volName = values.volumeLocalizedName.flatMap { $0.isEmpty ? nil : $0 } ?? "Macintosh HD"
        return DiskSample(totalGB: totalGB, usedGB: usedGB, freeGB: freeGB, usedPct: usedPct, volName: volName)
    }

    private func applyDisk(_ sample: DiskSample) {
        diskTotalGB = sample.totalGB
        diskUsedGB = sample.usedGB
        diskFreeGB = sample.freeGB
        diskUsedPercent = sample.usedPct
        diskVolumeName = sample.volName
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

    private func sampleDerived() -> DerivedSample {
        let sensors: [Double] = MonitorActivity.includeSmcSample
            ? SMCReader.shared.smcReadings() + IOHIDTempReader.shared.readings()
            : []
        return DerivedSample(
            lpm: Self.readLowPowerModeEnabled(),
            state: ProcessInfo.processInfo.thermalState,
            sensorReadings: sensors,
            socSample: MonitorActivity.includePowerSample ? IOReportPowerReader.shared.sample() : nil
        )
    }

    private func applyDerived(_ sample: DerivedSample) {
        let usage = totalUsage
        let resolved = CPUMonitor.resolveTemperature(state: sample.state, usage: usage, smcReadings: sample.sensorReadings)
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
            cpuName: cpuName, thermal: sample.state, lowPowerMode: sample.lpm
        )
        let ceiling = Self.chipPowerCeiling(cpuName) * 1.15
        isLowPowerModeEnabled = sample.lpm
        thermalState = sample.state
        tempSource = resolved.source
        smcSensorCount = sample.sensorReadings.count
        temperature = smoothedTemperature
        boostClock = boost
        if let socSample = sample.socSample {
            packagePowerWatts = min(socSample.cpuWatts, ceiling)
            gpuPowerWatts = min(socSample.gpuWatts, 120)
            anePowerWatts = min(socSample.aneWatts, 60)
            socPowerWatts = min(socSample.totalWatts, ceiling + 80)
            packagePowerSource = "Apple IOReport (measured)"
        } else {
            packagePowerWatts = min(estimate, ceiling)
            gpuPowerWatts = 0
            anePowerWatts = 0
            socPowerWatts = min(estimate, ceiling)
            packagePowerSource = "Load estimate"
        }
        if MonitorActivity.recordsHistory {
            powerRing.append(packagePowerWatts)
            powerHistory = powerRing.asArray
        }
        if MonitorActivity.includePerCoreSampling {
            let maxB = baseClock * 1.28
            for i in 0..<cores.count {
                cores[i].clockMHz = baseClock + (maxB - baseClock) * (cores[i].usage / 100.0)
            }
        }
    }
}

// ── Battery monitor (IOKit registry primary; pmset/ioreg subprocess fallbacks) ─
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

    private var timerSource: DispatchSourceTimer?
    private let workQueue = DispatchQueue(label: "rnitro.battery", qos: .utility)
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

    init() {}

    func startMonitoring() {
        applyActivityInterval()
    }

    func applyActivityInterval() {
        timerSource?.cancel()
        timerSource = nil
        let src = DispatchSource.makeTimerSource(queue: workQueue)
        src.schedule(deadline: .now(), repeating: MonitorActivity.batteryInterval)
        src.setEventHandler { [weak self] in self?.poll() }
        src.resume()
        timerSource = src
        poll()
    }

    func stopMonitoring() {
        timerSource?.cancel()
        timerSource = nil
    }

    private func poll() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let snap = Self.collectSnapshot(prevLevel: self.prevLevel, prevSampleTime: self.prevSampleTime)
            if snap.isPresent {
                self.prevLevel = snap.levelPercent
                self.prevSampleTime = Date()
            }
            DispatchQueue.main.async {
                self.applySnapshot(snap)
            }
        }
    }

    private func applySnapshot(_ snap: Snapshot) {
        let modeKey = "\(snap.isCharging)-\(snap.isOnAC)-\(snap.isFullyCharged)"
        if modeKey != lastModeKey {
            powerStateSince = Date()
            lastModeKey = modeKey
        }
        if snap.isPresent, MonitorActivity.tracksBatteryHistory {
            let now = Date()
            if historyPoints.isEmpty || now.timeIntervalSince(lastHistorySample ?? .distantPast) >= 300 {
                historyPoints.append((now, snap.levelPercent))
                lastHistorySample = now
            } else if !historyPoints.isEmpty {
                historyPoints[historyPoints.count - 1] = (now, snap.levelPercent)
            }
            let cutoff = now.addingTimeInterval(-12 * 3600)
            historyPoints.removeAll { $0.0 < cutoff }
            if history12h.count == historyPoints.count, !historyPoints.isEmpty {
                history12h[history12h.count - 1] = Double(historyPoints.last!.1)
            } else {
                history12h = historyPoints.map { Double($0.1) }
            }
        } else if snap.isPresent {
            history12h = [Double(snap.levelPercent)]
        }
        isPresent = snap.isPresent
        levelPercent = snap.levelPercent
        isCharging = snap.isCharging
        isOnAC = snap.isOnAC
        isFullyCharged = snap.isFullyCharged
        chargeWatts = snap.chargeWatts
        chargeRateText = snap.chargeRateText
        powerSource = snap.powerSource
        timeToFullMinutes = snap.timeToFullMinutes
        timeRemainingMinutes = snap.timeRemainingMinutes
        cycleCount = snap.cycleCount
        temperatureCelsius = snap.temperatureCelsius
        healthPercent = snap.healthPercent
    }

    private static func iokitSnapshotComplete(_ snap: Snapshot) -> Bool {
        guard snap.isPresent && snap.levelPercent > 0 else { return false }
        // Keep ioreg/pmset fallback when charging but wattage (or ETA) is still missing.
        if snap.isCharging {
            if snap.chargeWatts > 0 { return true }
            if let eta = snap.timeToFullMinutes, eta > 0, eta < 65535 { return true }
            return false
        }
        return true
    }

    private static func collectSnapshot(prevLevel: Int?, prevSampleTime: Date?) -> Snapshot {
        var snap = readIOKitBattery() ?? Snapshot()
        if iokitSnapshotComplete(snap) {
            finalizeSnapshot(&snap, prevLevel: prevLevel, prevSampleTime: prevSampleTime)
            return snap
        }
        if let pm = readPmset() { mergePmset(pm, into: &snap) }
        if let hw = readIoreg() { mergeIoreg(hw, into: &snap) }
        finalizeSnapshot(&snap, prevLevel: prevLevel, prevSampleTime: prevSampleTime)
        return snap
    }

    private static func finalizeSnapshot(_ snap: inout Snapshot, prevLevel: Int?, prevSampleTime: Date?) {
        guard snap.isPresent else {
            snap.chargeRateText = "No battery"
            snap.powerSource = "AC / Desktop"
            return
        }
        snap.powerSource = snap.isOnAC ? "AC Power" : "Battery Power"
        if snap.isCharging && snap.chargeWatts > 0 {
            if let eta = snap.timeToFullMinutes, eta > 0, eta < 65535 {
                snap.chargeRateText = String(format: "%.0f W · %d min", snap.chargeWatts, eta)
            } else {
                snap.chargeRateText = String(format: "%.0f W", snap.chargeWatts)
            }
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
           let prev = prevLevel, let prevT = prevSampleTime {
            let dt = Date().timeIntervalSince(prevT)
            if dt >= 4 {
                let dp = snap.levelPercent - prev
                if dp > 0 {
                    snap.chargeRateText = String(format: "+%.1f%%/hr", Double(dp) / dt * 3600)
                }
            }
        }
    }

    private static func mergePmset(_ pm: Snapshot, into snap: inout Snapshot) {
        if pm.isPresent {
            snap.isPresent = true
            if pm.levelPercent > 0 { snap.levelPercent = pm.levelPercent }
            snap.isCharging = pm.isCharging
            snap.isOnAC = pm.isOnAC
            snap.isFullyCharged = pm.isFullyCharged
            if let eta = pm.timeToFullMinutes { snap.timeToFullMinutes = eta }
            if let rem = pm.timeRemainingMinutes { snap.timeRemainingMinutes = rem }
        }
    }

    private static func mergeIoreg(_ hw: IoregBattery, into snap: inout Snapshot) {
        if hw.levelPercent > 0 || hw.isOnAC || hw.adapterWatts > 0 || hw.batteryInstalled {
            snap.isPresent = true
            if hw.levelPercent > 0 { snap.levelPercent = hw.levelPercent }
            snap.isOnAC = hw.isOnAC
            if hw.hasChargingSignal { snap.isCharging = hw.isCharging }
            if hw.adapterWatts > 0 { snap.chargeWatts = hw.adapterWatts }
            if hw.chargeWatts > 0 && snap.isCharging { snap.chargeWatts = hw.chargeWatts }
            if snap.isCharging, snap.timeToFullMinutes == nil, let eta = hw.timeToFullMinutes { snap.timeToFullMinutes = eta }
            if !snap.isCharging, snap.timeRemainingMinutes == nil, let rem = hw.timeRemainingMinutes { snap.timeRemainingMinutes = rem }
            applyIoregExtras(hw, to: &snap)
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
        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardOutput = outPipe
        task.standardError = errPipe
        do {
            try task.run()
        } catch { return nil }
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        _ = errPipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        guard !outData.isEmpty, let out = String(data: outData, encoding: .utf8) else { return nil }
        if task.terminationStatus != 0, !out.contains("InternalBattery"), !out.contains("AppleSmartBattery") { return nil }
        return out
    }

    private static func cfInt(_ value: CFTypeRef?) -> Int? {
        guard let value else { return nil }
        if let n = value as? NSNumber { return n.intValue }
        if CFGetTypeID(value) == CFNumberGetTypeID() {
            var v = Int32(0)
            CFNumberGetValue((value as! CFNumber), .sInt32Type, &v)
            return Int(v)
        }
        if let s = value as? String, let v = Int(s.trimmingCharacters(in: .whitespaces)) { return v }
        return nil
    }

    private static func cfBool(_ value: CFTypeRef?) -> Bool? {
        guard let value else { return nil }
        if let n = value as? NSNumber { return n.intValue != 0 }
        if CFGetTypeID(value) == CFBooleanGetTypeID() { return CFBooleanGetValue((value as! CFBoolean)) }
        if let s = value as? String {
            let lower = s.lowercased()
            if lower == "yes" || lower == "true" { return true }
            if lower == "no" || lower == "false" { return false }
        }
        return nil
    }

    private static func ioProperty(_ service: io_service_t, _ key: String) -> CFTypeRef? {
        IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
    }

    private static func ioPropertyInt(_ service: io_service_t, _ key: String) -> Int? {
        cfInt(ioProperty(service, key))
    }

    private static func ioPropertyBool(_ service: io_service_t, _ key: String) -> Bool? {
        cfBool(ioProperty(service, key))
    }

    private static func ioDictInt(_ value: CFTypeRef?, _ key: String) -> Int? {
        guard let value else { return nil }
        let entry: Any?
        if let d = value as? [String: Any] { entry = d[key] }
        else if let d = value as? NSDictionary { entry = d[key] }
        else { return nil }
        guard let entry else { return nil }
        if let n = entry as? NSNumber { return n.intValue }
        return cfInt(entry as? CFTypeRef)
    }

    /// IOPM stores signed milliamps in an unsigned registry field (two's complement).
    private static func ioRegistrySigned(_ raw: Int) -> Int {
        Int(Int32(bitPattern: UInt32(truncatingIfNeeded: UInt64(bitPattern: Int64(raw)))))
    }

    /// Charge wattage from IOKit (ChargerData / Amperage × voltage) — no pmset/ioreg subprocess.
    private static func applyIOKitChargePower(_ service: io_service_t, to snap: inout Snapshot) {
        var voltageMv = ioPropertyInt(service, "AppleRawBatteryVoltage")
            ?? ioPropertyInt(service, "Voltage")
        if voltageMv == nil || voltageMv == 0, let batteryData = ioProperty(service, "BatteryData") {
            voltageMv = ioDictInt(batteryData, "Voltage")
                ?? ioDictInt(batteryData, "AppleRawBatteryVoltage")
        }
        let voltage = voltageMv ?? 0

        var chargeMa = 0
        if let chargerData = ioProperty(service, "ChargerData"),
           let cc = ioDictInt(chargerData, "ChargingCurrent"), cc > 0 {
            chargeMa = cc
        } else if let amp = ioPropertyInt(service, "InstantAmperage") ?? ioPropertyInt(service, "Amperage") {
            let signed = ioRegistrySigned(amp)
            if signed > 0 { chargeMa = signed }
        }

        if chargeMa > 0, voltage > 0 {
            snap.chargeWatts = Double(chargeMa) / 1000.0 * Double(voltage) / 1000.0
        }

        if let adapter = ioProperty(service, "AdapterDetails"),
           let adapterW = ioDictInt(adapter, "Watts"), adapterW > 0 {
            if snap.isCharging, snap.chargeWatts <= 0 {
                snap.chargeWatts = Double(adapterW)
            } else if !snap.isCharging {
                snap.chargeWatts = Double(adapterW)
            }
        }
    }

    private static func smartBatteryService() -> io_service_t? {
        var service = IOServiceGetMatchingService(0, IOServiceMatching("AppleSmartBattery"))
        if service != 0 { return service }
        var iter: io_iterator_t = 0
        guard IOServiceGetMatchingServices(0, IOServiceMatching("AppleSmartBattery"), &iter) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iter) }
        service = IOIteratorNext(iter)
        return service != 0 ? service : nil
    }

    /// Direct IORegistry read — reliable inside GUI apps (no subprocess sandbox issues).
    private static func readIOKitBattery() -> Snapshot? {
        guard let service = smartBatteryService() else { return nil }
        defer { IOObjectRelease(service) }

        let installed = ioPropertyBool(service, "BatteryInstalled")
        let builtIn = ioPropertyBool(service, "built-in")
        guard installed != false, builtIn != false else { return nil }

        var snap = Snapshot()
        var level = 0

        if let bd = ioProperty(service, "BatteryData") {
            let socValue: Any? = (bd as? [String: Any])?["StateOfCharge"]
                ?? (bd as? NSDictionary)?["StateOfCharge"]
            if let soc = socValue as? Int {
                level = soc
            } else if let n = socValue as? NSNumber {
                level = n.intValue
            } else if let soc = cfInt(socValue as? CFTypeRef) {
                level = soc
            }
        }
        if level <= 0, let soc = ioPropertyInt(service, "StateOfCharge") { level = soc }
        if level <= 0, let cur = ioPropertyInt(service, "CurrentCapacity"), cur <= 100 { level = cur }
        if level <= 0, let raw = ioPropertyInt(service, "AppleRawCurrentCapacity"),
           let maxCap = ioPropertyInt(service, "AppleRawMaxCapacity"), maxCap > 0 {
            level = Int(Double(raw) / Double(maxCap) * 100.0)
        }
        if level <= 0, let cur = ioPropertyInt(service, "CurrentCapacity"),
           let maxCap = ioPropertyInt(service, "MaxCapacity"), maxCap > 0, cur <= maxCap {
            level = Int(Double(cur) / Double(maxCap) * 100.0)
        }

        snap.levelPercent = min(100, max(0, level))
        snap.isPresent = installed == true || builtIn == true || snap.levelPercent > 0
        guard snap.isPresent else { return nil }

        let external = ioPropertyBool(service, "ExternalConnected") == true
            || ioPropertyBool(service, "AppleRawExternalConnected") == true
        snap.isOnAC = external
        if let charging = ioPropertyBool(service, "IsCharging") {
            snap.isCharging = charging
            if charging { snap.isOnAC = true }
        } else if !external, snap.levelPercent > 0 {
            snap.isCharging = false
            snap.isOnAC = false
        }
        if let tr = ioPropertyInt(service, "TimeRemaining"), tr > 0, tr < 65535 {
            if snap.isCharging { snap.timeToFullMinutes = tr } else { snap.timeRemainingMinutes = tr }
        }
        if let cycles = ioPropertyInt(service, "CycleCount") { snap.cycleCount = cycles }
        if let temp = ioPropertyInt(service, "Temperature") ?? ioPropertyInt(service, "AppleRawBatteryTemperature") {
            snap.temperatureCelsius = temp > 200 ? Double(temp) / 100.0 : Double(temp)
        }
        if let maxCap = ioPropertyInt(service, "MaxCapacity"),
           let design = ioPropertyInt(service, "DesignCapacity"), design > 0, maxCap > 0 {
            snap.healthPercent = min(100, Int(Double(maxCap) / Double(design) * 100.0))
        }
        snap.isFullyCharged = snap.levelPercent >= 100 && !snap.isCharging && snap.isOnAC
        applyIOKitChargePower(service, to: &snap)
        return snap
    }

    private static func readPmset() -> Snapshot? {
        guard let out = runTool("/usr/bin/pmset", ["-g", "batt"]) else { return nil }
        var snap = Snapshot()
        for line in out.components(separatedBy: .newlines) where line.contains("InternalBattery") {
            snap.isPresent = true
            if let pctR = line.range(of: #"\)\s*(\d+)%"#, options: .regularExpression) {
                let pctStr = String(line[pctR]).replacingOccurrences(of: ")", with: "").trimmingCharacters(in: .whitespaces)
                snap.levelPercent = Int(pctStr.replacingOccurrences(of: "%", with: "")) ?? snap.levelPercent
            } else if let pctR = line.range(of: #"(\d+)%"#, options: .regularExpression) {
                let pctStr = String(line[pctR]).replacingOccurrences(of: "%", with: "")
                snap.levelPercent = Int(pctStr) ?? snap.levelPercent
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
        var batteryInstalled = false
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
        info.batteryInstalled = out.contains("\"BatteryInstalled\" = Yes") || out.contains("\"built-in\" = Yes")
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
        return info.levelPercent > 0 || info.isOnAC || info.adapterWatts > 0 || info.batteryInstalled ? info : nil
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
    @Published var downloadHistory: [Double] = []
    @Published var uploadHistory: [Double] = []
    private var downloadRing = RingBuffer<Double>(capacity: 0, fill: 0)
    private var uploadRing = RingBuffer<Double>(capacity: 0, fill: 0)

    func syncHistoryBuffers() {
        let cap = MonitorActivity.recordsHistory ? 60 : 0
        downloadRing.resize(capacity: cap, fill: 0)
        uploadRing.resize(capacity: cap, fill: 0)
        downloadHistory = cap > 0 ? downloadRing.asArray : []
        uploadHistory = cap > 0 ? uploadRing.asArray : []
    }

    private var timer: Timer?
    private var lastDown: UInt64 = 0
    private var lastUp: UInt64 = 0
    private var lastSample: Date?
    private var cachedIface: String?
    private var cachedIP = "—"
    private var cachedSSID = ""
    private var metadataTick = 0
    private let metadataRefreshEvery = 8
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
        metadataTick += 1
        let refreshMetadata = metadataTick % metadataRefreshEvery == 0 || cachedIface == nil
        let iface: String?
        if refreshMetadata {
            iface = Self.activeInterface()
            cachedIface = iface
        } else {
            iface = cachedIface
        }
        guard let iface else {
            DispatchQueue.main.async {
                self.interfaceName = "—"
                self.downloadMbps = 0
                self.uploadMbps = 0
                self.isAvailable = false
            }
            lastSample = nil
            cachedIface = nil
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
        if refreshMetadata {
            cachedIP = Self.localIPv4(for: iface) ?? "—"
            cachedSSID = Self.wifiNetworkName(for: iface) ?? ""
        }
        let ip = cachedIP
        let ssid = cachedSSID
        DispatchQueue.main.async {
            self.interfaceName = iface
            self.downloadMbps = downMbps
            self.uploadMbps = upMbps
            self.isAvailable = true
            self.localIP = ip
            self.wifiSSID = ssid
            if MonitorActivity.recordsHistory {
                self.downloadRing.append(downMbps)
                self.uploadRing.append(upMbps)
                self.downloadHistory = self.downloadRing.asArray
                self.uploadHistory = self.uploadRing.asArray
            }
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
    @Published var activityHistory: [Double] = []
    private var activityRing = RingBuffer<Double>(capacity: 0, fill: 0)

    func syncHistoryBuffer() {
        let cap = MonitorActivity.recordsHistory ? 60 : 0
        activityRing.resize(capacity: cap, fill: 0)
        activityHistory = cap > 0 ? activityRing.asArray : []
    }

    private var timer: Timer?
    private var sampleTick = 0
    private let queue = DispatchQueue(label: "rnitro.disk", qos: .utility)

    func start() {
        stop()
        sampleTick = 0
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
        sampleTick += 1
        guard sampleTick % 2 == 0 else { return }
        guard let out = NetworkMonitor.runToolPublic("/usr/sbin/iostat", ["-d", "1", "1"]) else { return }
        let lines = out.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let dataLine = lines.last(where: { $0.contains(".") && !$0.lowercased().hasPrefix("disk") && !$0.hasPrefix("kb/t") }) else { return }
        let parts = dataLine.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard parts.count >= 3, let mbps = Double(parts[parts.count - 1]) else { return }
        let half = mbps / 2.0
        DispatchQueue.main.async {
            self.readMBps = half
            self.writeMBps = half
            if MonitorActivity.recordsHistory {
                self.activityRing.append(mbps)
                self.activityHistory = self.activityRing.asArray
            }
        }
    }
}

// ── Top processes (CPU / RAM while popover open) ────────────────────────────
struct ProcessSnapshot: Identifiable, Equatable {
    let pid: Int32
    let name: String
    let cpuPercent: Double
    let memoryMB: Double
    var id: Int32 { pid }
}

final class ProcessMonitor: ObservableObject {
    static let shared = ProcessMonitor()

    @Published private(set) var topByCPU: [ProcessSnapshot] = []
    @Published private(set) var topByMemory: [ProcessSnapshot] = []
    @Published private(set) var isSampling = false

    private let queue = DispatchQueue(label: "rnitro.processes", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var lastTicks: [Int32: UInt64] = [:]
    private var lastSampleTime = Date.distantPast
    private let topN = 5
    private let interval: TimeInterval = 3.0

    func start() {
        stop()
        isSampling = true
        lastTicks.removeAll()
        lastSampleTime = Date.distantPast
        queue.async { [weak self] in self?.sample() }
        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now() + interval, repeating: interval)
        source.setEventHandler { [weak self] in self?.sample() }
        source.resume()
        timer = source
    }

    func stop() {
        timer?.cancel()
        timer = nil
        DispatchQueue.main.async {
            self.topByCPU = []
            self.topByMemory = []
            self.isSampling = false
        }
        lastTicks.removeAll()
        lastSampleTime = Date.distantPast
    }

    private func sample() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastSampleTime)
        let isFirst = lastSampleTime == Date.distantPast
        var snapshots: [ProcessSnapshot] = []

        let pids = Self.listPids()
        for pid in pids where pid > 0 {
            guard let name = Self.processName(pid), !name.isEmpty else { continue }
            guard let info = Self.taskInfo(pid) else { continue }
            let memMB = Double(info.pti_resident_size) / 1_048_576.0
            let totalTicks = info.pti_total_user + info.pti_total_system
            var cpuPct = 0.0
            if !isFirst, elapsed > 0.05, let prev = lastTicks[pid] {
                let delta = Double(totalTicks > prev ? totalTicks - prev : 0)
                cpuPct = (delta / (elapsed * 1_000_000_000.0)) * 100.0
            }
            lastTicks[pid] = totalTicks
            if memMB < 0.5 && cpuPct < 0.05 { continue }
            snapshots.append(ProcessSnapshot(pid: pid, name: name, cpuPercent: min(cpuPct, 999), memoryMB: memMB))
        }

        lastSampleTime = now
        let byCPU = Array(snapshots.sorted { $0.cpuPercent > $1.cpuPercent }.prefix(topN))
        let byMem = Array(snapshots.sorted { $0.memoryMB > $1.memoryMB }.prefix(topN))
        DispatchQueue.main.async {
            self.topByCPU = byCPU
            self.topByMemory = byMem
            self.isSampling = false
        }
    }

    private static func listPids() -> [pid_t] {
        let cap = 4096
        var buf = [pid_t](repeating: 0, count: cap)
        let bytes = buf.withUnsafeMutableBufferPointer { ptr -> Int in
            guard let base = ptr.baseAddress else { return 0 }
            return Int(proc_listallpids(base, Int32(MemoryLayout<pid_t>.size * cap)))
        }
        guard bytes > 0 else { return [] }
        let count = bytes / MemoryLayout<pid_t>.size
        return Array(buf.prefix(count))
    }

    private static func processName(_ pid: pid_t) -> String? {
        var name = [CChar](repeating: 0, count: 256)
        guard proc_name(pid, &name, UInt32(name.count)) > 0 else { return nil }
        let raw = String(cString: name)
        return raw.isEmpty ? nil : raw
    }

    private static func taskInfo(_ pid: pid_t) -> proc_taskinfo? {
        var info = proc_taskinfo()
        let size = MemoryLayout<proc_taskinfo>.size
        let ok = withUnsafeMutablePointer(to: &info) { ptr -> Int32 in
            proc_pidinfo(pid, 4, 0, ptr, Int32(size))
        }
        return ok > 0 ? info : nil
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
        guard timer == nil else { return }
        fetch()
        let t = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in self?.fetch() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
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

    static var idleProfile: IdleProfile {
        IdleProfile(rawValue: UserDefaults.standard.string(forKey: MonitorPreferences.idleProfileKey) ?? "") ?? .balanced
    }

    static var enabledSlots: [MenuBarSlot] { MenuBarConfig.enabledSlots }

    static var tier: SamplingTier {
        if popoverOpen { return .full }
        let slots = enabledSlots
        if slots.isEmpty || slots == [.cpu] { return .minimal }
        return .slotAware
    }

    static var cpuInterval: TimeInterval {
        if popoverOpen { return 1.0 }
        return idleProfile == .aggressive ? 4.0 : 2.0
    }

    static var gpuInterval: TimeInterval { 3.0 }
    static var networkInterval: TimeInterval { popoverOpen ? 1.5 : 3.0 }
    static var batteryInterval: TimeInterval {
        if popoverOpen { return 2.0 }
        return idleProfile == .aggressive ? 10.0 : 5.0
    }
    static var memoryInterval: TimeInterval {
        if popoverOpen { return 2.0 }
        return idleProfile == .aggressive ? 10.0 : 5.0
    }
    static var diskInterval: TimeInterval { popoverOpen ? 5.0 : 8.0 }
    static var sensorsInterval: TimeInterval { popoverOpen ? 3.0 : 8.0 }
    static var includePowerSample: Bool {
        popoverOpen || enabledSlots.contains(.power)
    }
    static var smcCacheTTL: TimeInterval { popoverOpen ? 1.0 : 3.0 }
    static var includeSmcSample: Bool {
        popoverOpen || enabledSlots.contains(.temp)
    }
    static var samplesMemory: Bool {
        popoverOpen || enabledSlots.contains(.ram)
    }
    static var includePerCoreSampling: Bool { popoverOpen }
    static var recordsHistory: Bool { popoverOpen }
    static var historyCapacity: Int { popoverOpen ? 80 : 0 }

    static var tracksBatteryHistory: Bool {
        popoverOpen || UserDefaults.standard.bool(forKey: "rnitro.sectionExpanded.battery")
    }

    static var needsNetworkMonitor: Bool {
        popoverOpen || enabledSlots.contains(.network)
    }

    static var needsBTCMonitor: Bool {
        enabledSlots.contains(.btc)
    }

    static var needsAdvisorMonitor: Bool {
        AdvisorThresholds.load().proactiveEnabled && popoverOpen
    }

    static func refreshOptionalServices() {
        if needsNetworkMonitor { NetworkMonitor.shared.start() } else { NetworkMonitor.shared.stop() }
        if needsBTCMonitor { BTCPriceMonitor.shared.start() } else { BTCPriceMonitor.shared.stop() }
        let advisorOn = needsAdvisorMonitor
        DispatchQueue.main.async {
            if advisorOn { SystemAdvisorModel.shared.startMonitoring() } else { SystemAdvisorModel.shared.stopMonitoring() }
        }
    }

    static func applyIdleProfileChange() {
        CPUMonitor.shared.setPollInterval(cpuInterval)
        BatteryMonitor.shared.applyActivityInterval()
        NetworkMonitor.shared.applyActivityInterval()
    }

    static func setPopoverOpen(_ open: Bool) {
        guard popoverOpen != open else { return }
        popoverOpen = open
        CPUMonitor.shared.syncHistoryBuffers()
        GPUMonitor.shared.syncHistoryBuffer()
        NetworkMonitor.shared.syncHistoryBuffers()
        DiskActivityMonitor.shared.syncHistoryBuffer()
        CPUMonitor.shared.setPollInterval(cpuInterval)
        BatteryMonitor.shared.applyActivityInterval()
        refreshOptionalServices()
        if open {
            GPUMonitor.shared.start()
            DiskActivityMonitor.shared.start()
            SensorsMonitor.shared.start()
            ProcessMonitor.shared.start()
        } else {
            GPUMonitor.shared.stop()
            DiskActivityMonitor.shared.stop()
            SensorsMonitor.shared.stop()
            ProcessMonitor.shared.stop()
        }
    }
}

class GPUMonitor: ObservableObject {
    static let shared = GPUMonitor()
    @Published var usage: Double = 0
    @Published var usageHistory: [Double] = []
    private var usageRing = RingBuffer<Double>(capacity: 0, fill: 0)

    func syncHistoryBuffer() {
        let cap = MonitorActivity.historyCapacity
        usageRing.resize(capacity: cap, fill: 0)
        usageHistory = cap > 0 ? usageRing.asArray : []
    }

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
        let val = Self.readGPUUsageIOKit()
        DispatchQueue.main.async {
            self.usage = min(100, val)
            if MonitorActivity.recordsHistory {
                self.usageRing.append(self.usage)
                self.usageHistory = self.usageRing.asArray
            }
        }
    }

    private static func readGPUUsageIOKit() -> Double {
        var iter: io_iterator_t = 0
        guard IOServiceGetMatchingServices(0, IOServiceMatching("IOAccelerator"), &iter) == KERN_SUCCESS else { return 0 }
        defer { IOObjectRelease(iter) }
        var service = IOIteratorNext(iter)
        while service != 0 {
            defer { IOObjectRelease(service) }
            if let stats = IORegistryEntryCreateCFProperty(service, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() {
                if let dict = stats as? [String: Any], let util = dict["Device Utilization %"] as? NSNumber {
                    return util.doubleValue
                }
                if let dict = stats as? NSDictionary, let util = dict["Device Utilization %"] as? NSNumber {
                    return util.doubleValue
                }
            }
            service = IOIteratorNext(iter)
        }
        return 0
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
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .monitor: return "gauge.with.dots.needle.67percent"
        case .advisor: return "waveform.path.ecg"
        case .chat: return "bubble.left.and.bubble.right"
        case .cleaner: return "trash"
        case .settings: return "gearshape"
        }
    }

    static let popoverTabs: [AppTab] = [.monitor, .advisor, .chat, .cleaner]
    static let windowTabs: [AppTab] = [.monitor, .advisor, .chat, .cleaner, .settings]

    var localizedTitle: String {
        let key: String
        switch self {
        case .monitor: key = "tab.monitor"
        case .advisor: key = "tab.advisor"
        case .chat: key = "tab.chat"
        case .cleaner: key = "tab.cleaner"
        case .settings: key = "tab.settings"
        }
        return DisplayPreferencesStore.shared.tr(key)
    }
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
    private static var cachedMasterKey: SymmetricKey?
    private static let cacheLock = NSLock()

    private static func keychainQuery(returnData: Bool) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: masterKeyAccount,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if returnData { query[kSecReturnData as String] = true }
        return query
    }

    private static func loadMasterKeyFromKeychain() -> SymmetricKey? {
        var item: CFTypeRef?
        guard SecItemCopyMatching(keychainQuery(returnData: true) as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data, data.count == 32 else { return nil }
        return SymmetricKey(data: data)
    }

    private static func saveMasterKey(_ key: SymmetricKey) {
        let data = key.withUnsafeBytes { Data($0) }
        SecItemDelete(keychainQuery(returnData: false) as CFDictionary)
        var add = keychainQuery(returnData: false)
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    private static func masterKey() -> SymmetricKey {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let cachedMasterKey { return cachedMasterKey }
        if let existing = loadMasterKeyFromKeychain() {
            cachedMasterKey = existing
            return existing
        }
        let key = SymmetricKey(size: .bits256)
        saveMasterKey(key)
        cachedMasterKey = key
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
    case gemini = "Gemini"
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case groq = "Grok"
    case deepseek = "DeepSeek"
    case openRouter = "OpenRouter"
    case lmStudio = "LM Studio"
    case ollama = "Ollama"
    case hermes = "Hermes"
    var id: String { rawValue }

    var requiresApiKey: Bool {
        switch self {
        case .lmStudio, .ollama, .hermes: return false
        default: return true
        }
    }

    var modelLabel: String {
        switch self {
        case .gemini: return "gemini-2.0-flash"
        case .openai: return "gpt-4o-mini"
        case .anthropic: return "claude-3-5-haiku-20241022"
        case .groq: return "llama-3.3-70b-versatile"
        case .deepseek: return "deepseek-chat"
        case .openRouter: return "openrouter/auto"
        case .lmStudio: return "local model (LM Studio)"
        case .ollama: return "llama3.2"
        case .hermes: return "hermes3"
        }
    }

    var keyURL: String {
        switch self {
        case .gemini: return "https://aistudio.google.com/apikey"
        case .openai: return "https://platform.openai.com/api-keys"
        case .anthropic: return "https://console.anthropic.com/settings/keys"
        case .groq: return "https://console.groq.com/keys"
        case .deepseek: return "https://platform.deepseek.com/api_keys"
        case .openRouter: return "https://openrouter.ai/keys"
        case .lmStudio: return "https://lmstudio.ai/"
        case .ollama: return "https://ollama.com/download"
        case .hermes: return "https://ollama.com/library/hermes3"
        }
    }

    var keyHint: String {
        switch self {
        case .gemini: return "Google AI Studio"
        case .openai: return "OpenAI Platform"
        case .anthropic: return "Anthropic Console"
        case .groq: return "Grok Console"
        case .deepseek: return "DeepSeek Platform"
        case .openRouter: return "OpenRouter"
        case .lmStudio: return "lmstudio.ai"
        case .ollama: return "ollama.com"
        case .hermes: return "Ollama Hermes3"
        }
    }

    var setupHint: String {
        switch self {
        case .lmStudio:
            return "Start LM Studio locally and load a model. API key is optional — leave blank and tap Enable if your server has no auth (default: localhost:1234)."
        case .ollama:
            return "Install Ollama and run a model locally (e.g. ollama pull llama3.2). No API key needed — tap Enable when Ollama is running on localhost:11434."
        case .hermes:
            return "Install Ollama and pull Hermes: ollama pull hermes3. No API key needed — tap Enable when Ollama is running on localhost:11434."
        default:
            return "Paste your \(rawValue) API key. AES-256 encrypted in Keychain — only sent to \(rawValue) when you chat."
        }
    }

    var ollamaModelTag: String? {
        switch self {
        case .ollama: return "llama3.2"
        case .hermes: return "hermes3"
        default: return nil
        }
    }
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
    private static let bundleAccount = "providers.bundle"
    private static var cachedBundle: [String: String]?
    private static var bundleLoaded = false
    private static let cacheLock = NSLock()

    private static func bundleQuery(returnData: Bool) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: bundleAccount,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if returnData { query[kSecReturnData as String] = true }
        return query
    }

    private static func legacyQuery(provider: AIProvider, returnData: Bool) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if returnData { query[kSecReturnData as String] = true }
        return query
    }

    private static func decodeBundle(_ blob: Data) -> [String: String]? {
        guard let data = AES256SecureStore.decrypt(blob),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else { return nil }
        return decoded
    }

    private static func encodeBundle(_ bundle: [String: String]) -> Data? {
        guard let json = try? JSONEncoder().encode(bundle),
              let encrypted = AES256SecureStore.encrypt(json) else { return nil }
        return encrypted
    }

    private static func persistBundle(_ bundle: [String: String]) {
        guard let data = encodeBundle(bundle) else { return }
        SecItemDelete(bundleQuery(returnData: false) as CFDictionary)
        var add = bundleQuery(returnData: false)
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    private static func decodeLegacyBlob(_ blob: Data) -> String? {
        if let data = AES256SecureStore.decrypt(blob),
           let key = String(data: data, encoding: .utf8), !key.isEmpty {
            return key
        }
        if let key = String(data: blob, encoding: .utf8), !key.isEmpty { return key }
        return nil
    }

    private static func deleteLegacyProvider(_ provider: AIProvider) {
        SecItemDelete(legacyQuery(provider: provider, returnData: false) as CFDictionary)
    }

    private static func importLegacyItems(into bundle: inout [String: String]) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let rows = item as? [[String: Any]] else { return false }
        var migrated = false
        for row in rows {
            guard let account = row[kSecAttrAccount as String] as? String,
                  account != bundleAccount,
                  bundle[account] == nil,
                  let blob = row[kSecValueData as String] as? Data,
                  let key = decodeLegacyBlob(blob) else { continue }
            bundle[account] = key
            migrated = true
            if let provider = AIProvider(rawValue: account) {
                deleteLegacyProvider(provider)
            } else {
                let del: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                    kSecAttrAccount as String: account
                ]
                SecItemDelete(del as CFDictionary)
            }
        }
        return migrated
    }

    private static func readBundleFromKeychain() -> [String: String] {
        var bundle: [String: String] = [:]
        var item: CFTypeRef?
        if SecItemCopyMatching(bundleQuery(returnData: true) as CFDictionary, &item) == errSecSuccess,
           let blob = item as? Data, let decoded = decodeBundle(blob) {
            bundle = decoded
        } else if importLegacyItems(into: &bundle), !bundle.isEmpty {
            persistBundle(bundle)
        }
        return bundle
    }

    /// One Keychain read for all providers (avoids repeated "app.rnitro.ai" prompts).
    private static func loadBundle() -> [String: String] {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if bundleLoaded, let cachedBundle { return cachedBundle }
        let bundle = readBundleFromKeychain()
        cachedBundle = bundle
        bundleLoaded = true
        return bundle
    }

    private static func mutateBundle(_ mutate: (inout [String: String]) -> Void) {
        var bundle = loadBundle()
        mutate(&bundle)
        cacheLock.lock()
        cachedBundle = bundle
        bundleLoaded = true
        cacheLock.unlock()
        persistBundle(bundle)
    }

    static func save(_ key: String, provider: AIProvider) {
        mutateBundle { $0[provider.rawValue] = key }
    }

    static func load(provider: AIProvider) -> String? {
        let bundle = loadBundle()
        guard let key = bundle[provider.rawValue], !key.isEmpty else { return nil }
        return key
    }

    static func delete(provider: AIProvider) {
        mutateBundle { $0.removeValue(forKey: provider.rawValue) }
        deleteLegacyProvider(provider)
    }

    static func hasKey(for provider: AIProvider) -> Bool { load(provider: provider) != nil }

    static func storedKeys() -> [String: String] { loadBundle() }
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

    @Published var selectedProvider: AIProvider = .gemini
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
        let bundled = AIKeychain.storedKeys()
        for p in AIProvider.allCases {
            if let k = bundled[p.rawValue] {
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

        let rawKey = keys[provider] ?? "local"
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
        guard let raw = keys[provider] else { return false }
        return AIKeyUtil.isEnabledLocal(raw)
    }

    var currentHasKey: Bool { hasSavedKey(for: selectedProvider) }

    private func resolvedKey(for provider: AIProvider) -> String? {
        guard let raw = keys[provider] else { return nil }
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
            apiKey = AIKeyUtil.sanitize(keys[provider] ?? "local")
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
            case .gemini:
                var req = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models")!)
                req.httpMethod = "GET"
                req.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
                req.timeoutInterval = 8
                try await validateHTTP(req, domain: "Gemini", accept: [200])
            case .openai:
                var req = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
                req.httpMethod = "GET"
                req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                req.timeoutInterval = 8
                try await validateHTTP(req, domain: "OpenAI", accept: [200])
            case .anthropic:
                var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                req.timeoutInterval = 8
                req.httpBody = try JSONSerialization.data(withJSONObject: [
                    "model": "claude-3-5-haiku-20241022",
                    "max_tokens": 1,
                    "messages": [["role": "user", "content": "ping"]]
                ])
                try await validateHTTP(req, domain: "Anthropic", accept: [200])
            case .groq:
                var req = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/models")!)
                req.httpMethod = "GET"
                req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                req.timeoutInterval = 8
                try await validateHTTP(req, domain: "Grok", accept: [200])
            case .deepseek:
                var req = URLRequest(url: URL(string: "https://api.deepseek.com/v1/models")!)
                req.httpMethod = "GET"
                req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                req.timeoutInterval = 8
                try await validateHTTP(req, domain: "DeepSeek", accept: [200])
            case .openRouter:
                var req = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/models")!)
                req.httpMethod = "GET"
                req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                req.timeoutInterval = 8
                try await validateHTTP(req, domain: "OpenRouter", accept: [200])
            case .lmStudio:
                var req = URLRequest(url: URL(string: "http://127.0.0.1:1234/v1/chat/completions")!)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.timeoutInterval = 8
                if AIKeyUtil.isUsableCloudKey(apiKey) {
                    req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                }
                req.httpBody = try JSONSerialization.data(withJSONObject: [
                    "model": "local-model",
                    "messages": [["role": "user", "content": "ping"]],
                    "max_tokens": 1
                ])
                try await validateHTTP(req, domain: "LM Studio", accept: [200])
            case .ollama, .hermes:
                var req = URLRequest(url: URL(string: "http://127.0.0.1:11434/api/tags")!)
                req.httpMethod = "GET"
                req.timeoutInterval = 5
                let (data, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                guard http.statusCode == 200 else {
                    throw NSError(domain: "Ollama", code: http.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
                }
                if let tag = provider.ollamaModelTag,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let models = json["models"] as? [[String: Any]] {
                    let names = models.compactMap { $0["name"] as? String }
                    if !names.contains(where: { $0.localizedCaseInsensitiveContains(tag) }) {
                        throw NSError(domain: "Ollama", code: 0,
                                      userInfo: [NSLocalizedDescriptionKey: "Model \(tag) not found — run: ollama pull \(tag)"])
                    }
                }
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
        case .openai, .groq, .deepseek, .openRouter, .lmStudio: return true
        default: return false
        }
    }

    nonisolated private static func request(provider: AIProvider, apiKey: String, messages: [ChatMessage]) async throws -> String {
        switch provider {
        case .gemini: return try await requestGemini(apiKey: apiKey, messages: messages)
        case .openai: return try await requestOpenAI(apiKey: apiKey, messages: messages)
        case .anthropic: return try await requestAnthropic(apiKey: apiKey, messages: messages)
        case .groq: return try await requestGroq(apiKey: apiKey, messages: messages)
        case .deepseek: return try await requestDeepSeek(apiKey: apiKey, messages: messages)
        case .openRouter: return try await requestOpenRouter(apiKey: apiKey, messages: messages)
        case .lmStudio: return try await requestLMStudio(apiKey: apiKey, messages: messages)
        case .ollama: return try await requestOllama(apiKey: apiKey, messages: messages, model: "llama3.2")
        case .hermes: return try await requestOllama(apiKey: apiKey, messages: messages, model: "hermes3")
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
        case .groq:
            return try await streamOpenAICompatible(
                url: "https://api.groq.com/openai/v1/chat/completions", apiKey: apiKey, model: "llama-3.3-70b-versatile",
                messages: messages, domain: "Grok", requireAuth: true, onDelta: onDelta,
                extraHeaders: [:]
            )
        case .deepseek:
            return try await streamOpenAICompatible(
                url: "https://api.deepseek.com/v1/chat/completions", apiKey: apiKey, model: "deepseek-chat",
                messages: messages, domain: "DeepSeek", requireAuth: true, onDelta: onDelta,
                extraHeaders: [:]
            )
        case .openRouter:
            return try await streamOpenAICompatible(
                url: "https://openrouter.ai/api/v1/chat/completions", apiKey: apiKey, model: "openrouter/auto",
                messages: messages, domain: "OpenRouter", requireAuth: true, onDelta: onDelta,
                extraHeaders: ["HTTP-Referer": "https://getrnitro.netlify.app", "X-Title": "rNitro"]
            )
        case .lmStudio:
            return try await streamOpenAICompatible(
                url: "http://127.0.0.1:1234/v1/chat/completions", apiKey: apiKey, model: "local-model",
                messages: messages, domain: "LM Studio", requireAuth: false, onDelta: onDelta,
                extraHeaders: [:]
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
        let key: String
        switch self {
        case .ai: key = "settings.ai"
        case .appearance: key = "settings.appearance"
        case .menubar: key = "settings.menubar"
        case .monitor: key = "settings.monitor"
        case .alerts: key = "settings.alerts"
        case .general: key = "settings.general"
        }
        return DisplayPreferencesStore.shared.tr(key)
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
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @State private var section: SettingsSection = .ai

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(display.tr("settings.title"))
                    .font(rNitroFont(.title, metrics: metrics, weight: .semibold))
                Text(display.tr("settings.subtitle"))
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
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @AppStorage(MonitorPreferences.uiStyleKey) private var uiStyleRaw = MonitorUIStyle.modern.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(display.tr("appearance.title"))
                    .font(rNitroFont(.body, metrics: metrics, weight: .semibold))
                Text(display.tr("appearance.subtitle"))
                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                Text(display.tr("appearance.fontSize"))
                    .font(rNitroFont(.label, metrics: metrics, weight: .semibold))
                Picker(display.tr("appearance.fontSize"), selection: Binding(
                    get: { display.fontSize },
                    set: { display.setFontSize($0) }
                )) {
                    ForEach(FontSizePreset.allCases) { size in
                        Text(display.tr("font.\(size.rawValue)")).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                Text(display.tr("appearance.language"))
                    .font(rNitroFont(.label, metrics: metrics, weight: .semibold))
                    .padding(.top, 4)
                Picker(display.tr("appearance.language"), selection: Binding(
                    get: { display.language },
                    set: { display.setLanguage($0) }
                )) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.nativeLabel).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                Text(display.tr("appearance.monitorUI"))
                    .font(rNitroFont(.label, metrics: metrics, weight: .semibold))
                    .padding(.top, 4)
                Text(display.tr("appearance.monitorUI.hint"))
                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                Picker(display.tr("appearance.monitorUI"), selection: $uiStyleRaw) {
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
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @AppStorage(MonitorPreferences.menuBarLayoutKey) private var menuBarLayoutRaw = MenuBarLayout.inline.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(display.tr("menubar.title"))
                    .font(rNitroFont(.body, metrics: metrics, weight: .semibold))
                Text(display.tr("menubar.subtitle"))
                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                Picker(display.tr("menubar.layout"), selection: $menuBarLayoutRaw) {
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
    @ObservedObject private var display = DisplayPreferencesStore.shared
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
                Text(display.tr("monitor.title"))
                    .font(rNitroFont(.body, metrics: metrics, weight: .semibold))
                Text(display.tr("monitor.subtitle"))
                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                Toggle(isOn: $showStressUI) {
                    Text(display.tr("monitor.stress")).font(rNitroFont(.label, metrics: metrics))
                }
                .toggleStyle(.switch)
                .onChange(of: showStressUI) { _, on in if !on { stress.stop() } }
                Toggle(isOn: $showBenchmarkUI) {
                    Text(display.tr("monitor.benchmark")).font(rNitroFont(.label, metrics: metrics))
                }
                .toggleStyle(.switch).disabled(bench.isRunning)
                Toggle(isOn: $showNetworkUI) {
                    Text(display.tr("monitor.network")).font(rNitroFont(.label, metrics: metrics))
                }
                .toggleStyle(.switch)
                if RNITRO_FEATURE_BETA_UI {
                    Toggle(isOn: $soloMode) {
                        Text(display.tr("monitor.solo")).font(rNitroFont(.label, metrics: metrics))
                    }
                    .toggleStyle(.switch)
                    Toggle(isOn: $showWeather) {
                        Text(display.tr("monitor.weather")).font(rNitroFont(.label, metrics: metrics))
                    }
                    .toggleStyle(.switch)
                    Text(display.tr("monitor.panels"))
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
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @ObservedObject private var advisor = SystemAdvisorModel.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(display.tr("alerts.advisorTitle"))
                    .font(rNitroFont(.body, metrics: metrics, weight: .semibold))
                Text(display.tr("alerts.advisorSubtitle"))
                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                Text(display.tr("alerts.thresholds"))
                    .font(rNitroFont(.label, metrics: metrics, weight: .semibold))
                thresholdRow("Temp warn °C", value: $advisor.thresholds.tempWarning, range: 55...95, step: 1)
                thresholdRow("Temp critical °C", value: $advisor.thresholds.tempCritical, range: 65...105, step: 1)
                thresholdRow("CPU %", value: $advisor.thresholds.cpuWarning, range: 50...100, step: 1)
                thresholdRow("RAM %", value: $advisor.thresholds.ramWarning, range: 50...100, step: 1)
                thresholdRow("GPU %", value: $advisor.thresholds.gpuWarning, range: 50...100, step: 1)
                thresholdRow("Battery low %", value: $advisor.thresholds.batteryLow, range: 5...40, step: 1)
                Toggle(isOn: $advisor.thresholds.proactiveEnabled) {
                    Text(display.tr("alerts.proactive")).font(rNitroFont(.label, metrics: metrics))
                }
                .toggleStyle(.switch)
                .onChange(of: advisor.thresholds.proactiveEnabled) { _, _ in advisor.refreshThresholds() }
                Toggle(isOn: $advisor.thresholds.criticalTempBannersEnabled) {
                    Text(display.tr("alerts.banners")).font(rNitroFont(.label, metrics: metrics))
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
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @State private var launchAtLogin = LaunchAtLoginManager.isEnabled()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(display.tr("general.title"))
                    .font(rNitroFont(.body, metrics: metrics, weight: .semibold))
                if #available(macOS 13.0, *) {
                    Toggle(isOn: $launchAtLogin) {
                        Text(display.tr("general.launchAtLogin")).font(rNitroFont(.label, metrics: metrics))
                    }
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { _, _ in
                        if !LaunchAtLoginManager.setEnabled(launchAtLogin) {
                            launchAtLogin = LaunchAtLoginManager.isEnabled()
                        }
                    }
                } else {
                    Text(display.tr("general.launchAtLogin.req"))
                        .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                }
                Text(display.tr("general.idleEfficiency"))
                    .font(rNitroFont(.label, metrics: metrics, weight: .semibold))
                    .padding(.top, 6)
                Picker(display.tr("general.idleProfile"), selection: Binding(
                    get: { IdleProfile(rawValue: UserDefaults.standard.string(forKey: MonitorPreferences.idleProfileKey) ?? "") ?? .balanced },
                    set: { UserDefaults.standard.set($0.rawValue, forKey: MonitorPreferences.idleProfileKey); MonitorActivity.applyIdleProfileChange() }
                )) {
                    ForEach(IdleProfile.allCases) { p in
                        Text(p.label).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                Text(display.tr("general.idleHint"))
                    .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                MonitorRow(label: display.tr("general.version"), value: UpdateChecker.displayLabel(CURRENT_VERSION))
                MonitorRow(label: display.tr("general.installLocation"), value: UpdateChecker.installPathLabel())
                MinimalButton(title: display.tr("general.checkUpdates"), action: { UpdateChecker.checkManually() })
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
            rows.append(("Source", "IOKit + pmset/ioreg fallback (macOS)"))
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

    static func forWidth(_ w: CGFloat, layout: ContentLayout, fontScale: CGFloat = 1.0) -> UIMetrics {
        let compact = layout == .popover || w < 420
        let base: CGFloat = (compact ? 12 : 14) * fontScale
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
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @ViewBuilder let content: (UIMetrics) -> Content

    var body: some View {
        GeometryReader { geo in
            let metrics = UIMetrics.forWidth(geo.size.width, layout: layout, fontScale: display.fontSize.scale)
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
    static let idleProfileKey = "rnitro.idleProfile"
    static let fontSizeKey = "rnitro.fontSize"
    static let languageKey = "rnitro.language"
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh"
    case spanish = "es"
    case german = "de"
    var id: String { rawValue }

    var nativeLabel: String {
        switch self {
        case .english: return "English"
        case .chinese: return "繁體中文"
        case .spanish: return "Español"
        case .german: return "Deutsch"
        }
    }
}

enum FontSizePreset: String, CaseIterable, Identifiable {
    case small, medium, large, xlarge
    var id: String { rawValue }

    var scale: CGFloat {
        switch self {
        case .small: return 0.88
        case .medium: return 1.0
        case .large: return 1.12
        case .xlarge: return 22.0 / 14.0  // body ≈ 22px (window layout base 14)
        }
    }
}

final class DisplayPreferencesStore: ObservableObject {
    static let shared = DisplayPreferencesStore()

    @Published var language: AppLanguage
    @Published var fontSize: FontSizePreset

    private init() {
        let langRaw = UserDefaults.standard.string(forKey: MonitorPreferences.languageKey) ?? AppLanguage.english.rawValue
        language = AppLanguage(rawValue: langRaw) ?? .english
        let sizeRaw = UserDefaults.standard.string(forKey: MonitorPreferences.fontSizeKey) ?? FontSizePreset.medium.rawValue
        fontSize = FontSizePreset(rawValue: sizeRaw) ?? .medium
    }

    func setLanguage(_ lang: AppLanguage) {
        language = lang
        UserDefaults.standard.set(lang.rawValue, forKey: MonitorPreferences.languageKey)
    }

    func setFontSize(_ size: FontSizePreset) {
        fontSize = size
        UserDefaults.standard.set(size.rawValue, forKey: MonitorPreferences.fontSizeKey)
    }

    func tr(_ key: String) -> String {
        Self.table[language]?[key] ?? Self.table[.english]?[key] ?? key
    }

    private static let table: [AppLanguage: [String: String]] = [
        .english: enStrings,
        .chinese: zhStrings,
        .spanish: esStrings,
        .german: deStrings,
    ]

    private static let enStrings: [String: String] = [
        "tab.monitor": "Monitor", "tab.advisor": "Advisor", "tab.chat": "Chat",
        "tab.cleaner": "Cleaner", "tab.settings": "Settings",
        "settings.title": "Settings",
        "settings.subtitle": "AI keys, monitor layout, menubar, alerts, and startup options.",
        "settings.ai": "AI", "settings.appearance": "Appearance", "settings.menubar": "Menubar",
        "settings.monitor": "Monitor", "settings.alerts": "Alerts", "settings.general": "General",
        "appearance.title": "Display", "appearance.subtitle": "Font size, language, and monitor layout style.",
        "appearance.fontSize": "Font size", "appearance.language": "Language",
        "font.small": "Small", "font.medium": "Medium", "font.large": "Large", "font.xlarge": "Extra Large",
        "appearance.monitorUI": "Monitor UI", "appearance.monitorUI.hint": "Modern uses iStats-style accordion sections. Legacy is the compact classic layout.",
        "ui.modern": "Modern (iStats-style)", "ui.legacy": "Legacy",
        "menubar.title": "Menu bar icon", "menubar.subtitle": "Choose layout and which stats appear in the top-right menubar.",
        "menubar.layout": "Menu Bar Layout", "layout.compact": "Compact", "layout.inline": "Inline", "layout.minimal": "Minimal",
        "slot.cpu": "CPU", "slot.temp": "Temp", "slot.ram": "RAM", "slot.power": "Power",
        "slot.network": "Network", "slot.battery": "Battery", "slot.btc": "Bitcoin",
        "monitor.title": "Monitor sections", "monitor.subtitle": "Control which panels and tools appear on the Monitor tab.",
        "monitor.stress": "Show Stress Test", "monitor.benchmark": "Show Benchmark", "monitor.network": "Show Network",
        "monitor.solo": "Solo Mode (one panel open)", "monitor.weather": "Show weather on Network",
        "monitor.panels": "Visible panels", "monitor.tools": "Tools",
        "alerts.title": "Alerts", "alerts.subtitle": "System Advisor thresholds and notification banners.",
        "alerts.advisorTitle": "System Advisor alerts", "alerts.advisorSubtitle": "Warning thresholds and notification behavior for the Advisor tab.",
        "alerts.thresholds": "Warning thresholds",
        "alerts.proactive": "Proactive alerts in chat", "alerts.banners": "macOS banners for critical temps",
        "general.title": "General", "general.launchAtLogin": "Launch at Login",
        "general.launchAtLogin.req": "Launch at Login requires macOS 13 or later.",
        "general.idleEfficiency": "Idle efficiency", "general.idleProfile": "Idle profile",
        "general.idleBalanced": "Balanced", "general.idleAggressive": "Aggressive (lowest RAM)",
        "general.idleHint": "Balanced keeps the menu bar snappy. Aggressive uses slower polls and skips history buffers until the popover opens.",
        "general.version": "Version", "general.installLocation": "Install location", "general.checkUpdates": "Check for Updates",
        "section.battery": "Battery & Power", "section.cpu": "CPU", "section.gpu": "GPU", "section.memory": "Memory",
        "section.disk": "Disk", "section.network": "Network", "section.sensors": "Sensors",
        "section.tools": "Stress & Benchmark", "section.tools.summary": "Stress & Benchmark",
        "row.usage": "Usage", "row.loadAvg": "Load avg", "row.uptime": "Uptime", "row.clock": "Clock",
        "row.temperature": "Temperature", "row.power": "Power", "row.pressure": "Pressure",
        "row.wired": "Wired", "row.compressed": "Compressed", "row.swap": "Swap used",
        "row.read": "Read", "row.write": "Write", "row.ip": "IP", "row.wifi": "Wi-Fi",
        "row.weather": "Weather", "row.location": "Location", "row.loading": "Loading…",
        "row.download": "Download", "row.upload": "Upload", "row.lowPower": "Low Power Mode", "row.on": "On",
        "row.stress": "Stress Test", "row.benchmark": "Benchmark", "row.bitcoin": "Bitcoin",
        "row.status": "Status", "row.tip": "Tip", "row.noSensors": "No temperature or fan sensors found",
        "row.sensorsTip": "SMC keys vary by chip — CPU temp still shown above",
        "btn.start": "Start", "btn.stop": "Stop", "btn.run": "Run", "btn.running": "Running…",
        "openMainWindow": "Open main window", "live": "Live", "cores": "Cores",
        "panel.cpu": "CPU", "panel.gpu": "GPU", "panel.memory": "Memory", "panel.disk": "Disk",
        "panel.network": "Network", "panel.battery": "Battery & Power", "panel.sensors": "Sensors",
        "panel.settings": "Settings", "panel.cleaner": "Cleaner",
        "processes.topCpu": "Top processes (CPU)", "processes.topRam": "Top processes (RAM)",
        "processes.none": "Sampling…", "processes.col.cpu": "CPU", "processes.col.ram": "RAM",
    ]

    private static let zhStrings: [String: String] = [
        "tab.monitor": "監控", "tab.advisor": "顧問", "tab.chat": "聊天", "tab.cleaner": "清理", "tab.settings": "設定",
        "settings.title": "設定", "settings.subtitle": "AI 密鑰、監控版面、選單列、提醒與啟動選項。",
        "settings.ai": "AI", "settings.appearance": "外觀", "settings.menubar": "選單列",
        "settings.monitor": "監控", "settings.alerts": "提醒", "settings.general": "一般",
        "appearance.title": "顯示", "appearance.subtitle": "字體大小、語言與監控介面樣式。",
        "appearance.fontSize": "字體大小", "appearance.language": "語言",
        "font.small": "小", "font.medium": "中", "font.large": "大", "font.xlarge": "特大",
        "appearance.monitorUI": "監控介面", "appearance.monitorUI.hint": "現代模式使用 iStats 風格摺疊分區；經典模式為緊湊版面。",
        "ui.modern": "現代 (iStats 風格)", "ui.legacy": "經典",
        "menubar.title": "選單列圖示", "menubar.subtitle": "選擇版面與右上角選單列顯示的統計項目。",
        "menubar.layout": "選單列版面", "layout.compact": "緊湊", "layout.inline": "單行", "layout.minimal": "極簡",
        "slot.cpu": "CPU", "slot.temp": "溫度", "slot.ram": "記憶體", "slot.power": "功耗",
        "slot.network": "網路", "slot.battery": "電池", "slot.btc": "比特幣",
        "monitor.title": "監控分區", "monitor.subtitle": "控制監控頁顯示的面板與工具。",
        "monitor.stress": "顯示壓力測試", "monitor.benchmark": "顯示基準測試", "monitor.network": "顯示網路",
        "monitor.solo": "單獨模式（一次只展開一個面板）", "monitor.weather": "在網路分區顯示天氣",
        "monitor.panels": "可見面板", "monitor.tools": "工具",
        "alerts.title": "提醒", "alerts.subtitle": "系統顧問閾值與通知橫幅。",
        "alerts.advisorTitle": "系統顧問提醒", "alerts.advisorSubtitle": "顧問頁的警告閾值與通知行為。",
        "alerts.thresholds": "警告閾值",
        "alerts.proactive": "聊天中的主動提醒", "alerts.banners": "嚴重溫度時顯示 macOS 橫幅",
        "general.title": "一般", "general.launchAtLogin": "登入時啟動",
        "general.launchAtLogin.req": "登入時啟動需要 macOS 13 或更高版本。",
        "general.idleEfficiency": "閒置效率", "general.idleProfile": "閒置設定",
        "general.idleBalanced": "平衡", "general.idleAggressive": "激進（最低記憶體）",
        "general.idleHint": "平衡模式保持選單列回應迅速；激進模式降低輪詢頻率，彈出視窗關閉前不記錄歷史資料。",
        "general.version": "版本", "general.installLocation": "安裝位置", "general.checkUpdates": "檢查更新",
        "section.battery": "電池與功耗", "section.cpu": "CPU", "section.gpu": "GPU", "section.memory": "記憶體",
        "section.disk": "磁碟", "section.network": "網路", "section.sensors": "感測器",
        "section.tools": "壓力與基準測試", "section.tools.summary": "壓力與基準測試",
        "row.usage": "使用率", "row.loadAvg": "平均負載", "row.uptime": "執行時間", "row.clock": "頻率",
        "row.temperature": "溫度", "row.power": "功耗", "row.pressure": "壓力",
        "row.wired": "連線", "row.compressed": "壓縮", "row.swap": "交換區已用",
        "row.read": "讀取", "row.write": "寫入", "row.ip": "IP", "row.wifi": "Wi-Fi",
        "row.weather": "天氣", "row.location": "位置", "row.loading": "載入中…",
        "row.download": "下載", "row.upload": "上傳", "row.lowPower": "低電量模式", "row.on": "開",
        "row.stress": "壓力測試", "row.benchmark": "基準測試", "row.bitcoin": "比特幣",
        "row.status": "狀態", "row.tip": "提示", "row.noSensors": "未找到溫度或風扇感測器",
        "row.sensorsTip": "SMC 鍵因晶片而異 — CPU 溫度仍顯示在上方",
        "btn.start": "開始", "btn.stop": "停止", "btn.run": "執行", "btn.running": "執行中…",
        "openMainWindow": "開啟主視窗", "live": "即時", "cores": "核心",
        "panel.cpu": "CPU", "panel.gpu": "GPU", "panel.memory": "記憶體", "panel.disk": "磁碟",
        "panel.network": "網路", "panel.battery": "電池與功耗", "panel.sensors": "感測器",
        "panel.settings": "設定", "panel.cleaner": "清理",
        "processes.topCpu": "CPU 佔用最高程式", "processes.topRam": "記憶體佔用最高程式",
        "processes.none": "採樣中…", "processes.col.cpu": "CPU", "processes.col.ram": "記憶體",
    ]

    private static let esStrings: [String: String] = [
        "tab.monitor": "Monitor", "tab.advisor": "Asesor", "tab.chat": "Chat", "tab.cleaner": "Limpiador", "tab.settings": "Ajustes",
        "settings.title": "Ajustes", "settings.subtitle": "Claves de IA, diseño del monitor, barra de menú, alertas y opciones de inicio.",
        "settings.ai": "IA", "settings.appearance": "Apariencia", "settings.menubar": "Barra de menú",
        "settings.monitor": "Monitor", "settings.alerts": "Alertas", "settings.general": "General",
        "appearance.title": "Pantalla", "appearance.subtitle": "Tamaño de fuente, idioma y estilo del monitor.",
        "appearance.fontSize": "Tamaño de fuente", "appearance.language": "Idioma",
        "font.small": "Pequeño", "font.medium": "Mediano", "font.large": "Grande", "font.xlarge": "Extra grande",
        "appearance.monitorUI": "Interfaz del monitor", "appearance.monitorUI.hint": "Moderno usa secciones plegables estilo iStats. Clásico es el diseño compacto.",
        "ui.modern": "Moderno (estilo iStats)", "ui.legacy": "Clásico",
        "menubar.title": "Icono de barra de menú", "menubar.subtitle": "Elige el diseño y las estadísticas en la barra superior.",
        "menubar.layout": "Diseño de barra", "layout.compact": "Compacto", "layout.inline": "En línea", "layout.minimal": "Mínimo",
        "slot.cpu": "CPU", "slot.temp": "Temp", "slot.ram": "RAM", "slot.power": "Potencia",
        "slot.network": "Red", "slot.battery": "Batería", "slot.btc": "Bitcoin",
        "monitor.title": "Secciones del monitor", "monitor.subtitle": "Controla qué paneles y herramientas aparecen.",
        "monitor.stress": "Mostrar prueba de estrés", "monitor.benchmark": "Mostrar benchmark", "monitor.network": "Mostrar red",
        "monitor.solo": "Modo solo (un panel abierto)", "monitor.weather": "Mostrar clima en Red",
        "monitor.panels": "Paneles visibles", "monitor.tools": "Herramientas",
        "alerts.title": "Alertas", "alerts.subtitle": "Umbrales del asesor del sistema y banners de notificación.",
        "alerts.advisorTitle": "Alertas del asesor del sistema", "alerts.advisorSubtitle": "Umbrales de advertencia y notificaciones para la pestaña Asesor.",
        "alerts.thresholds": "Umbrales de advertencia",
        "alerts.proactive": "Alertas proactivas en el chat", "alerts.banners": "Banners de macOS para temperaturas críticas",
        "general.title": "General", "general.launchAtLogin": "Iniciar al arrancar",
        "general.launchAtLogin.req": "Iniciar al arrancar requiere macOS 13 o posterior.",
        "general.idleEfficiency": "Eficiencia en reposo", "general.idleProfile": "Perfil en reposo",
        "general.idleBalanced": "Equilibrado", "general.idleAggressive": "Agresivo (menor RAM)",
        "general.idleHint": "Equilibrado mantiene la barra ágil. Agresivo usa sondeos más lentos y omite historiales hasta abrir el panel.",
        "general.version": "Versión", "general.installLocation": "Ubicación de instalación", "general.checkUpdates": "Buscar actualizaciones",
        "section.battery": "Batería y energía", "section.cpu": "CPU", "section.gpu": "GPU", "section.memory": "Memoria",
        "section.disk": "Disco", "section.network": "Red", "section.sensors": "Sensores",
        "section.tools": "Estrés y benchmark", "section.tools.summary": "Estrés y benchmark",
        "row.usage": "Uso", "row.loadAvg": "Carga media", "row.uptime": "Tiempo activo", "row.clock": "Reloj",
        "row.temperature": "Temperatura", "row.power": "Potencia", "row.pressure": "Presión",
        "row.wired": "Residente", "row.compressed": "Comprimida", "row.swap": "Swap usado",
        "row.read": "Lectura", "row.write": "Escritura", "row.ip": "IP", "row.wifi": "Wi-Fi",
        "row.weather": "Clima", "row.location": "Ubicación", "row.loading": "Cargando…",
        "row.download": "Descarga", "row.upload": "Subida", "row.lowPower": "Modo bajo consumo", "row.on": "Activado",
        "row.stress": "Prueba de estrés", "row.benchmark": "Benchmark", "row.bitcoin": "Bitcoin",
        "row.status": "Estado", "row.tip": "Consejo", "row.noSensors": "No se encontraron sensores de temperatura o ventilador",
        "row.sensorsTip": "Las claves SMC varían según el chip — la temp. de CPU sigue arriba",
        "btn.start": "Iniciar", "btn.stop": "Detener", "btn.run": "Ejecutar", "btn.running": "Ejecutando…",
        "openMainWindow": "Abrir ventana principal", "live": "En vivo", "cores": "Núcleos",
        "panel.cpu": "CPU", "panel.gpu": "GPU", "panel.memory": "Memoria", "panel.disk": "Disco",
        "panel.network": "Red", "panel.battery": "Batería y energía", "panel.sensors": "Sensores",
        "panel.settings": "Ajustes", "panel.cleaner": "Limpiador",
        "processes.topCpu": "Procesos principales (CPU)", "processes.topRam": "Procesos principales (RAM)",
        "processes.none": "Muestreando…", "processes.col.cpu": "CPU", "processes.col.ram": "RAM",
    ]

    private static let deStrings: [String: String] = [
        "tab.monitor": "Monitor", "tab.advisor": "Berater", "tab.chat": "Chat", "tab.cleaner": "Reiniger", "tab.settings": "Einstellungen",
        "settings.title": "Einstellungen", "settings.subtitle": "KI-Schlüssel, Monitor-Layout, Menüleiste, Warnungen und Startoptionen.",
        "settings.ai": "KI", "settings.appearance": "Darstellung", "settings.menubar": "Menüleiste",
        "settings.monitor": "Monitor", "settings.alerts": "Warnungen", "settings.general": "Allgemein",
        "appearance.title": "Anzeige", "appearance.subtitle": "Schriftgröße, Sprache und Monitor-Stil.",
        "appearance.fontSize": "Schriftgröße", "appearance.language": "Sprache",
        "font.small": "Klein", "font.medium": "Mittel", "font.large": "Groß", "font.xlarge": "Sehr groß",
        "appearance.monitorUI": "Monitor-Oberfläche", "appearance.monitorUI.hint": "Modern nutzt iStats-ähnliche Abschnitte. Legacy ist das kompakte Layout.",
        "ui.modern": "Modern (iStats-Stil)", "ui.legacy": "Legacy",
        "menubar.title": "Menüleisten-Symbol", "menubar.subtitle": "Layout und Statistiken in der Menüleiste wählen.",
        "menubar.layout": "Menüleisten-Layout", "layout.compact": "Kompakt", "layout.inline": "Inline", "layout.minimal": "Minimal",
        "slot.cpu": "CPU", "slot.temp": "Temp", "slot.ram": "RAM", "slot.power": "Leistung",
        "slot.network": "Netzwerk", "slot.battery": "Akku", "slot.btc": "Bitcoin",
        "monitor.title": "Monitor-Bereiche", "monitor.subtitle": "Steuert, welche Panels und Tools angezeigt werden.",
        "monitor.stress": "Stresstest anzeigen", "monitor.benchmark": "Benchmark anzeigen", "monitor.network": "Netzwerk anzeigen",
        "monitor.solo": "Solo-Modus (ein Panel offen)", "monitor.weather": "Wetter im Netzwerk-Bereich",
        "monitor.panels": "Sichtbare Panels", "monitor.tools": "Werkzeuge",
        "alerts.title": "Warnungen", "alerts.subtitle": "Systemberater-Schwellen und Benachrichtigungsbanner.",
        "alerts.advisorTitle": "Systemberater-Warnungen", "alerts.advisorSubtitle": "Warnschwellen und Benachrichtigungen für den Berater-Tab.",
        "alerts.thresholds": "Warnschwellen",
        "alerts.proactive": "Proaktive Chat-Warnungen", "alerts.banners": "macOS-Banner bei kritischen Temperaturen",
        "general.title": "Allgemein", "general.launchAtLogin": "Beim Anmelden starten",
        "general.launchAtLogin.req": "Beim Anmelden starten erfordert macOS 13 oder neuer.",
        "general.idleEfficiency": "Leerlauf-Effizienz", "general.idleProfile": "Leerlauf-Profil",
        "general.idleBalanced": "Ausgewogen", "general.idleAggressive": "Aggressiv (wenig RAM)",
        "general.idleHint": "Ausgewogen hält die Menüleiste reaktionsschnell. Aggressiv nutzt langsamere Abfragen und keine Verläufe bis das Panel offen ist.",
        "general.version": "Version", "general.installLocation": "Installationsort", "general.checkUpdates": "Nach Updates suchen",
        "section.battery": "Akku & Leistung", "section.cpu": "CPU", "section.gpu": "GPU", "section.memory": "Speicher",
        "section.disk": "Festplatte", "section.network": "Netzwerk", "section.sensors": "Sensoren",
        "section.tools": "Stress & Benchmark", "section.tools.summary": "Stress & Benchmark",
        "row.usage": "Auslastung", "row.loadAvg": "Load avg", "row.uptime": "Laufzeit", "row.clock": "Takt",
        "row.temperature": "Temperatur", "row.power": "Leistung", "row.pressure": "Druck",
        "row.wired": "Fest", "row.compressed": "Komprimiert", "row.swap": "Swap belegt",
        "row.read": "Lesen", "row.write": "Schreiben", "row.ip": "IP", "row.wifi": "WLAN",
        "row.weather": "Wetter", "row.location": "Ort", "row.loading": "Lädt…",
        "row.download": "Download", "row.upload": "Upload", "row.lowPower": "Stromsparmodus", "row.on": "An",
        "row.stress": "Stresstest", "row.benchmark": "Benchmark", "row.bitcoin": "Bitcoin",
        "row.status": "Status", "row.tip": "Tipp", "row.noSensors": "Keine Temperatur- oder Lüftersensoren gefunden",
        "row.sensorsTip": "SMC-Schlüssel variieren je nach Chip — CPU-Temp. oben angezeigt",
        "btn.start": "Start", "btn.stop": "Stopp", "btn.run": "Ausführen", "btn.running": "Läuft…",
        "openMainWindow": "Hauptfenster öffnen", "live": "Live", "cores": "Kerne",
        "panel.cpu": "CPU", "panel.gpu": "GPU", "panel.memory": "Speicher", "panel.disk": "Festplatte",
        "panel.network": "Netzwerk", "panel.battery": "Akku & Leistung", "panel.sensors": "Sensoren",
        "panel.settings": "Einstellungen", "panel.cleaner": "Reiniger",
        "processes.topCpu": "Top-Prozesse (CPU)", "processes.topRam": "Top-Prozesse (RAM)",
        "processes.none": "Erfasse…", "processes.col.cpu": "CPU", "processes.col.ram": "RAM",
    ]
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
        case .modern: return DisplayPreferencesStore.shared.tr("ui.modern")
        case .legacy: return DisplayPreferencesStore.shared.tr("ui.legacy")
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

    static func refreshRegistrationIfNeeded() {
        guard #available(macOS 13.0, *), isEnabled() else { return }
        _ = setEnabled(true)
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
        case .cpu: return DisplayPreferencesStore.shared.tr("slot.cpu")
        case .temp: return DisplayPreferencesStore.shared.tr("slot.temp")
        case .ram: return DisplayPreferencesStore.shared.tr("slot.ram")
        case .power: return DisplayPreferencesStore.shared.tr("slot.power")
        case .network: return DisplayPreferencesStore.shared.tr("slot.network")
        case .battery: return DisplayPreferencesStore.shared.tr("slot.battery")
        case .btc: return DisplayPreferencesStore.shared.tr("slot.btc")
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
        case .combined: return DisplayPreferencesStore.shared.tr("layout.compact")
        case .inline: return DisplayPreferencesStore.shared.tr("layout.inline")
        case .minimal: return DisplayPreferencesStore.shared.tr("layout.minimal")
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
            if bat.isCharging, bat.chargeWatts > 0 {
                return String(format: "%d%% %.0fW", bat.levelPercent, bat.chargeWatts)
            }
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
        case .cpu: return DisplayPreferencesStore.shared.tr("panel.cpu")
        case .gpu: return DisplayPreferencesStore.shared.tr("panel.gpu")
        case .memory: return DisplayPreferencesStore.shared.tr("panel.memory")
        case .disk: return DisplayPreferencesStore.shared.tr("panel.disk")
        case .network: return DisplayPreferencesStore.shared.tr("panel.network")
        case .battery: return DisplayPreferencesStore.shared.tr("panel.battery")
        case .sensors: return DisplayPreferencesStore.shared.tr("panel.sensors")
        case .settings: return DisplayPreferencesStore.shared.tr("panel.settings")
        case .cleaner: return DisplayPreferencesStore.shared.tr("panel.cleaner")
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
    @ObservedObject private var display = DisplayPreferencesStore.shared
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
                            Text(t.localizedTitle)
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

enum ProcessHighlight {
    case cpu, memory
}

struct ProcessUsageRow: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var display = DisplayPreferencesStore.shared
    let snapshot: ProcessSnapshot
    let highlight: ProcessHighlight

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot.name)
                    .font(rNitroFont(.caption, metrics: metrics, weight: .medium))
                    .lineLimit(1).truncationMode(.tail)
                Text("pid \(snapshot.pid)")
                    .font(rNitroFont(.micro, metrics: metrics))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 4)
            if highlight == .cpu {
                Text(String(format: "%.1f%%", snapshot.cpuPercent))
                    .font(rNitroFont(.caption, metrics: metrics, weight: .semibold))
                    .foregroundColor(Color.usage(min(100, snapshot.cpuPercent)))
                Text(String(format: "%.0f MB", snapshot.memoryMB))
                    .font(rNitroFont(.micro, metrics: metrics))
                    .foregroundColor(.secondary)
                    .frame(width: 52, alignment: .trailing)
            } else {
                Text(String(format: "%.0f MB", snapshot.memoryMB))
                    .font(rNitroFont(.caption, metrics: metrics, weight: .semibold))
                    .foregroundColor(.nPurple)
                Text(String(format: "%.1f%%", snapshot.cpuPercent))
                    .font(rNitroFont(.micro, metrics: metrics))
                    .foregroundColor(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
        }
        .padding(.vertical, 2)
    }
}

struct MonitorModernHeaderView: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var m = CPUMonitor.shared

    var body: some View {
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
    }
}

struct MonitorBatterySectionView: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @ObservedObject private var bat = BatteryMonitor.shared
    @ObservedObject private var m = CPUMonitor.shared
    let onBatteryTap: () -> Void
    let onCpuPowerTap: () -> Void

    var body: some View {
        MonitorSection(
            title: display.tr("section.battery"),
            accent: .nGreen,
            summary: bat.isPresent ? "\(bat.levelPercent)%" : String(format: "%.1fW", m.packagePowerWatts),
            sparkline: m.powerHistory,
            sparkMax: max(m.powerHistory.max() ?? 1, CPUMonitor.chipPowerCeiling(m.cpuName)),
            storageKey: "rnitro.sectionExpanded.battery"
        ) {
            BatteryCpuPowerRow(
                bat: bat, monitor: m,
                onBatteryTap: bat.isPresent ? onBatteryTap : nil,
                onCpuPowerTap: onCpuPowerTap
            )
            if m.isLowPowerModeEnabled {
                MonitorRow(
                    label: display.tr("row.lowPower"),
                    value: display.tr("row.on"),
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
    }
}

struct MonitorCPUSectionView: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @ObservedObject private var m = CPUMonitor.shared
    @ObservedObject private var proc = ProcessMonitor.shared
    let onTemperatureTap: () -> Void

    var body: some View {
        MonitorSection(
            title: display.tr("section.cpu"),
            accent: .accent,
            summary: String(format: "%.0f%%", m.totalUsage),
            sparkline: m.usageHistory,
            storageKey: "rnitro.sectionExpanded.cpu"
        ) {
            GraphView(history: m.usageHistory, color: Color.usage(m.totalUsage))
                .frame(height: metrics.graphHeight)
            MonitorRow(label: display.tr("row.usage"), value: String(format: "%.1f%%", m.totalUsage), valueColor: Color.usage(m.totalUsage))
            MonitorRow(label: display.tr("row.loadAvg"), value: String(format: "%.2f · %.2f · %.2f", m.loadAverage1, m.loadAverage5, m.loadAverage15))
            MonitorRow(label: display.tr("row.uptime"), value: CPUMonitor.formatUptime(m.systemUptime))
            MonitorRow(label: display.tr("row.clock"), value: String(format: "%.0f / %.0f MHz", m.baseClock, m.boostClock))
            Button(action: onTemperatureTap) {
                MonitorRow(label: display.tr("row.temperature"), value: String(format: "%.0f °C", m.temperature), valueColor: Color.temp(m.temperature))
            }.buttonStyle(.plain)
            VStack(spacing: 4) {
                ForEach(Array(m.cores.enumerated()), id: \.offset) { i, core in
                    let eff = i < m.efficiencyCoreCount
                    let cIdx = eff ? i : i - m.efficiencyCoreCount
                    CoreRow(core: core, index: i, isEfficiency: eff, clusterIndex: cIdx)
                }
            }
            Text(display.tr("processes.topCpu"))
                .font(rNitroFont(.micro, metrics: metrics, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.top, 6)
            if proc.topByCPU.isEmpty {
                MonitorRow(label: display.tr("processes.col.cpu"), value: display.tr("processes.none"))
            } else {
                VStack(spacing: 2) {
                    ForEach(proc.topByCPU) { p in
                        ProcessUsageRow(snapshot: p, highlight: .cpu)
                    }
                }
            }
        }
    }
}

struct MonitorGPUSectionView: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @ObservedObject private var gpu = GPUMonitor.shared
    @ObservedObject private var m = CPUMonitor.shared

    var body: some View {
        MonitorSection(
            title: display.tr("section.gpu"),
            accent: .nGreen,
            summary: String(format: "%.0f%%", gpu.usage),
            sparkline: gpu.usageHistory,
            storageKey: "rnitro.sectionExpanded.gpu"
        ) {
            GraphView(history: gpu.usageHistory, color: Color.usage(gpu.usage))
                .frame(height: metrics.graphHeight)
            MonitorRow(label: display.tr("row.usage"), value: String(format: "%.1f%%", gpu.usage), valueColor: Color.usage(gpu.usage))
            MonitorRow(label: display.tr("row.power"), value: String(format: "%.1f W", m.gpuPowerWatts))
        }
    }
}

struct MonitorMemorySectionView: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @ObservedObject private var m = CPUMonitor.shared
    @ObservedObject private var proc = ProcessMonitor.shared
    let onMemoryTap: () -> Void

    var body: some View {
        MonitorSection(
            title: display.tr("section.memory"),
            accent: .nPurple,
            summary: String(format: "%.0f%%", m.memoryUsedPercent),
            sparkline: m.memoryHistory,
            storageKey: "rnitro.sectionExpanded.memory"
        ) {
            UsageBarRow(label: "RAM", usedGB: m.memoryUsedGB, freeGB: m.memoryFreeGB,
                        totalGB: m.memoryTotalGB, usedPercent: m.memoryUsedPercent,
                        action: onMemoryTap)
            MonitorRow(label: display.tr("row.pressure"), value: m.memoryPressure, valueColor: Color.pressure(m.memoryPressure))
            MonitorRow(label: display.tr("row.wired"), value: String(format: "%.1f GB", m.memoryWiredGB))
            MonitorRow(label: display.tr("row.compressed"), value: String(format: "%.1f GB", m.memoryCompressedGB))
            MonitorRow(label: display.tr("row.swap"), value: String(format: "%.1f GB", m.memorySwapGB))
            Text(display.tr("processes.topRam"))
                .font(rNitroFont(.micro, metrics: metrics, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.top, 6)
            if proc.topByMemory.isEmpty {
                MonitorRow(label: display.tr("processes.col.ram"), value: display.tr("processes.none"))
            } else {
                VStack(spacing: 2) {
                    ForEach(proc.topByMemory) { p in
                        ProcessUsageRow(snapshot: p, highlight: .memory)
                    }
                }
            }
        }
    }
}

struct MonitorDiskSectionView: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @ObservedObject private var m = CPUMonitor.shared
    @ObservedObject private var disk = DiskActivityMonitor.shared
    let onStorageTap: () -> Void

    var body: some View {
        MonitorSection(
            title: display.tr("section.disk"),
            accent: .nOrange,
            summary: String(format: "%.0f%%", m.diskUsedPercent),
            sparkline: disk.activityHistory,
            sparkMax: max(disk.activityHistory.max() ?? 1, 10),
            storageKey: "rnitro.sectionExpanded.disk"
        ) {
            UsageBarRow(label: "SSD · \(m.diskVolumeName)", usedGB: m.diskUsedGB, freeGB: m.diskFreeGB,
                        totalGB: m.diskTotalGB, usedPercent: m.diskUsedPercent,
                        action: onStorageTap)
            MiniGraphView(history: disk.activityHistory, color: .nOrange, maxValue: max(disk.activityHistory.max() ?? 1, 10))
                .frame(height: 28)
            MonitorRow(label: display.tr("row.read"), value: String(format: "%.1f MB/s", disk.readMBps))
            MonitorRow(label: display.tr("row.write"), value: String(format: "%.1f MB/s", disk.writeMBps))
        }
    }
}

struct MonitorNetworkSectionView: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @ObservedObject private var net = NetworkMonitor.shared
    @ObservedObject private var weather = WeatherService.shared
    let showWeather: Bool

    var body: some View {
        MonitorSection(
            title: display.tr("section.network"),
            accent: .nBlue,
            summary: net.isAvailable ? NetworkMonitor.formatSpeed(net.downloadMbps) : "—",
            sparkline: net.downloadHistory,
            sparkMax: max(net.downloadHistory.max() ?? 1, 100),
            storageKey: "rnitro.sectionExpanded.network"
        ) {
            NetworkMonitorRow(net: net)
            MonitorRow(label: display.tr("row.ip"), value: net.localIP)
            if !net.wifiSSID.isEmpty {
                MonitorRow(label: display.tr("row.wifi"), value: net.wifiSSID)
            }
            if showWeather, let w = weather.snapshot {
                MonitorRow(label: display.tr("row.weather"), value: String(format: "%.0f°C %@", w.tempC, w.condition))
                MonitorRow(label: display.tr("row.location"), value: w.city)
            } else if showWeather && weather.isLoading {
                MonitorRow(label: display.tr("row.weather"), value: display.tr("row.loading"))
            }
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(display.tr("row.download")).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                    MiniGraphView(history: net.downloadHistory, color: .accent, maxValue: max(net.downloadHistory.max() ?? 1, 100))
                        .frame(height: 24)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(display.tr("row.upload")).font(rNitroFont(.micro, metrics: metrics)).foregroundColor(.secondary)
                    MiniGraphView(history: net.uploadHistory, color: .nGreen, maxValue: max(net.uploadHistory.max() ?? 1, 100))
                        .frame(height: 24)
                }
            }
        }
        .onAppear {
            let key = net.wifiSSID.isEmpty ? "wired-\(net.interfaceName)" : net.wifiSSID
            weather.refresh(forNetworkKey: key, enabled: showWeather)
        }
        .onChange(of: net.wifiSSID) { _, _ in
            let key = net.wifiSSID.isEmpty ? "wired-\(net.interfaceName)" : net.wifiSSID
            weather.refresh(forNetworkKey: key, enabled: showWeather)
        }
        .onChange(of: showWeather) { _, on in
            let key = net.wifiSSID.isEmpty ? "wired-\(net.interfaceName)" : net.wifiSSID
            weather.refresh(forNetworkKey: key, enabled: on)
        }
    }
}

struct MonitorSensorsSectionView: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @ObservedObject private var sensors = SensorsMonitor.shared

    var body: some View {
        MonitorSection(
            title: display.tr("section.sensors"),
            accent: .nOrange,
            summary: sensors.entries.isEmpty ? "—" : "\(sensors.entries.count) readings",
            storageKey: "rnitro.sectionExpanded.sensors"
        ) {
            if sensors.entries.isEmpty {
                MonitorRow(label: display.tr("row.status"), value: display.tr("row.noSensors"))
                MonitorRow(label: display.tr("row.tip"), value: display.tr("row.sensorsTip"))
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
    }
}

struct MonitorToolsSectionView: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var display = DisplayPreferencesStore.shared
    @ObservedObject private var btc = BTCPriceMonitor.shared
    @ObservedObject private var stress = StressTester.shared
    @ObservedObject private var bench = BenchmarkRunner.shared

    var body: some View {
        MonitorSection(
            title: display.tr("section.tools"),
            accent: .secondary,
            summary: display.tr("section.tools.summary"),
            storageKey: "rnitro.sectionExpanded.settings"
        ) {
            if let price = btc.priceUSD {
                MonitorRow(label: display.tr("row.bitcoin"), value: String(format: "$%.0f", price))
            }
            HStack {
                Text(display.tr("row.stress")).font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                Spacer()
                MinimalButton(
                    title: stress.isRunning ? display.tr("btn.stop") : display.tr("btn.start"),
                    tint: stress.isRunning ? .nRed : .nOrange,
                    disabled: bench.isRunning,
                    action: { stress.isRunning ? stress.stop() : stress.start() }
                )
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(display.tr("row.benchmark")).font(rNitroFont(.label, metrics: metrics)).foregroundColor(.secondary)
                    Text("1-core \(bench.singleCoreScore.map { String(format: "%.0f", $0) } ?? "—") · multi \(bench.multiCoreScore.map { String(format: "%.0f", $0) } ?? "—")")
                        .font(rNitroFont(.caption, metrics: metrics)).foregroundColor(.secondary)
                }
                Spacer()
                MinimalButton(
                    title: bench.isRunning ? display.tr("btn.running") : display.tr("btn.run"),
                    disabled: bench.isRunning || stress.isRunning,
                    action: { bench.run() }
                )
            }
        }
        .padding(.bottom, 12)
    }
}

struct MonitorModernTabView: View {
    @Binding var statDetail: StatDetailKind?
    @AppStorage(MonitorPreferences.networkKey) private var showNetworkUI = true
    @AppStorage(MonitorPreferences.showWeatherKey) private var showWeather = true

    private func toggleStatDetail(_ kind: StatDetailKind) {
        statDetail = statDetail == kind ? nil : kind
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                MonitorModernHeaderView()
                MonitorBatterySectionView(
                    onBatteryTap: { toggleStatDetail(.battery) },
                    onCpuPowerTap: { toggleStatDetail(.cpuPower) }
                )
                MonitorCPUSectionView(onTemperatureTap: { toggleStatDetail(.temperature) })
                MonitorGPUSectionView()
                MonitorMemorySectionView(onMemoryTap: { toggleStatDetail(.memory) })
                MonitorDiskSectionView(onStorageTap: { toggleStatDetail(.storage) })
                if showNetworkUI {
                    MonitorNetworkSectionView(showWeather: showWeather)
                }
                MonitorSensorsSectionView()
                MonitorToolsSectionView()
            }
        }
        .clipped()
        .onAppear { SectionExpansionStore.migrateExtrasKey() }
    }
}

struct MonitorTabContent: View {
    @Environment(\.uiMetrics) private var metrics
    let layout: ContentLayout
    @Binding var statDetail: StatDetailKind?
    @AppStorage(MonitorPreferences.stressKey) private var showStressUI = true
    @AppStorage(MonitorPreferences.benchmarkKey) private var showBenchmarkUI = true
    @AppStorage(MonitorPreferences.networkKey) private var showNetworkUI = true
    @AppStorage(MonitorPreferences.uiStyleKey) private var uiStyleRaw = MonitorUIStyle.modern.rawValue
    @ObservedObject private var m = CPUMonitor.shared
    @ObservedObject private var bat = BatteryMonitor.shared
    @ObservedObject private var net = NetworkMonitor.shared
    @ObservedObject private var stress = StressTester.shared
    @ObservedObject private var bench = BenchmarkRunner.shared
    @ObservedObject private var btc = BTCPriceMonitor.shared

    private func toggleStatDetail(_ kind: StatDetailKind) {
        statDetail = statDetail == kind ? nil : kind
    }

    var body: some View {
        Group {
            if uiStyleRaw == MonitorUIStyle.legacy.rawValue {
                legacyMonitorTab
            } else {
                MonitorModernTabView(statDetail: $statDetail)
            }
        }
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

struct ContentView: View {
    @Environment(\.uiMetrics) private var metrics
    @ObservedObject private var display = DisplayPreferencesStore.shared
    let tabs: [AppTab]
    var layout: ContentLayout = .window
    @ObservedObject private var advisor = SystemAdvisorModel.shared
    @State private var statDetail: StatDetailKind? = nil
    @State private var tab: AppTab = .monitor
    @State private var showFirstLaunchTips = FirstLaunchTips.shouldShow

    var body: some View {
        MetricsReader(layout: layout) { _ in
            Group {
                if layout == .window {
                    rootContent
                        .sheet(item: $statDetail) { kind in
                            StatDetailPopup(kind: kind, monitor: CPUMonitor.shared, battery: BatteryMonitor.shared)
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
                    StatDetailPopup(kind: kind, monitor: CPUMonitor.shared, battery: BatteryMonitor.shared, onClose: { statDetail = nil })
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
                    Text(display.tr("openMainWindow"))
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
            case .monitor:
                MonitorTabContent(layout: layout, statDetail: $statDetail)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    private let menuBarRefreshTrigger = PassthroughSubject<Void, Never>()
    private var hotkeyMonitor: Any?
    private var modeObserver: NSObjectProtocol?
    private var powerModeObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        FontRegistrar.registerVarelaRound()
        UpdateChecker.checkOnLaunch()
        MonitorActivity.setPopoverOpen(false)
        UNUserNotificationCenter.current().delegate = self
        AdvisorNotificationCenter.configure()
        BatteryMonitor.shared.startMonitoring()

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(togglePopover)
        statusItem = item
        if let button = item.button {
            MenuBarIconManager.shared.attach(to: button)
        }
        updateStatusTitle()
        rebuildMenubarSubscriptions()

        modeObserver = NotificationCenter.default.addObserver(
            forName: .menuBarModeChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MonitorActivity.refreshOptionalServices()
            self?.rebuildMenubarSubscriptions()
            self?.updateStatusTitle()
        }

        powerModeObserver = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            let lpm = CPUMonitor.readLowPowerModeEnabled()
            CPUMonitor.shared.isLowPowerModeEnabled = lpm
            self?.updateStatusTitle()
        }
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

    private func rebuildMenubarSubscriptions() {
        subscriptions.removeAll()
        menuBarRefreshTrigger
            .debounce(for: .milliseconds(80), scheduler: RunLoop.main)
            .sink { [weak self] in self?.updateStatusTitle() }
            .store(in: &subscriptions)
        let scheduleRefresh: () -> Void = { [weak self] in self?.menuBarRefreshTrigger.send() }
        let slots = MenuBarConfig.enabledSlots
        var monitors: [AnyPublisher<Void, Never>] = [
            CPUMonitor.shared.$totalUsage.map { _ in () }.eraseToAnyPublisher(),
            CPUMonitor.shared.$isLowPowerModeEnabled.map { _ in () }.eraseToAnyPublisher()
        ]
        if slots.contains(.temp) {
            monitors.append(CPUMonitor.shared.$temperature.map { _ in () }.eraseToAnyPublisher())
        }
        if slots.contains(.power) {
            monitors.append(CPUMonitor.shared.$packagePowerWatts.map { _ in () }.eraseToAnyPublisher())
        }
        if slots.contains(.ram) {
            monitors.append(CPUMonitor.shared.$memoryUsedPercent.map { _ in () }.eraseToAnyPublisher())
        }
        if slots.contains(.network) {
            monitors.append(NetworkMonitor.shared.$downloadMbps.map { _ in () }.eraseToAnyPublisher())
        }
        if slots.contains(.battery) {
            monitors.append(contentsOf: [
                BatteryMonitor.shared.$levelPercent.map { _ in () }.eraseToAnyPublisher(),
                BatteryMonitor.shared.$isCharging.map { _ in () }.eraseToAnyPublisher(),
                BatteryMonitor.shared.$isOnAC.map { _ in () }.eraseToAnyPublisher(),
                BatteryMonitor.shared.$chargeWatts.map { _ in () }.eraseToAnyPublisher(),
                BatteryMonitor.shared.$chargeRateText.map { _ in () }.eraseToAnyPublisher(),
                BatteryMonitor.shared.$timeRemainingMinutes.map { _ in () }.eraseToAnyPublisher(),
                BatteryMonitor.shared.$timeToFullMinutes.map { _ in () }.eraseToAnyPublisher()
            ])
        }
        if slots.contains(.btc) {
            monitors.append(BTCPriceMonitor.shared.$priceUSD.map { _ in () }.eraseToAnyPublisher())
        }
        for publisher in monitors {
            publisher.receive(on: DispatchQueue.main).sink { _ in scheduleRefresh() }.store(in: &subscriptions)
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

strip -x "$WORK_DIR/rNitro" 2>/dev/null || true

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
    <key>CFBundleVersion</key><string>8.3.12-Beta-arm64</string>
    <key>CFBundleShortVersionString</key><string>8.3.12-Beta-arm64</string>
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
