import re

from services.gemini_service import vision_ocr


def extract_text_from_image(image_bytes: bytes) -> str:
    """Send the image to Gemini Vision for OCR and return extracted text."""
    try:
        return vision_ocr(image_bytes)
    except Exception as e:
        raise RuntimeError(f"Gemini OCR failed: {e}")


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