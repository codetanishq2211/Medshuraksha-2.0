from fastapi import APIRouter
from pydantic import BaseModel

from services.ollama_service import ask_ollama

router = APIRouter(
    prefix="/ai",
    tags=["AI"]
)


class ChatRequest(BaseModel):
    question: str


@router.post("/chat")
def chat(data: ChatRequest):
    answer = ask_ollama(data.question)
    return {"answer": answer}