# L2: Multi-stage build for Python
# Demonstrates: install deps in builder, copy site-packages to slim runtime
# Result: no pip, no wheel cache, no compiler in runtime image
#
# Build: docker build -f python-app-multistage.Dockerfile -t python-multistage:latest .
# Run:   docker run -p 5000:5000 python-multistage:latest

# ── Stage 1: Build (install dependencies) ───────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /build

# Install build tools (only needed at build time)
RUN apt-get update && apt-get install -y --no-install-recommends gcc && rm -rf /var/lib/apt/lists/*

COPY ../../test-apps/python-app/flask-app-pip-requirements.txt ./requirements.txt

# Install to a local prefix so we can copy it cleanly
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM python:3.12-slim AS runtime

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application source
COPY ../../test-apps/python-app/flask-hello-world-server.py ./

# Non-root user
RUN useradd -r -s /bin/false appuser
USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "flask-hello-world-server:app"]
