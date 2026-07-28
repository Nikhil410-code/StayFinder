# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=4000
ENV DATABASE_PATH=/app/data/stayfinder.db

# Set the working directory in the container
WORKDIR /app

# Install system dependencies (needed for compiling bcrypt if no pre-built wheels)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . /app/

# Create directory for persistent SQLite database volume
RUN mkdir -p /app/data

# Make start script executable
RUN chmod +x /app/entrypoint.sh

# Expose the port the app runs on
EXPOSE 4000

# Set entrypoint to run migrations and start WSGI server
ENTRYPOINT ["/app/entrypoint.sh"]
