from __future__ import annotations

import json
import os
import threading
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Callable

PROVIDERS = [
    "gemini",
    "openai",
    "anthropic",
    "grok",
    "deepseek",
    "openrouter",
    "ollama",
]

PROVIDER_LABELS = {
    "gemini": "Gemini",
    "openai": "OpenAI",
    "anthropic": "Anthropic",
    "grok": "Grok (xAI)",
    "deepseek": "DeepSeek",
    "openrouter": "OpenRouter",
    "ollama": "Ollama (local)",
}

DEFAULT_MODELS = {
    "openai": "gpt-4o-mini",
    "openrouter": "openai/gpt-4o-mini",
    "deepseek": "deepseek-chat",
    "grok": "grok-2-latest",
    "anthropic": "claude-3-5-sonnet-20241022",
    "gemini": "gemini-1.5-flash",
    "ollama": "llama3.2",
}

ENV_KEYS = {
    "openai": "OPENAI_API_KEY",
    "openrouter": "OPENROUTER_API_KEY",
    "gemini": "GEMINI_API_KEY",
    "anthropic": "ANTHROPIC_API_KEY",
    "grok": "XAI_API_KEY",
    "deepseek": "DEEPSEEK_API_KEY",
}

SYSTEM_PROMPT = (
    "You are rNitro, a concise Linux system assistant. "
    "Help with CPU, memory, disk, temperatures, and general desktop troubleshooting. "
    "Keep answers short and actionable."
)


@dataclass
class ChatMessage:
    role: str
    content: str


def resolve_api_key(provider: str, cfg: dict | None = None) -> str | None:
    env = ENV_KEYS.get(provider)
    if env:
        val = os.environ.get(env, "").strip()
        if val:
            return val
    if cfg:
        keys = cfg.get("api_keys") or {}
        val = str(keys.get(provider, "")).strip()
        if val:
            return val
    return None


def complete(provider: str, model: str, messages: list[ChatMessage], cfg: dict | None = None) -> str:
    if provider == "ollama":
        return _ollama(model or DEFAULT_MODELS["ollama"], messages)
    key = resolve_api_key(provider, cfg)
    if not key:
        env_name = ENV_KEYS.get(provider, "API key")
        return f"Set {env_name} in Settings or environment for {PROVIDER_LABELS.get(provider, provider)}."
    model = model or DEFAULT_MODELS.get(provider, "")
    if provider == "openai":
        return _openai_compat("https://api.openai.com/v1/chat/completions", key, model, messages)
    if provider == "openrouter":
        return _openai_compat("https://openrouter.ai/api/v1/chat/completions", key, model, messages, extra={"HTTP-Referer": "https://getrnitro.netlify.app", "X-Title": "rNitro Linux"})
    if provider == "deepseek":
        return _openai_compat("https://api.deepseek.com/chat/completions", key, model, messages)
    if provider == "grok":
        return _openai_compat("https://api.x.ai/v1/chat/completions", key, model, messages)
    if provider == "anthropic":
        return _anthropic(key, model, messages)
    if provider == "gemini":
        return _gemini(key, model, messages)
    return "Unknown provider"


def complete_async(
    provider: str,
    model: str,
    messages: list[ChatMessage],
    cfg: dict | None,
    on_done: Callable[[str], None],
    on_error: Callable[[str], None] | None = None,
) -> None:
    def work() -> None:
        try:
            reply = complete(provider, model, messages, cfg)
            on_done(reply)
        except Exception as exc:
            msg = f"Error: {exc}"
            if on_error:
                on_error(msg)
            else:
                on_done(msg)

    threading.Thread(target=work, daemon=True, name="rnitro-chat").start()


def _post_json(url: str, headers: dict, payload: dict) -> dict:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {body[:300]}") from exc


def _chat_messages(messages: list[ChatMessage]) -> list[dict]:
    out = [{"role": "system", "content": SYSTEM_PROMPT}]
    for m in messages:
        if m.role in ("user", "assistant"):
            out.append({"role": m.role, "content": m.content})
    return out


def _openai_compat(
    url: str,
    key: str,
    model: str,
    messages: list[ChatMessage],
    extra: dict | None = None,
) -> str:
    headers = {"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
    if extra:
        headers.update(extra)
    body = {"model": model, "messages": _chat_messages(messages)}
    data = _post_json(url, headers, body)
    return data["choices"][0]["message"]["content"]


def _anthropic(key: str, model: str, messages: list[ChatMessage]) -> str:
    msgs = [{"role": m.role, "content": m.content} for m in messages if m.role in ("user", "assistant")]
    body = {"model": model, "max_tokens": 1024, "system": SYSTEM_PROMPT, "messages": msgs}
    data = _post_json(
        "https://api.anthropic.com/v1/messages",
        {"x-api-key": key, "anthropic-version": "2023-06-01", "Content-Type": "application/json"},
        body,
    )
    return data["content"][0]["text"]


def _gemini(key: str, model: str, messages: list[ChatMessage]) -> str:
    contents = []
    for m in messages:
        if m.role == "user":
            contents.append({"role": "user", "parts": [{"text": m.content}]})
        elif m.role == "assistant":
            contents.append({"role": "model", "parts": [{"text": m.content}]})
    if not contents:
        return "No user message."
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
    body = {"systemInstruction": {"parts": [{"text": SYSTEM_PROMPT}]}, "contents": contents}
    data = _post_json(url, {"Content-Type": "application/json"}, body)
    return data["candidates"][0]["content"]["parts"][0]["text"]


def _ollama(model: str, messages: list[ChatMessage]) -> str:
    body = {
        "model": model,
        "messages": _chat_messages(messages),
        "stream": False,
    }
    data = _post_json("http://127.0.0.1:11434/api/chat", {"Content-Type": "application/json"}, body)
    return data["message"]["content"]