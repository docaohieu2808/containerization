"""Tiny Flask service shared by the Python container examples.

GET /        JSON greeting (hostname, pid)
GET /health  {"status": "ok"}
"""
import os
import socket

from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def index():
    return jsonify(
        message="Hello from Python container!",
        hostname=socket.gethostname(),
        pid=os.getpid(),
    )


@app.route("/health")
def health():
    return jsonify(status="ok"), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
