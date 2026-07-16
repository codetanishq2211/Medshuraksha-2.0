import csv
import json
from pathlib import Path

csv_path = Path(r"d:\medshuraksha 2.0\kaggle_medicines.csv")
out_path = Path(r"d:\medshuraksha 2.0\medicines.json")


def clean(value):
    if value is None:
        return ""
    return str(value).strip()


def make_record(row):
    name = clean(row.get("name") or row.get("medicineName") or row.get("medicine_name") or "")
    if not name:
        return None

    manufacturer = clean(row.get("manufacturer_name") or row.get("manufacturer") or row.get("company") or "")
    side_effects = clean(row.get("Consolidated_Side_Effects") or row.get("side_effects") or row.get("Side Effects") or "")
    if not side_effects:
        side_effects = "No side-effects data available."

    avoid_in = clean(row.get("Habit Forming") or row.get("avoid_in") or row.get("Contraindications") or "")
    if not avoid_in:
        avoid_in = "Consult a doctor before use."

    uses = []
    for idx in range(5):
        key = f"use{idx}"
        value = clean(row.get(key))
        if value:
            uses.append(value)

    ingredients = []
    for key in ("short_composition1", "short_composition2"):
        value = clean(row.get(key))
        if value:
            ingredients.append(value)

    additional_parts = []
    if ingredients:
        additional_parts.append(f"Composition: {', '.join(ingredients)}")
    if uses:
        additional_parts.append(f"Uses: {'; '.join(uses)}")
    therapeutic_class = clean(row.get("Therapeutic Class") or row.get("therapeutic_class") or "")
    if therapeutic_class:
        additional_parts.append(f"Therapeutic class: {therapeutic_class}")
    action_class = clean(row.get("Action Class") or row.get("action_class") or "")
    if action_class:
        additional_parts.append(f"Action class: {action_class}")

    return {
        "name": name,
        "manufacturer": manufacturer,
        "approved": True,
        "expiry_guidance": "Check the printed expiry date and packaging instructions.",
        "side_effects": side_effects,
        "avoid_in": avoid_in,
        "additional_info": "; ".join(additional_parts) if additional_parts else "Kaggle dataset entry.",
    }


with csv_path.open("r", encoding="utf-8", newline="") as handle:
    reader = csv.DictReader(handle)
    records = []
    for row in reader:
        record = make_record(row)
        if record is not None:
            records.append(record)

out_path.write_text(json.dumps(records, indent=2, ensure_ascii=False), encoding="utf-8")
print(f"Imported {len(records)} records into {out_path}")
