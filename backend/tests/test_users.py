import os

os.environ["DATABASE_URL"] = "sqlite:///./test_users.db"

from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_register_and_list_user():
    response = client.post("/users/register", json={"name": "Alice"})
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["name"] == "Alice"

    list_response = client.get("/users")
    assert list_response.status_code == 200, list_response.text
    names = [item["name"] for item in list_response.json()]
    assert "Alice" in names


def test_database_health_reports_users_table():
    response = client.get("/health/database")

    assert response.status_code == 200, response.text
    assert response.json()["database_url_configured"] is True
    assert "database_host" in response.json()
    assert response.json()["users_table_exists"] is True
