import base64
import os
import requests

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_CHAT_MODEL = os.getenv("GEMINI_CHAT_MODEL", "gemini-flash-latest")
GEMINI_VISION_MODEL = os.getenv("GEMINI_VISION_MODEL", "gemini-flash-latest")
GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"


def _call_gemini(model: str, parts: list[dict]) -> str:
    if not GEMINI_API_KEY:
        raise RuntimeError("Gemini API key is not configured. Set GEMINI_API_KEY.")

    url = f"{GEMINI_BASE_URL}/{model}:generateContent?key={GEMINI_API_KEY}"
    payload = {"contents": [{"parts": parts}]}

    response = requests.post(url, json=payload, timeout=60)
    response.raise_for_status()
    data = response.json()

    try:
        return data["candidates"][0]["content"]["parts"][0]["text"].strip()
    except (KeyError, IndexError, TypeError):
        return ""


def ask_gemini(prompt: str) -> str:
    return _call_gemini(GEMINI_CHAT_MODEL, [{"text": prompt}])


def vision_ocr(image_bytes: bytes) -> str:
    encoded = base64.b64encode(image_bytes).decode("ascii")

    parts = [
        {"inline_data": {"mime_type": "image/jpeg", "data": encoded}},
        {"text": "Extract all visible text from the image below. Return only the extracted text without explanation."},
    ]
    return _call_gemini(GEMINI_VISION_MODEL, parts)