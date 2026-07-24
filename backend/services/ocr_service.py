import io
import re
import numpy as np
from PIL import Image
import easyocr

# Loaded once and reused - building the reader is the slow part (loads the
# recognition model), so we don't want to do it on every request.
_reader = None


def _get_reader():
    global _reader
    if _reader is None:
        _reader = easyocr.Reader(["en"], gpu=False)
    return _reader


def extract_text_from_image(image_bytes: bytes) -> str:
    """Run OCR on raw image bytes and return the raw extracted text."""
    image = Image.open(io.BytesIO(image_bytes))
    if image.mode != "RGB":
        image = image.convert("RGB")
    image_np = np.array(image)

    reader = _get_reader()
    lines = reader.readtext(image_np, detail=0)
    return "\n".join(lines).strip()


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