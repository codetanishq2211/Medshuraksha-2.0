import os
import re
import requests

# Get a free key at https://ocr.space/ocrapi/freekey (no card required)
# "helloworld" is OCR.space's public demo key - works but has a low rate
# limit, so replace it with your own for real use.
OCR_SPACE_API_KEY = os.getenv("OCR_SPACE_API_KEY", "helloworld")
OCR_SPACE_URL = "https://api.ocr.space/parse/image"


def extract_text_from_image(image_bytes: bytes) -> str:
    """Send the image to OCR.space's hosted OCR API and return extracted text."""
    try:
        response = requests.post(
            OCR_SPACE_URL,
            files={"file": ("image.jpg", image_bytes)},
            data={
                "apikey": OCR_SPACE_API_KEY,
                "language": "eng",
                "OCREngine": 2,
            },
            timeout=30,
        )
        response.raise_for_status()
        result = response.json()

        if result.get("IsErroredOnProcessing"):
            error_msg = result.get("ErrorMessage", ["Unknown OCR error"])
            raise RuntimeError(f"OCR.space error: {error_msg}")

        parsed_results = result.get("ParsedResults") or []
        if not parsed_results:
            return ""

        return parsed_results[0].get("ParsedText", "").strip()
    except requests.RequestException as e:
        raise RuntimeError(f"OCR request failed: {e}")


def guess_medicine_name(ocr_text: str) -> str:
    """
    Medicine packaging usually prints the brand name largest and near the top.
    Take the first line that's mostly letters as the best guess.
    """
    lines = [line.strip() for line in ocr_text.splitlines() if line.strip()]
    if not lines:
        return ""

    candidates = []
    for line in lines:
        letters_only = re.sub(r"[^A-Za-z ]", "", line).strip()
        if len(letters_only) >= 3:
            candidates.append(letters_only)

    if not candidates:
        return lines[0]

    return candidates[0]