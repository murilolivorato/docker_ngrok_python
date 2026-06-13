# Python environment for the ngrok tutorial
FROM python:3.12-slim

# Don't write .pyc files and stream stdout/stderr straight to the logs.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000

WORKDIR /app

# Install dependencies first so this layer is cached between code changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application source.
COPY . .

EXPOSE 5000

CMD ["python", "main.py"]
