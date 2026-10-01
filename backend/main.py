from fastapi import FastAPI

from database import Base, engine
from routes.search import router as search_router
from routes.ai import router as ai_router
from routes.scan import router as scan_router
from routes.users import router as users_router
from routes.profile import router as profile_router

app = FastAPI(
    title="MedSuraksha API",
    version="2.0"
)

Base.metadata.create_all(bind=engine)

app.include_router(search_router)
app.include_router(ai_router)
app.include_router(scan_router)
app.include_router(users_router)
app.include_router(profile_router)


@app.get("/")
def home():
    return {
        "message": "MedSuraksha Backend Running Successfully 🚀"
    }