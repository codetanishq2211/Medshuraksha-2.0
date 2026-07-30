from fastapi import APIRouter
from pydantic import BaseModel

from services.ai_service import ask_ai

router = APIRouter(
    prefix="/ai",
    tags=["AI"]
)


class ChatRequest(BaseModel):
    question: str


@router.post("/chat")
def chat(data: ChatRequest):
    answer = ask_ai(data.question)
    return {"answer": answer}