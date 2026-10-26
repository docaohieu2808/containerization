# syntax=docker/dockerfile:1
# L3: BuildKit cache mount for pip.
# Teaches: --mount=type=cache keeps pip's download/wheel cache between builds on
# the build host, while the image itself stays free of it (the cache lives in the
# mount, not in a layer).
#
# Build: docker build -t python-buildkit .   (context = this directory)
# Run:   docker run --rm -p 5000:5000 python-buildkit
FROM python:3.15.0-slim-trixie

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app

COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

COPY app.py ./

RUN useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin app
USER 10001:10001
EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health', timeout=3)"]

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
