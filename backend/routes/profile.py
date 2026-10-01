from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from models import Profile

router = APIRouter(
    prefix="/profile",
    tags=["Profile"],
)


class ProfilePayload(BaseModel):
    firebase_uid: str
    phone_number: str | None = None
    name: str | None = None
    date_of_birth: str | None = None


@router.post("")
def save_profile(data: ProfilePayload, db: Session = Depends(get_db)):
    profile = db.query(Profile).filter(Profile.firebase_uid == data.firebase_uid).first()

    if profile is None:
        profile = Profile(
            firebase_uid=data.firebase_uid,
            phone_number=data.phone_number,
            name=data.name,
            date_of_birth=data.date_of_birth,
        )
        db.add(profile)
    else:
        if data.phone_number is not None:
            profile.phone_number = data.phone_number
        if data.name is not None:
            profile.name = data.name
        if data.date_of_birth is not None:
            profile.date_of_birth = data.date_of_birth

    db.commit()
    db.refresh(profile)

    return {
        "id": profile.id,
        "firebase_uid": profile.firebase_uid,
        "phone_number": profile.phone_number,
        "name": profile.name,
        "date_of_birth": profile.date_of_birth,
    }


@router.get("/{firebase_uid}")
def get_profile(firebase_uid: str, db: Session = Depends(get_db)):
    profile = db.query(Profile).filter(Profile.firebase_uid == firebase_uid).first()
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")

    return {
        "id": profile.id,
        "firebase_uid": profile.firebase_uid,
        "phone_number": profile.phone_number,
        "name": profile.name,
        "date_of_birth": profile.date_of_birth,
    }
