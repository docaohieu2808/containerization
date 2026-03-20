# L3: BuildKit cache mount for Python pip
# Demonstrates: persistent pip cache directory across builds via --mount=type=cache
#
# Build: DOCKER_BUILDKIT=1 docker build \
#          -f python-app-buildkit-pip-cache-mount.Dockerfile -t python-buildkit:latest .

# syntax=docker/dockerfile:1.6
FROM python:3.12-slim

WORKDIR /app

COPY ../../test-apps/python-app/flask-app-pip-requirements.txt ./requirements.txt

# --mount=type=cache,target=/root/.cache/pip
# pip downloads are cached across builds; only re-downloaded when versions change
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -r requirements.txt

COPY ../../test-apps/python-app/flask-hello-world-server.py ./

RUN useradd -r -s /bin/false appuser
USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "flask-hello-world-server:app"]
