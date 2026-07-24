from fastapi import APIRouter, UploadFile, File, Depends
from sqlalchemy.orm import Session

from database import get_db
from services.ocr_service import extract_text_from_image, guess_medicine_name
from services.medicine_service import search_local
from services.ollama_service import ask_ollama

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

    ai_answer = ask_ollama(guessed_name)
    return {
        "source": "ai",
        "ocr_text": ocr_text,
        "guessed_name": guessed_name,
        "matches": [],
        "ai_answer": ai_answer,
    }