# L1: Basic Dockerfile for Python (Flask)
# Demonstrates: proper COPY order for layer caching, non-root user, healthcheck
#
# Build: docker build -f python-app-basic.Dockerfile -t python-basic:latest .
# Run:   docker run -p 5000:5000 python-basic:latest

FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Copy dependency manifest first (layer cache: only invalidated when deps change)
COPY ../../test-apps/python-app/flask-app-pip-requirements.txt ./requirements.txt

# Install dependencies (cached layer unless requirements.txt changes)
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source after deps
COPY ../../test-apps/python-app/flask-hello-world-server.py ./

# Create non-root user and switch to it (security hardening)
RUN useradd -r -s /bin/false appuser
USER appuser

# Expose application port
EXPOSE 5000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

# Use gunicorn for production serving
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "flask-hello-world-server:app"]
