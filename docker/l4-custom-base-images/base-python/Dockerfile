# syntax=docker/dockerfile:1
# L4: reusable hardened base image for Python services.
# Teaches: UTC timezone, CA certificates, no setuid/setgid binaries, a fixed
# non-root uid, and no curl in the image (health probes use the Python stdlib).
#
# Build: docker build -t myorg/base-python:3.14 .   (context = this directory)
# Use:   FROM myorg/base-python:3.14
# Run it read-only for extra hardening: docker run --read-only --tmpfs /tmp ...
FROM python:3.14.9-slim-trixie

ENV TZ=UTC \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Package versions come from the pinned Debian release; the base tag is the pin.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends tzdata ca-certificates \
    && ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime \
    && echo "$TZ" > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# Strip setuid/setgid bits from everything on the root filesystem.
RUN find / -xdev -perm /6000 -type f -exec chmod a-s {} +

RUN useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin app

WORKDIR /app
RUN chown app /app

USER 10001:10001

LABEL org.opencontainers.image.title="myorg/base-python" \
      org.opencontainers.image.description="Hardened Python 3.14 base image" \
      org.opencontainers.image.base.name="docker.io/library/python:3.14.9-slim-trixie"
