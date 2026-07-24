import os
import requests

# Adjust these via environment variables if your Ollama setup differs
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3")


def ask_ollama(medicine_name: str) -> str:
    prompt = (
        "You are a medical information assistant. A user scanned a medicine "
        f"packet and the detected name is: '{medicine_name}'. "
        "Give a short, clear summary covering: what it is likely used for, "
        "common side effects, and who should avoid it. "
        "If you are not confident this is a real medicine, say so plainly "
        "instead of guessing."
    )

    try:
        response = requests.post(
            f"{OLLAMA_BASE_URL}/api/generate",
            json={
                "model": OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False,
            },
            timeout=60,
        )
        response.raise_for_status()
        data = response.json()
        return data.get("response", "").strip()
    except requests.RequestException as e:
        return f"AI lookup failed: {e}"