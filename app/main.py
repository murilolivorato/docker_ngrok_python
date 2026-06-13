"""
Minimal Flask app used to demonstrate exposing a Dockerized Python
service to the public internet through ngrok.
"""
import json
import logging
import os
import socket
from datetime import datetime
from logging.handlers import RotatingFileHandler
from pathlib import Path

from flask import Flask, jsonify, request

app = Flask(__name__)

# Write webhook events to a rotating log file inside /app/logs/
_log_dir = Path("/app/logs")
_log_dir.mkdir(parents=True, exist_ok=True)
_handler = RotatingFileHandler(
    _log_dir / "webhooks.log",
    maxBytes=1_000_000,   # 1 MB per file
    backupCount=5,
)
_handler.setFormatter(logging.Formatter("%(message)s"))
_webhook_log = logging.getLogger("webhooks")
_webhook_log.setLevel(logging.INFO)
_webhook_log.addHandler(_handler)
_webhook_log.propagate = False


def _log_webhook(payload: dict) -> None:
    entry = {
        "time": datetime.utcnow().isoformat() + "Z",
        "source_ip": request.remote_addr,
        "event": request.headers.get("X-GitHub-Event", "unknown"),
        "delivery": request.headers.get("X-GitHub-Delivery", "-"),
        "payload": payload,
    }
    _webhook_log.info(json.dumps(entry))


@app.route("/")
def index():
    """Landing page — handy to confirm the tunnel reaches the app."""
    return f"""
    <html>
      <head><title>Python + Docker + ngrok</title></head>
      <body style="font-family: sans-serif; max-width: 640px; margin: 40px auto;">
        <h1>🐍 + 🐳 + 🔗 It works!</h1>
        <p>This Flask app is running inside a Docker container and is being
           served to the public internet by ngrok.</p>
        <ul>
          <li><b>Container host:</b> {socket.gethostname()}</li>
          <li><b>Server time:</b> {datetime.utcnow().isoformat()}Z</li>
          <li><b>You requested:</b> {request.host}</li>
        </ul>
        <p>Try the JSON endpoint: <a href="/api/hello">/api/hello</a></p>
      </body>
    </html>
    """


@app.route("/api/hello")
def hello():
    """A tiny JSON endpoint — useful when testing webhooks / API calls."""
    return jsonify(
        message="Hello from a Dockerized Python app exposed via ngrok!",
        host=request.host,
        time=datetime.utcnow().isoformat() + "Z",
    )


@app.route("/webhook", methods=["POST", "GET"])
def webhook():
    """
    Example webhook receiver. Point a third-party service (Stripe, GitHub,
    a payment gateway, etc.) at <your-ngrok-url>/webhook to receive callbacks
    on your local machine.
    """
    payload = request.get_json(silent=True) or {}
    _log_webhook(payload)
    return jsonify(status="received", payload=payload)


if __name__ == "__main__":
    # 0.0.0.0 so the app is reachable from outside the container.
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)
