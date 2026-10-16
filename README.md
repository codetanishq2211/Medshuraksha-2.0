# MedShuraksha

[![Flutter](https://img.shields.io/badge/Flutter-mobile%20app-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/API-FastAPI-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

MedShuraksha is a medicine information and verification app. Search for a medicine or scan its packaging to look for a match in the app's medicine catalogue. If no catalogue match is found, the app can request general information from its configured AI service.

> **Health information notice:** This app is not a substitute for a doctor or pharmacist. Catalogue coverage and data quality may vary; always verify medicine, approval, dosage, and safety information with a qualified professional.

## Features

- Search the medicine catalogue by name.
- Scan medicine packaging; OCR extracts a name and checks the configured database.
- View catalogue details when a match is available, including manufacturer, approval status, side effects, and precautions where supplied.
- Receive AI-generated general information when a scan or search has no catalogue match.
- Keep scan history on the device.
- Use the profile and sign-in features when configured with Firebase.

## How it works

1. The app sends a scanned image to the backend, which uses the configured Gemini service for text extraction.
2. The backend searches its configured medicine database for the extracted name.
3. If there is no database match, the backend may send the medicine name to the configured AI service for general information. This is not a live web search or a verified database result.

## Project structure

| Path | Description |
| --- | --- |
| `medsuraksha_app/` | Flutter mobile application |
| `backend/` | FastAPI service, database models, and API routes |
| `backend/data/` | Backend medicine data files, when provided |
| `render.yaml` | Render deployment configuration |

## Run the backend locally

Requirements: Python 3.11 or later.

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

The backend uses a local SQLite database by default. Set environment variables in your current PowerShell session as needed:

```powershell
$env:DATABASE_URL = "sqlite:///./medshuraksha.db"
$env:GEMINI_API_KEY = "your-gemini-api-key"
$env:GROQ_API_KEY = "your-groq-api-key"
```

Gemini is used for scan OCR; Groq is used for the AI assistant and medicine-information fallback. Keep real keys out of source files, screenshots, and commits. The API can start without AI keys, but AI-backed features will not work.

Start the API:

```powershell
uvicorn main:app --reload
```

Visit `http://127.0.0.1:8000/docs` for interactive API documentation.

To use PostgreSQL instead of SQLite, set `DATABASE_URL` to a PostgreSQL connection URL before starting the backend. Ensure the database is provisioned and the medicine catalogue is populated for database search to return matches.

## Run the Flutter app

Requirements: Flutter SDK compatible with the project's Dart SDK constraint.

```powershell
cd medsuraksha_app
flutter pub get
flutter run
```

The app currently uses the backend URL configured in `lib/services/api_service.dart`. For local development against your own backend, configure that URL for your device or emulator and network setup.

Firebase configuration is not included in this public repository. To enable Firebase features, create or use your own Firebase project and add its Android `google-services.json` and iOS `GoogleService-Info.plist` locally. These files are intentionally ignored by Git.

## Privacy and deployment

- Scan images are sent to the configured backend and Gemini service for OCR. When no catalogue match is found, the medicine name may be sent to the configured AI service.
- Scan history is stored locally on the device. Profile information submitted through the app is stored by the configured backend.
- Do not commit API keys, database URLs, Firebase configuration, personal health information, or uploaded medicine images.
- The current backend is a project/demo implementation. Do not use it to process real personal or health information in a public deployment without first adding and reviewing appropriate authentication, authorization, and privacy safeguards.

## Tests

From the `backend/` directory, install the test tools if needed and run:

```powershell
python -m pip install pytest httpx
python -m pytest
```

## Contributing

Issues and pull requests are welcome. Please avoid including credentials, private health information, or real user data in reports and test fixtures.

## License

This project is licensed under the [MIT License](LICENSE).
