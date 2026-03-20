# Simple Flask HTTP server — used as test app across all containerization examples
# Exposes GET / (hello JSON) and GET /health (healthcheck endpoint)
from flask import Flask, jsonify
import socket
import os

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({
        'message': 'Hello from Python container!',
        'hostname': socket.gethostname(),
        'pid': os.getpid(),
    })

@app.route('/health')
def health():
    return jsonify({'status': 'ok'}), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
