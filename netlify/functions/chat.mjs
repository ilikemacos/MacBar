/** rNitro website support chat — Netlify serverless proxy (keeps API keys off the client). */

const SITE_URL = "https://getrnitro.netlify.app";

async function fetchSiteJson(path) {
  try {
    const res = await fetch(`${SITE_URL}${path}`, {
      headers: { Accept: "application/json" },
    });
    if (res.ok) return await res.json();
  } catch (_) {
    /* offline / local dev */
  }
  return null;
}

function idFromSh(sh) {
  if (!sh) return null;
  return sh.replace(/^rNitro-/, "").replace(/\.sh$/, "");
}

function mergeVersions(bodyVersions, remote) {
  const stableRel = remote?.releases?.stable;
  const betaRel = remote?.releases?.beta;
  const winRel = remote?.releases?.windows;
  return {
    stable: {
      id:
        remote?.latest ||
        bodyVersions?.stable?.id ||
        idFromSh(stableRel?.sh) ||
        "v8.2.6-Final-arm64",
      sh: stableRel?.sh || bodyVersions?.stable?.sh || "rNitro-v8.2.6-Final-arm64.sh",
      zip: stableRel?.zip || bodyVersions?.stable?.zip,
      label: stableRel?.label || bodyVersions?.stable?.label,
    },
    beta: {
      id:
        remote?.beta ||
        bodyVersions?.beta?.id ||
        idFromSh(betaRel?.sh) ||
        "v8.2.8-Beta-arm64",
      sh: betaRel?.sh || bodyVersions?.beta?.sh || "rNitro-v8.2.8-Beta-arm64.sh",
      zip: betaRel?.zip || bodyVersions?.beta?.zip,
      label: betaRel?.label || bodyVersions?.beta?.label,
    },
    windows: {
      id: remote?.windows || bodyVersions?.windows?.id || "v4.2.2-Windows-Final-x86",
      exe: winRel?.exe || bodyVersions?.windows?.exe,
    },
  };
}

function changelogHighlights(changelog) {
  if (!changelog?.whats_new?.length) return "";
  return changelog.whats_new
    .map((card) => {
      const items = (card.items || [])
        .map((it) => (typeof it === "object" ? `${it.strong || ""}${it.text || ""}` : String(it)))
        .join("; ");
      return `${card.title}: ${items}`;
    })
    .join("\n");
}

function buildSystemPrompt(versions, changelog) {
  const stable = versions?.stable?.id || "v8.2.6-Final-arm64";
  const beta = versions?.beta?.id || "v8.2.8-Beta-arm64";
  const win = versions?.windows?.id || "v4.2.2-Windows-Final-x86";
  const highlights = changelogHighlights(changelog);
  const highlightsBlock = highlights
    ? `\nRECENT HIGHLIGHTS (from changelog.json)\n${highlights}\n`
    : "";
  return `You are the official rNitro support assistant on ${SITE_URL}. Answer ONLY about rNitro (macOS/Windows CPU monitor app, downloads, install, features, troubleshooting). Be concise, friendly, and accurate. Use short paragraphs or bullet lists. If unsure, say so and suggest the Support email form on the page.

CURRENT RELEASES
- Stable macOS: ${stable} — CPU monitor, benchmark, stress test, AI chat (OpenAI GPT + OpenRouter only), System Advisor.
- Beta macOS: ${beta} — stable features + all AI providers (Gemini, OpenAI, Anthropic, Groq, DeepSeek, OpenRouter, LM Studio, Ollama, Hermes), Varela Round UI font, critical temp notification banners, System Advisor.
- Windows: ${win} — tray monitor (.exe needs .NET 8 Desktop Runtime; .ps1 compiles with built-in csc.exe).
${highlightsBlock}
INSTALL (macOS)
- Recommended: App ZIP (1.8 MB) — unzip, drag rNitro.app to Applications, right-click → Open once if Gatekeeper blocks.
- PKG/DMG: fastest; macOS may warn "can't verify" — click Done, then System Settings → Privacy & Security → Open.
- .sh installer: compiles from readable source on the user's Mac (~30s). Stable .sh: ${versions?.stable?.sh || "rNitro-v8.2.6-Final-arm64.sh"} — Beta .sh: ${versions?.beta?.sh || "rNitro-v8.2.8-Beta-arm64.sh"}
- Site: ${SITE_URL}
- GitHub Releases (same App ZIPs): https://github.com/ilikemacos/rNitro/releases
  - Stable: https://github.com/ilikemacos/rNitro/releases/latest/download/${versions?.stable?.zip || "rNitro-v8.2.6-Final-arm64.zip"}
  - Beta: https://github.com/ilikemacos/rNitro/releases/download/${(versions?.beta?.id || "v8.2.8-Beta-arm64").replace(/-arm64$/, "")}/${versions?.beta?.zip || "rNitro-v8.2.8-Beta-arm64.zip"}
- Requires Apple Silicon (arm64), macOS 12+. Not Intel Macs.

INSTALL (Windows)
- Download EXE or .ps1 from the Windows tab. EXE needs .NET 8 Desktop Runtime x64.

FEATURES
- Menu bar CPU/temp monitor, popover with per-core stats, benchmark, stress test.
- Beta: System Advisor tab — client-side specs assistant, customizable temp/CPU/RAM/GPU/battery warn/critical thresholds, no API key.
- Beta: AI Chat tab — user brings own API keys (Keychain); local LM Studio/Ollama/Hermes need no cloud key.
- Beta: First-launch tips sheet — welcome dialog on first open (menubar icon, Gatekeeper, App ZIP install).
- Beta: AES-256-GCM — API keys and AI chat history encrypted at rest (CryptoKit; master key in Keychain).
- Temperature: reads SMC when possible (like iStat Menus); falls back to macOS thermal state.
- BTC price in menu bar from CoinGecko (no key).
- Updates: app checks ${SITE_URL}/version.json on launch.

SECURITY / TRUST
- .sh/.ps1 contain full source; SHA-256 verified before run. No telemetry. Free, no subscription.
- App ZIP downloads are ad-hoc signed. Quarantine: xattr -cr on the .app if needed.

UNINSTALL
- macOS: quit, delete rNitro.app from Applications.
- Windows: tray → Exit, delete from %LOCALAPPDATA%\\rNitro.

Do not invent features, version numbers, or URLs. Do not help with unrelated topics.`;
}

async function callGroq(messages, apiKey) {
  const model = process.env.GROQ_MODEL || "llama-3.1-8b-instant";
  const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      messages,
      max_tokens: 600,
      temperature: 0.25,
    }),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Groq ${res.status}: ${err.slice(0, 200)}`);
  }
  const data = await res.json();
  return data.choices?.[0]?.message?.content?.trim() || "";
}

async function callOpenRouter(messages, apiKey) {
  const model = process.env.OPENROUTER_MODEL || "meta-llama/llama-3.1-8b-instruct:free";
  const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "HTTP-Referer": SITE_URL,
      "X-Title": "rNitro Support Chat",
    },
    body: JSON.stringify({
      model,
      messages,
      max_tokens: 600,
      temperature: 0.25,
    }),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`OpenRouter ${res.status}: ${err.slice(0, 200)}`);
  }
  const data = await res.json();
  return data.choices?.[0]?.message?.content?.trim() || "";
}

async function callGemini(messages, apiKey) {
  const model = process.env.GEMINI_MODEL || "gemini-2.0-flash";
  const system = messages.find((m) => m.role === "system")?.content || "";
  const contents = messages
    .filter((m) => m.role !== "system")
    .map((m) => ({
      role: m.role === "assistant" ? "model" : "user",
      parts: [{ text: m.content }],
    }));
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      systemInstruction: system ? { parts: [{ text: system }] } : undefined,
      contents,
      generationConfig: { maxOutputTokens: 600, temperature: 0.25 },
    }),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Gemini ${res.status}: ${err.slice(0, 200)}`);
  }
  const data = await res.json();
  return data.candidates?.[0]?.content?.parts?.map((p) => p.text).join("")?.trim() || "";
}

function pickClientKey(body) {
  const key = String(body.apiKey || "").trim();
  const provider = String(body.provider || "groq").toLowerCase();
  if (!key || key.length < 20 || key.length > 256) return null;
  if (provider === "groq" && !key.startsWith("gsk_")) return null;
  if (provider === "openrouter" && !key.startsWith("sk-or-")) return null;
  if (provider === "gemini" && !key.startsWith("AIza")) return null;
  if (!["groq", "openrouter", "gemini"].includes(provider)) return null;
  return { apiKey: key, provider };
}

async function complete(messages, client) {
  const groq = process.env.GROQ_API_KEY;
  if (groq) return { text: await callGroq(messages, groq), provider: "groq" };
  const orKey = process.env.OPENROUTER_API_KEY;
  if (orKey) return { text: await callOpenRouter(messages, orKey), provider: "openrouter" };
  const gemini = process.env.GEMINI_API_KEY;
  if (gemini) return { text: await callGemini(messages, gemini), provider: "gemini" };

  if (client) {
    if (client.provider === "groq") return { text: await callGroq(messages, client.apiKey), provider: "groq" };
    if (client.provider === "openrouter") return { text: await callOpenRouter(messages, client.apiKey), provider: "openrouter" };
    if (client.provider === "gemini") return { text: await callGemini(messages, client.apiKey), provider: "gemini" };
  }
  return null;
}

function apiConfigured() {
  return !!(process.env.GROQ_API_KEY || process.env.OPENROUTER_API_KEY || process.env.GEMINI_API_KEY);
}

export async function handler(event) {
  if (event.httpMethod === "GET") {
    const configured = apiConfigured();
    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ ok: true, configured, ai: configured, byok: !configured }),
    };
  }

  if (event.httpMethod === "OPTIONS") {
    return {
      statusCode: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
      },
      body: "",
    };
  }

  if (event.httpMethod !== "POST") {
    return { statusCode: 405, body: JSON.stringify({ error: "Method not allowed" }) };
  }

  let body;
  try {
    body = JSON.parse(event.body || "{}");
  } catch {
    return { statusCode: 400, body: JSON.stringify({ error: "Invalid JSON" }) };
  }

  const message = String(body.message || "").trim().slice(0, 2000);
  if (!message) {
    return { statusCode: 400, body: JSON.stringify({ error: "message required" }) };
  }

  const history = Array.isArray(body.history) ? body.history.slice(-10) : [];
  const [remoteVersions, changelog] = await Promise.all([
    fetchSiteJson("/version.json"),
    fetchSiteJson("/changelog.json"),
  ]);
  const versions = mergeVersions(body.versions || {}, remoteVersions);
  const system = buildSystemPrompt(versions, changelog);

  const messages = [
    { role: "system", content: system },
    ...history
      .filter((m) => m && (m.role === "user" || m.role === "assistant") && m.content)
      .map((m) => ({
        role: m.role,
        content: String(m.content).slice(0, 4000),
      })),
    { role: "user", content: message },
  ];

  const clientKey = apiConfigured() ? null : pickClientKey(body);

  try {
    const result = await complete(messages, clientKey);
    if (!result) {
      return {
        statusCode: 503,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          error: "no_api_key",
          byok: true,
          reply:
            "AI needs an API key. Tap the key icon in the chat header and paste a Groq, OpenRouter, or Gemini key (stored in this browser only). Or use a quick-pick question below.",
        }),
      };
    }
    if (!result.text) {
      return {
        statusCode: 502,
        body: JSON.stringify({ error: "empty_response" }),
      };
    }
    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ reply: result.text, provider: result.provider, ai: true }),
    };
  } catch (err) {
    console.error("chat error:", err);
    return {
      statusCode: 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        error: "ai_failed",
        reply:
          "Sorry — the AI backend hit an error. Try a suggested question below, or email via the Support section.",
      }),
    };
  }
}