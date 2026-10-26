# syntax=docker/dockerfile:1
# L1: basic single-stage Dockerfile for Python (Flask + gunicorn).
# Teaches: requirements-before-source COPY order, no pip cache in the image,
# non-root user, exec-form HEALTHCHECK.
#
# Build: docker build -t python-basic .      (context = this directory)
# Run:   docker run --rm -p 5000:5000 python-basic
FROM python:3.15.0-slim-trixie

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py ./

RUN useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin app
USER 10001:10001

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health', timeout=3)"]

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
