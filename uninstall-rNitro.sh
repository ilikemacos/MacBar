#!/bin/bash
#
# rNitro uninstaller — hardened
#
# v8.1.2-Beta-arm64 — Removes rNitro.app, Launch at Login registration,
# preferences/caches, and AI API keys from Keychain. Confirms before deleting.
#
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

echo "🗑️  rNitro Uninstaller"
echo "--------------------"

# ── Security: refuse to run via a pipe (curl|bash) ───────────────────────────
if [[ ! -f "$0" ]]; then
  echo "❌ This script must be saved to disk and run directly (e.g. \`bash uninstall-rNitro.sh\`)."
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
  echo "❌ Do not run this uninstaller as root or with sudo. Aborting."
  exit 1
fi

# ── Security: HOME must be a sane, existing directory ────────────────────────
if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
  echo "❌ \$HOME is not set to a valid directory. Aborting."
  exit 1
fi

# ── Security: verify script integrity (SHA-256) ───────────────────────────────
EXPECTED_HASH="d8868c10637c5ae9e79d99ca4afaafac54faec8a0beece0fd1912b0f098733a7"
ACTUAL_HASH="$(sed 's/^EXPECTED_HASH=.*/EXPECTED_HASH="MASKED"/' "$0" | shasum -a 256 | awk '{print $1}')"
if [[ "$EXPECTED_HASH" == "PLACEHOLDER" ]]; then
  echo "⚠️  Integrity hash not set (development copy). Continuing anyway."
elif [[ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]]; then
  echo "❌ Integrity check failed. This file may have been tampered with."
  echo "   Expected: $EXPECTED_HASH"
  echo "   Got:      $ACTUAL_HASH"
  echo "   Download a fresh copy from https://rnitro.netlify.app/"
  exit 1
else
  echo "✅ Integrity check passed."
fi

echo ""

# ── Targets ───────────────────────────────────────────────────────────────────
APP_PATHS=(
  "$HOME/Applications/rNitro.app"
  "/Applications/rNitro.app"
)
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_GLOBS=(
  "com.rnitro.cpumonitor.plist"
  "com.rnitro.*.plist"
  "app.rnitro.*.plist"
)
CACHE_PATHS=(
  "$HOME/Library/Caches/com.rnitro.cpumonitor"
)
PREFS_PATHS=(
  "$HOME/Library/Preferences/com.rnitro.cpumonitor.plist"
)
SUPPORT_PATHS=(
  "$HOME/Library/Application Support/rNitro"
)
KEYCHAIN_SERVICE="app.rnitro.ai"
AI_PROVIDERS=(
  "Gemini" "OpenAI" "Anthropic" "Groq" "DeepSeek"
  "OpenRouter" "LM Studio" "Ollama" "Hermes"
)

# ── Discover what is present ──────────────────────────────────────────────────
FOUND_APPS=()
for p in "${APP_PATHS[@]}"; do
  [[ -e "$p" ]] && FOUND_APPS+=("$p")
done

FOUND_AGENTS=()
if [[ -d "$LAUNCH_AGENT_DIR" ]]; then
  for g in "${LAUNCH_AGENT_GLOBS[@]}"; do
    for f in "$LAUNCH_AGENT_DIR"/$g; do
      [[ -f "$f" ]] && FOUND_AGENTS+=("$f")
    done
  done
fi

FOUND_CACHES=()
for p in "${CACHE_PATHS[@]}"; do
  [[ -e "$p" ]] && FOUND_CACHES+=("$p")
done

FOUND_PREFS=()
for p in "${PREFS_PATHS[@]}"; do
  [[ -f "$p" ]] && FOUND_PREFS+=("$p")
done

FOUND_SUPPORT=()
for p in "${SUPPORT_PATHS[@]}"; do
  [[ -e "$p" ]] && FOUND_SUPPORT+=("$p")
done

FOUND_KEYS=()
if command -v security >/dev/null 2>&1; then
  for provider in "${AI_PROVIDERS[@]}"; do
    if security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$provider" >/dev/null 2>&1; then
      FOUND_KEYS+=("$provider")
    fi
  done
fi

RUNNING="$(pgrep -x rNitro 2>/dev/null || true)"
HAS_LOGIN_ITEM=false
if command -v swift >/dev/null 2>&1; then
  if swift -e 'import ServiceManagement; if #available(macOS 13.0, *) { print(SMAppService.mainApp.status == .enabled ? "yes" : "no") } else { print("no") }' 2>/dev/null | grep -q '^yes$'; then
    HAS_LOGIN_ITEM=true
  fi
fi

TOTAL_ITEMS=0
TOTAL_ITEMS=$(( ${#FOUND_APPS[@]} + ${#FOUND_AGENTS[@]} + ${#FOUND_CACHES[@]} + ${#FOUND_PREFS[@]} + ${#FOUND_SUPPORT[@]} + ${#FOUND_KEYS[@]} ))
[[ -n "$RUNNING" ]] && TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
[[ "$HAS_LOGIN_ITEM" == true ]] && TOTAL_ITEMS=$((TOTAL_ITEMS + 1))

if [[ "$TOTAL_ITEMS" -eq 0 ]]; then
  echo "ℹ️  rNitro does not appear to be installed on this Mac."
  echo "   Nothing to remove."
  exit 0
fi

echo "The following rNitro components were found:"
echo ""

if [[ -n "$RUNNING" ]]; then
  echo "  • Running process: rNitro (PID $RUNNING)"
fi
if [[ "$HAS_LOGIN_ITEM" == true ]]; then
  echo "  • Launch at Login registration (SMAppService)"
fi
[[ ${#FOUND_APPS[@]} -gt 0 ]] && for p in "${FOUND_APPS[@]}"; do echo "  • App bundle: $p"; done
[[ ${#FOUND_AGENTS[@]} -gt 0 ]] && for p in "${FOUND_AGENTS[@]}"; do echo "  • LaunchAgent: $p"; done
[[ ${#FOUND_CACHES[@]} -gt 0 ]] && for p in "${FOUND_CACHES[@]}"; do echo "  • Cache: $p"; done
[[ ${#FOUND_PREFS[@]} -gt 0 ]] && for p in "${FOUND_PREFS[@]}"; do echo "  • Preferences: $p"; done
[[ ${#FOUND_SUPPORT[@]} -gt 0 ]] && for p in "${FOUND_SUPPORT[@]}"; do echo "  • Application Support: $p"; done
[[ ${#FOUND_KEYS[@]} -gt 0 ]] && for k in "${FOUND_KEYS[@]}"; do echo "  • Keychain key: $KEYCHAIN_SERVICE / $k"; done

echo ""
echo "⚠️  This will quit rNitro and permanently delete the items listed above."
echo "    Your AI chat history (UserDefaults) and saved API keys will be removed."
echo ""
read -r -p "Type 'uninstall' to confirm, or anything else to cancel: " CONFIRM
if [[ "$CONFIRM" != "uninstall" ]]; then
  echo "Cancelled — nothing was removed."
  exit 0
fi

echo ""
REMOVED=()
FAILED=()

safe_rm_path() {
  local target="$1"
  if [[ -L "$target" ]]; then
    FAILED+=("$target (symlink — skipped for safety)")
    return 1
  fi
  if [[ -d "$target" ]]; then
    rm -rf -- "$target" && REMOVED+=("$target") && return 0
  elif [[ -f "$target" ]]; then
    rm -f -- "$target" && REMOVED+=("$target") && return 0
  fi
  return 1
}

# ── Quit running instance ─────────────────────────────────────────────────────
if [[ -n "$RUNNING" ]]; then
  echo "⏹️  Quitting rNitro..."
  pkill -x rNitro 2>/dev/null || true
  for _ in 1 2 3 4 5; do
    pgrep -x rNitro >/dev/null 2>&1 || break
    sleep 0.4
  done
  if pgrep -x rNitro >/dev/null 2>&1; then
    pkill -9 -x rNitro 2>/dev/null || true
    sleep 0.3
  fi
  if pgrep -x rNitro >/dev/null 2>&1; then
    FAILED+=("rNitro process (still running)")
  else
    REMOVED+=("rNitro process")
  fi
fi

# ── Unregister Launch at Login ────────────────────────────────────────────────
if [[ "$HAS_LOGIN_ITEM" == true ]]; then
  echo "🔓 Removing Launch at Login registration..."
  if swift -e 'import ServiceManagement; if #available(macOS 13.0, *) { try? SMAppService.mainApp.unregister() }' 2>/dev/null; then
    REMOVED+=("Launch at Login (SMAppService)")
  else
    FAILED+=("Launch at Login (SMAppService)")
  fi
fi

# ── Remove app bundles ────────────────────────────────────────────────────────
if [[ ${#FOUND_APPS[@]} -gt 0 ]]; then
  for p in "${FOUND_APPS[@]}"; do
    echo "📦 Removing $p ..."
    safe_rm_path "$p" || FAILED+=("$p")
  done
fi

# ── Remove LaunchAgents ───────────────────────────────────────────────────────
if [[ ${#FOUND_AGENTS[@]} -gt 0 ]]; then
  for p in "${FOUND_AGENTS[@]}"; do
    echo "📋 Removing $p ..."
    safe_rm_path "$p" || FAILED+=("$p")
  done
fi

# ── Remove caches, prefs, support ─────────────────────────────────────────────
if [[ ${#FOUND_CACHES[@]} -gt 0 || ${#FOUND_PREFS[@]} -gt 0 || ${#FOUND_SUPPORT[@]} -gt 0 ]]; then
  for p in "${FOUND_CACHES[@]:-}" "${FOUND_PREFS[@]:-}" "${FOUND_SUPPORT[@]:-}"; do
    [[ -z "$p" ]] && continue
    echo "🧹 Removing $p ..."
    safe_rm_path "$p" || FAILED+=("$p")
  done
fi

# ── Remove Keychain API keys ────────────────────────────────────────────────────
if command -v security >/dev/null 2>&1 && [[ ${#FOUND_KEYS[@]} -gt 0 ]]; then
  for provider in "${FOUND_KEYS[@]}"; do
    echo "🔑 Removing Keychain entry: $KEYCHAIN_SERVICE / $provider ..."
    if security delete-generic-password -s "$KEYCHAIN_SERVICE" -a "$provider" >/dev/null 2>&1; then
      REMOVED+=("Keychain: $KEYCHAIN_SERVICE / $provider")
    else
      FAILED+=("Keychain: $KEYCHAIN_SERVICE / $provider")
    fi
  done
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────"
if [[ ${#REMOVED[@]} -gt 0 ]]; then
  echo "✅ Removed (${#REMOVED[@]}):"
  for item in "${REMOVED[@]}"; do
    echo "   • $item"
  done
fi
if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo ""
  echo "⚠️  Could not remove (${#FAILED[@]}):"
  for item in "${FAILED[@]}"; do
    echo "   • $item"
  done
  echo ""
  echo "You may need to quit rNitro manually and delete remaining files by hand."
  exit 1
fi

echo ""
echo "✅ rNitro has been fully uninstalled."
echo "   Reinstall anytime from https://rnitro.netlify.app/"