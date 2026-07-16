# MedShuraksha

A simple medicine lookup app for checking government-approved medicines by name or photo.

## Features
- Search by medicine name or manufacturer.
- Upload a medicine photo and use OCR to extract text.
- Load medicine data from PostgreSQL for fast local lookup.
- Fallback to Ollama AI if the medicine is not found locally.

## Setup
1. Open a terminal in the project folder.
2. Install dependencies:
   ```powershell
   .\.venv\Scripts\python.exe -m pip install -r requirements.txt
   ```
3. (Optional) Install Tesseract OCR for image recognition:
   - Windows: install from https://github.com/tesseract-ocr/tesseract
   - Make sure `tesseract.exe` is on your PATH.

## Run
```powershell
.\.venv\Scripts\python.exe -m streamlit run main.py
```

## PostgreSQL database connection
The app prefers PostgreSQL when the following environment variables are set:
```powershell
setx PG_HOST "127.0.0.1"
setx PG_PORT "5432"
setx PG_USER "postgres"
setx PG_PASSWORD "your_password"
setx PG_DB "medshuraksha"
setx PG_TABLE "public.medicines"
```
Optionally set `PG_TABLE` if your table uses a different schema or name.

If PostgreSQL is configured, the app loads medicine records directly from the database and does not require the large local dataset files.

## Ollama AI fallback
To use Ollama fallback when a medicine is not found locally, set:
```powershell
setx OLLAMA_API_URL "http://127.0.0.1:11434/v1/chat/completions"
setx OLLAMA_MODEL "llama2"
```
Then restart your terminal.

## Remote dataset (for deployment)
If you want the app to load medicine data from a public URL instead of a large local file, set:
```powershell
setx MEDICINES_DATA_URL "https://example.com/medicines.json"
```
The app will use that URL first and fall back to the local `medicines.json` file if it is unavailable.

## Notes
- The app uses PostgreSQL by default when DB credentials are provided.
- Local dataset files like `medicines.json` and `kaggle_medicines.csv` are ignored by git to keep the repository small.
- If OCR is not working, ensure `pytesseract` is installed and Tesseract is configured correctly.
