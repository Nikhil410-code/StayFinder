#!/bin/sh
# entrypoint.sh - Bootstrapping script for StayFinder Docker container

if [ ! -f "$DATABASE_PATH" ]; then
    echo "Database not found at $DATABASE_PATH. Initializing and seeding database..."
    python scripts/seed.py
else
    echo "Database found at $DATABASE_PATH."
fi

echo "Starting StayFinder Flask API via Gunicorn..."
exec gunicorn --bind 0.0.0.0:4000 --workers 4 "app:create_app()"
