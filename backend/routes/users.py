from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from models import User
from passlib.context import CryptContext

router = APIRouter(
    prefix="/users",
    tags=["Users"],
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class UserCreate(BaseModel):
    name: str
    username: str | None = None
    password: str | None = None


class UserLogin(BaseModel):
    username: str
    password: str


@router.get("")
def get_users(db: Session = Depends(get_db)):
    users = db.query(User).order_by(User.id.asc()).all()
    return [
        {
            "id": user.id,
            "name": user.name,
            "username": user.username,
            "created_at": user.created_at,
        }
        for user in users
    ]


@router.post("/register")
def register_user(data: UserCreate, db: Session = Depends(get_db)):
    name = data.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Name is required")

    username = data.username.strip() if data.username else None
    if username:
        existing_user = db.query(User).filter(User.username == username).first()
        if existing_user:
            raise HTTPException(status_code=400, detail="Username already taken")

    user = User(
        name=name,
        username=username,
        password_hash=pwd_context.hash(data.password) if data.password else None,
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return {
        "id": user.id,
        "name": user.name,
        "username": user.username,
    }


@router.post("/login")
def login_user(data: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == data.username).first()
    if not user or not user.password_hash:
        raise HTTPException(status_code=401, detail="Invalid username or password")

    if not pwd_context.verify(data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid username or password")

    return {
        "id": user.id,
        "name": user.name,
        "username": user.username,
    }
