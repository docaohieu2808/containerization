# syntax=docker/dockerfile:1
# L2: multi-stage Python build with a virtual environment.
# Teaches: install into a virtualenv in the builder, copy only that directory to
# the runtime stage. If a dependency needed a compiler, the compiler would stay
# in the builder stage.
#
# Build: docker build -t python-multistage . (context = this directory)
# Run:   docker run --rm -p 5000:5000 python-multistage
FROM python:3.14.9-slim-trixie AS builder
WORKDIR /build

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.14.9-slim-trixie AS runtime
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
COPY app.py ./

RUN useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin app
USER 10001:10001
EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health', timeout=3)"]

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
