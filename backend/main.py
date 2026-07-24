from fastapi import FastAPI

from routes.search import router as search_router
from routes.scan import router as scan_router
from routes.ai import router as ai_router

app = FastAPI(
    title="MedSuraksha API",
    version="2.0"
)

app.include_router(search_router)
app.include_router(scan_router)
app.include_router(ai_router)


@app.get("/")
def home():
    return {
        "message": "MedSuraksha Backend Running Successfully 🚀"
    }