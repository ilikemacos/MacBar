#!/usr/bin/env python3
"""Generate the stable macOS installer from install-rNitro.sh (OpenAI + OpenRouter only)."""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import versions as v

STABLE_AIPROVIDER = """enum AIProvider: String, CaseIterable, Identifiable {
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
}"""

STABLE_PROBE_SWITCH = """            switch provider {
            case .openai:
                var req = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
                req.httpMethod = "GET"
                req.setValue("Bearer \\(apiKey)", forHTTPHeaderField: "Authorization")
                req.timeoutInterval = 8
                try await validateHTTP(req, domain: "OpenAI", accept: [200])
            case .openRouter:
                var req = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/models")!)
                req.httpMethod = "GET"
                req.setValue("Bearer \\(apiKey)", forHTTPHeaderField: "Authorization")
                req.timeoutInterval = 8
                try await validateHTTP(req, domain: "OpenRouter", accept: [200])
            }"""

STABLE_REQUEST_SWITCH = """        switch provider {
        case .openai: return try await requestOpenAI(apiKey: apiKey, messages: messages)
        case .openRouter: return try await requestOpenRouter(apiKey: apiKey, messages: messages)
        }"""


def main() -> None:
    data = v.load()
    beta = v.beta_release(data)
    stable = v.stable_release(data)

    src = v.SITE / beta["source_sh"]
    dst = v.SITE / stable["sh"]
    text = src.read_text(encoding="utf-8")

    beta_id = beta["id"]
    stable_id = stable["id"]

    text = re.sub(
        r"# v[\w.-]+ —.*\n(?:# .*\n)*",
        f"# {stable_id} — Stable release: CPU monitor + AI chat (OpenAI & OpenRouter only).\n",
        text,
        count=1,
    )

    ai_start = text.index("enum AIProvider: String, CaseIterable, Identifiable {")
    ai_end = text.index("enum AIConnectionState: String, Equatable {", ai_start)
    text = text[:ai_start] + STABLE_AIPROVIDER + "\n\n" + text[ai_end:]

    text = text.replace(
        "@Published var selectedProvider: AIProvider = .gemini",
        "@Published var selectedProvider: AIProvider = .openai",
    )

    text = re.sub(
        r"nonisolated private static func probe\(provider: AIProvider, apiKey: String\) async -> Result<Void, Error> \{\n        do \{\n            switch provider \{.*?\n            \}\n            return \.success\(\(\)\)",
        "nonisolated private static func probe(provider: AIProvider, apiKey: String) async -> Result<Void, Error> {\n        do {\n" + STABLE_PROBE_SWITCH + "\n            return .success(())",
        text,
        count=1,
        flags=re.DOTALL,
    )

    text = re.sub(
        r"nonisolated private static func request\(provider: AIProvider, apiKey: String, messages: \[ChatMessage\]\) async throws -> String \{\n        switch provider \{.*?\n        \}\n    \}",
        "nonisolated private static func request(provider: AIProvider, apiKey: String, messages: [ChatMessage]) async throws -> String {\n" + STABLE_REQUEST_SWITCH + "\n    }",
        text,
        count=1,
        flags=re.DOTALL,
    )

    beta_slug = beta_id.removeprefix("v")
    stable_slug = stable_id.removeprefix("v")
    text = text.replace(beta_slug, stable_slug)
    text = text.replace(f'let CURRENT_VERSION = "{beta_id}"', f'let CURRENT_VERSION = "{stable_id}"')

    dst.write_text(text, encoding="utf-8")
    print(f"Wrote {dst}")


if __name__ == "__main__":
    main()