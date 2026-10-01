import os

os.environ["DATABASE_URL"] = "sqlite:///./test_profile.db"

from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_save_and_get_profile():
    response = client.post(
        "/profile",
        json={
            "firebase_uid": "device_123",
            "name": "Alice",
            "date_of_birth": "2000-01-01",
        },
    )
    assert response.status_code == 200, response.text

    data = response.json()
    assert data["firebase_uid"] == "device_123"
    assert data["name"] == "Alice"

    fetch = client.get("/profile/device_123")
    assert fetch.status_code == 200, fetch.text
    assert fetch.json()["name"] == "Alice"
