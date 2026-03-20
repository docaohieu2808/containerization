# L4: Reusable hardened base image for Python applications
# Demonstrates: security hardening, CA certs, timezone, non-root user baked in
#
# Build: docker build -f base-python-hardened.Dockerfile -t myorg/base-python:3.12 .
# Use:   FROM myorg/base-python:3.12

FROM python:3.12-slim

# ── Timezone & CA certs ──────────────────────────────────────────────────────
ENV TZ=UTC \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       tzdata \
       ca-certificates \
       curl \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo "$TZ" > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# ── Security hardening ───────────────────────────────────────────────────────
# Remove setuid/setgid bits from binaries not needed at runtime
RUN find / -perm /6000 -type f 2>/dev/null | xargs chmod a-s 2>/dev/null || true

# Upgrade pip to latest to avoid known CVEs
RUN pip install --upgrade pip

# ── Non-root user ────────────────────────────────────────────────────────────
RUN useradd -r -u 1001 -s /bin/false appuser

WORKDIR /app
RUN chown appuser /app

USER appuser

# Labels (OCI standard)
LABEL org.opencontainers.image.base.name="python:3.12-slim" \
      org.opencontainers.image.title="myorg/base-python" \
      org.opencontainers.image.description="Hardened Python 3.12 base image"
