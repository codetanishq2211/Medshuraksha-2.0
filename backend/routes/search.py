from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db
from services.medicine_service import search_local

router = APIRouter()


@router.get("/search")
def search(q: str, db: Session = Depends(get_db)):
    return search_local(db, q)