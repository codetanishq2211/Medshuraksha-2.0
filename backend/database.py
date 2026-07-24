import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# Falls back to your local Postgres if DATABASE_URL isn't set.
# For Neon (or any cloud Postgres), set the env var instead of editing this file:
#   $env:DATABASE_URL = "postgresql://user:password@ep-xxxx.neon.tech/dbname?sslmode=require"
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:Tanishqkumarreal@localhost:5432/medshuraksha",
)

engine = create_engine(DATABASE_URL, connect_args={"connect_timeout": 10})

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