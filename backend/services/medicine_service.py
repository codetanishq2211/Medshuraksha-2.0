from sqlalchemy.orm import Session
from models import Medicine


def search_local(db: Session, query: str, limit: int = 20):
    medicines = (
        db.query(Medicine)
        .filter(Medicine.name.ilike(f"%{query}%"))
        .limit(limit)
        .all()
    )

    return [
        {
            "id": m.id,
            "name": m.name,
            "manufacturer": m.manufacturer,
            "approved": m.approved,
            "side_effects": m.side_effects,
            "avoid_in": m.avoid_in,
            "additional_info": m.additional_info,
        }
        for m in medicines
    ]