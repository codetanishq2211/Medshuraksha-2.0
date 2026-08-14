from services.gemini_service import ask_gemini


def ask_ai(question: str) -> str:
    if not GROQ_API_KEY:
        return "AI lookup is not configured: missing GROQ_API_KEY."

    try:
        response = requests.post(
            GROQ_URL,
            headers={
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": GROQ_MODEL,
                "messages": [{"role": "user", "content": question}],
                "temperature": 0.3,
            },
            timeout=30,
        )
        response.raise_for_status()
        data = response.json()
        return data["choices"][0]["message"]["content"].strip()
    except requests.RequestException as e:
        return f"AI lookup failed: {e}"