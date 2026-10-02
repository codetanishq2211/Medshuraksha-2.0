import os

from fastapi import FastAPI, HTTPException
from sqlalchemy import inspect, text

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


@app.get("/health/database")
def database_health():
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
            users_table_exists = inspect(connection).has_table("users")

        host = engine.url.host or ""
        provider = "neon" if host.endswith(".neon.tech") else engine.dialect.name
        return {
            "status": "ok",
            "provider": provider,
            "database_host": host or None,
            "database_name": engine.url.database,
            "database_url_configured": bool(os.getenv("DATABASE_URL")),
            "users_table_exists": users_table_exists,
        }
    except Exception as exc:
        raise HTTPException(status_code=503, detail="Database connection failed") from exc