from fastapi import APIRouter, UploadFile, File, Depends
from sqlalchemy.orm import Session

from database import get_db
from services.ocr_service import extract_text_from_image, guess_medicine_name
from services.medicine_service import search_local
from services.ai_service import ask_ai

router = APIRouter(
    prefix="/scan",
    tags=["Scanner"]
)


@router.post("/image")
async def scan_image(file: UploadFile = File(...), db: Session = Depends(get_db)):
    image_bytes = await file.read()

    ocr_text = extract_text_from_image(image_bytes)
    guessed_name = guess_medicine_name(ocr_text)

    if not guessed_name:
        return {
            "source": "none",
            "ocr_text": ocr_text,
            "guessed_name": guessed_name,
            "matches": [],
            "ai_answer": None,
        }

    matches = search_local(db, guessed_name)

    if matches:
        return {
            "source": "database",
            "ocr_text": ocr_text,
            "guessed_name": guessed_name,
            "matches": matches,
            "ai_answer": None,
        }

    prompt = (
        "You are a medical information assistant. A user scanned a medicine "
        f"packet and the detected name is: '{guessed_name}'. "
        "Give a short, clear summary covering: what it is likely used for, "
        "common side effects, and who should avoid it. "
        "If you are not confident this is a real medicine, say so plainly "
        "instead of guessing."
    )
    ai_answer = ask_ai(prompt)
    return {
        "source": "ai",
        "ocr_text": ocr_text,
        "guessed_name": guessed_name,
        "matches": [],
        "ai_answer": ai_answer,
    }