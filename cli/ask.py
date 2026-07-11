"""Optional AI ask — uses OPENAI_API_KEY or GEMINI_API_KEY from the environment."""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.request


def _post_json(url: str, payload: dict, headers: dict[str, str], timeout: float = 60.0) -> dict:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def ask_with_context(question: str, snapshot: dict) -> str:
    question = question.strip()
    if not question:
        return "Provide a question, e.g. rnitro ask \"Why is CPU high?\""

    context = json.dumps(snapshot, indent=2)
    prompt = (
        "You are rNitro CLI, a concise macOS/Linux system assistant. "
        "Use the live metrics JSON below. Answer in plain language with bullet tips when helpful.\n\n"
        f"Metrics:\n{context}\n\nQuestion: {question}"
    )

    openai_key = os.environ.get("OPENAI_API_KEY", "").strip()
    if openai_key:
        try:
            body = _post_json(
                "https://api.openai.com/v1/chat/completions",
                {
                    "model": "gpt-4o-mini",
                    "messages": [{"role": "user", "content": prompt}],
                    "max_tokens": 600,
                },
                {
                    "Authorization": f"Bearer {openai_key}",
                    "Content-Type": "application/json",
                },
            )
            return body["choices"][0]["message"]["content"].strip()
        except (urllib.error.URLError, KeyError, IndexError, json.JSONDecodeError) as exc:
            return f"OpenAI error: {exc}"

    gemini_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if gemini_key:
        try:
            url = (
                "https://generativelanguage.googleapis.com/v1beta/models/"
                f"gemini-2.0-flash:generateContent?key={gemini_key}"
            )
            body = _post_json(
                url,
                {"contents": [{"parts": [{"text": prompt}]}]},
                {"Content-Type": "application/json"},
            )
            parts = body["candidates"][0]["content"]["parts"]
            return parts[0]["text"].strip()
        except (urllib.error.URLError, KeyError, IndexError, json.JSONDecodeError) as exc:
            return f"Gemini error: {exc}"

    return (
        "Set OPENAI_API_KEY or GEMINI_API_KEY in your environment, "
        "or configure keys in the Refresh app's Chat → API tab."
    )