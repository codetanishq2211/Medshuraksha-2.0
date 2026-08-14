import base64
import os
import requests

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY") or os.getenv("OPENAI_API_KEY", "")
GEMINI_API_URL = os.getenv("GEMINI_API_URL", "https://api.openai.com/v1/responses")
GEMINI_CHAT_MODEL = os.getenv("GEMINI_CHAT_MODEL", "gpt-4.1-mini")
GEMINI_VISION_MODEL = os.getenv("GEMINI_VISION_MODEL", "gpt-4.1-mini")


def _get_api_headers() -> dict[str, str]:
    return {
        "Authorization": f"Bearer {GEMINI_API_KEY}",
        "Content-Type": "application/json",
    }


def _extract_text_from_response(data: dict) -> str:
    # OpenAI Responses API may return a mix of output objects.
    if data is None:
        return ""

    texts: list[str] = []

    # Legacy choice-based responses
    if "choices" in data:
        for choice in data.get("choices", []):
            message = choice.get("message") or {}
            content = message.get("content")
            if isinstance(content, str):
                texts.append(content)
            elif isinstance(content, dict):
                texts.extend(_extract_text_from_response({"output": [content]}).splitlines())

    # New Responses output format
    for output_obj in data.get("output", []):
        content = output_obj.get("content")
        if isinstance(content, list):
            for item in content:
                if item.get("type") == "output_text":
                    texts.append(item.get("text", ""))
                elif item.get("type") == "message":
                    nested = item.get("content")
                    if isinstance(nested, list):
                        for nested_item in nested:
                            if nested_item.get("type") == "output_text":
                                texts.append(nested_item.get("text", ""))
        elif isinstance(content, str):
            texts.append(content)

    return "\n".join([t.strip() for t in texts if t and t.strip()]).strip()


def _call_gemini(payload: dict) -> str:
    if not GEMINI_API_KEY:
        raise RuntimeError("Gemini API key is not configured. Set GEMINI_API_KEY or OPENAI_API_KEY.")

    response = requests.post(
        GEMINI_API_URL,
        headers=_get_api_headers(),
        json=payload,
        timeout=60,
    )
    response.raise_for_status()
    data = response.json()
    return _extract_text_from_response(data)


def ask_gemini(prompt: str) -> str:
    payload = {
        "model": GEMINI_CHAT_MODEL,
        "temperature": 0.3,
        "input": [
            {
                "role": "user",
                "content": [
                    {"type": "input_text", "text": prompt},
                ],
            }
        ],
    }
    return _call_gemini(payload)


def vision_ocr(image_bytes: bytes) -> str:
    encoded = base64.b64encode(image_bytes).decode("ascii")
    data_url = f"data:image/jpeg;base64,{encoded}"

    payload = {
        "model": GEMINI_VISION_MODEL,
        "temperature": 0.0,
        "input": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": "Extract all visible text from the image below. Return only the extracted text without explanation.",
                    },
                    {
                        "type": "input_image",
                        "image_url": data_url,
                    },
                ],
            }
        ],
    }
    return _call_gemini(payload)
