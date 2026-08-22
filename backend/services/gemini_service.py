import base64
import os
import time
import requests

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_CHAT_MODEL = os.getenv("GEMINI_CHAT_MODEL", "gemini-flash-latest")
GEMINI_VISION_MODEL = os.getenv("GEMINI_VISION_MODEL", "gemini-flash-latest")
GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"


def _call_gemini(model: str, parts: list[dict], max_retries: int = 3) -> str:
    if not GEMINI_API_KEY:
        raise RuntimeError("Gemini API key is not configured. Set GEMINI_API_KEY.")

    url = f"{GEMINI_BASE_URL}/{model}:generateContent?key={GEMINI_API_KEY}"
    payload = {"contents": [{"parts": parts}]}

    last_error: Exception | None = None
    for attempt in range(max_retries):
        try:
            response = requests.post(url, json=payload, timeout=60)
            # Retry on transient server-side errors, not on client errors
            # like bad request or invalid key - retrying those just wastes time.
            if response.status_code in (429, 500, 502, 503, 504):
                last_error = requests.exceptions.HTTPError(
                    f"{response.status_code} Server Error: {response.reason}",
                    response=response,
                )
                if attempt < max_retries - 1:
                    time.sleep(2 ** attempt)  # 1s, 2s, 4s
                    continue
                raise last_error

            response.raise_for_status()
            data = response.json()
            try:
                return data["candidates"][0]["content"]["parts"][0]["text"].strip()
            except (KeyError, IndexError, TypeError):
                return ""
        except requests.exceptions.Timeout as e:
            last_error = e
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)
                continue
            raise

    if last_error:
        raise last_error
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