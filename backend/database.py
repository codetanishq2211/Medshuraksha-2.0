import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# Default to a local SQLite database so the app can share data from a laptop
# without requiring a separate Postgres install. For a cloud/Postgres setup,
# set DATABASE_URL before starting the app.
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./medshuraksha.db",
)

connect_args = {}
if DATABASE_URL.startswith("sqlite"):
    connect_args["check_same_thread"] = False
else:
    connect_args["connect_timeout"] = 10

engine = create_engine(DATABASE_URL, connect_args=connect_args)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()