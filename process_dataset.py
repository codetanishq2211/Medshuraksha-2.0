import csv
import json
from pathlib import Path

# Read CSV
csv_file = Path('Extensive_A_Z_medicines_dataset_of_India.csv')
output_file = Path('medicines_from_kaggle.json')

medicines = []
with open(csv_file, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    medicines = list(reader)

print(f"✅ Loaded {len(medicines)} medicines from CSV")
print(f"\nColumns in CSV:")
if medicines:
    for col in medicines[0].keys():
        print(f"  - {col}")
    
    print(f"\nFirst medicine entry:")
    for k, v in medicines[0].items():
        print(f"  {k}: {v}")

# Save as JSON
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(medicines, f, indent=2, ensure_ascii=False)

print(f"\n✅ Saved to {output_file}")
