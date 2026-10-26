# syntax=docker/dockerfile:1
# L4: reusable hardened base image for Node.js services.
# Teaches: bake the boring-but-important defaults into one image so every service
# inherits them: UTC timezone, CA certificates, no setuid/setgid binaries,
# a fixed non-root uid, and update-notifier noise disabled.
#
# Build: docker build -t myorg/base-node:24 .   (context = this directory)
# Use:   FROM myorg/base-node:24                (see ../derived-node-app)
# Run it read-only for extra hardening: docker run --read-only --tmpfs /tmp ...
FROM node:24.22.1-alpine3.24

ENV TZ=UTC \
    NPM_CONFIG_UPDATE_NOTIFIER=false

# Package versions come from the pinned Alpine release; the base tag is the pin.
# hadolint ignore=DL3018
RUN apk add --no-cache tzdata ca-certificates \
    && cp "/usr/share/zoneinfo/$TZ" /etc/localtime \
    && echo "$TZ" > /etc/timezone \
    && apk del tzdata

# Strip setuid/setgid bits from everything on the root filesystem.
RUN find / -xdev -perm /6000 -type f -exec chmod a-s {} +

# Fixed uid/gid so volumes and Kubernetes runAsUser can be set deterministically.
RUN addgroup -S -g 10001 app && adduser -S -u 10001 -G app app

WORKDIR /app
RUN chown app:app /app

USER 10001:10001

LABEL org.opencontainers.image.title="myorg/base-node" \
      org.opencontainers.image.description="Hardened Node.js 24 base image" \
      org.opencontainers.image.base.name="docker.io/library/node:24.22.1-alpine3.24"
