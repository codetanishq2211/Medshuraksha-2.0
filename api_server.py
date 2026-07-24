"""
REST API server for MedShuraksha medicine data.
Provides endpoints to search and fetch medicines from PostgreSQL.
"""
import os
import json
from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
from psycopg2 import sql

app = Flask(__name__)
CORS(app)

# Database configuration from environment variables
PG_HOST = os.getenv("PG_HOST", "127.0.0.1")
PG_PORT = os.getenv("PG_PORT", "5432")
PG_USER = os.getenv("PG_USER", "postgres")
PG_PASSWORD = os.getenv("PG_PASSWORD", "")
PG_DB = os.getenv("PG_DB", "medshuraksha")
PG_TABLE = os.getenv("PG_TABLE", "public.medicines")


def get_db_connection():
    """Create and return a PostgreSQL database connection."""
    return psycopg2.connect(
        host=PG_HOST,
        port=PG_PORT,
        user=PG_USER,
        password=PG_PASSWORD,
        dbname=PG_DB,
    )


@app.route("/api/medicines/search", methods=["GET"])
def search_medicines():
    """
    Search medicines by name or manufacturer.
    Query parameters:
    - q: search query (name or manufacturer)
    - limit: maximum results (default: 50)
    """
    query = request.args.get("q", "").strip()
    limit = request.args.get("limit", 50, type=int)

    if not query:
        return jsonify({"error": "Search query required"}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        # Parse table name
        if "." in PG_TABLE:
            schema, table = PG_TABLE.split(".", 1)
        else:
            schema = "public"
            table = PG_TABLE

        # Search by name or manufacturer (case-insensitive)
        search_pattern = f"%{query}%"
        cur.execute(
            sql.SQL(
                "SELECT name, manufacturer, approved, side_effects, avoid_in, additional_info FROM {}.{} WHERE LOWER(name) LIKE LOWER(%s) OR LOWER(manufacturer) LIKE LOWER(%s) LIMIT %s"
            ).format(sql.Identifier(schema), sql.Identifier(table)),
            (search_pattern, search_pattern, limit),
        )

        rows = cur.fetchall()
        medicines = [
            {
                "name": row[0] or "",
                "manufacturer": row[1] or "",
                "approved": bool(row[2]) if row[2] is not None else True,
                "side_effects": row[3] or "",
                "avoid_in": row[4] or "",
                "additional_info": row[5] or "",
            }
            for row in rows
        ]

        cur.close()
        conn.close()

        return jsonify({"query": query, "count": len(medicines), "medicines": medicines})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/medicines/count", methods=["GET"])
def medicine_count():
    """Get total count of medicines in the database."""
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        if "." in PG_TABLE:
            schema, table = PG_TABLE.split(".", 1)
        else:
            schema = "public"
            table = PG_TABLE

        cur.execute(
            sql.SQL("SELECT COUNT(*) FROM {}.{}").format(
                sql.Identifier(schema), sql.Identifier(table)
            )
        )
        count = cur.fetchone()[0]

        cur.close()
        conn.close()

        return jsonify({"count": count})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/health", methods=["GET"])
def health():
    """Health check endpoint."""
    try:
        conn = get_db_connection()
        conn.close()
        return jsonify({"status": "ok", "database": "connected"})
    except Exception as e:
        return jsonify({"status": "error", "database": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
