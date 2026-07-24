import os
import json
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database import Base
from models import Medicine

# Set this before running, e.g. in PowerShell:
#   $env:NEON_DATABASE_URL = "postgresql://user:password@ep-xxxx.neon.tech/dbname?sslmode=require"
NEON_DATABASE_URL = os.getenv("NEON_DATABASE_URL")

if not NEON_DATABASE_URL:
    raise SystemExit(
        "Set the NEON_DATABASE_URL environment variable before running this script."
    )

engine = create_engine(NEON_DATABASE_URL, connect_args={"connect_timeout": 10})
Base.metadata.create_all(bind=engine)

SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

with open("data/medicines.json", "r", encoding="utf-8") as f:
    medicines = json.load(f)

inserted = 0
for item in medicines:
    medicine = Medicine(
        name=item.get("name"),
        manufacturer=item.get("manufacturer"),
        approved=item.get("approved", False),
        side_effects=item.get("side_effects"),
        avoid_in=item.get("avoid_in"),
        additional_info=item.get("additional_info"),
        # NOTE: "expiry_guidance" from the JSON is not stored - no matching
        # column exists on Medicine yet. Add one to models.py if you want it.
    )
    db.add(medicine)
    inserted += 1

db.commit()
db.close()

print(f"Inserted {inserted} medicines into Neon.")