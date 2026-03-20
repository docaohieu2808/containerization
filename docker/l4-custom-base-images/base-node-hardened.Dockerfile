# L4: Reusable hardened base image for Node.js applications
# Demonstrates: security hardening, CA certs, timezone, non-root user baked in
# This base image is built once and used as FROM in all Node app Dockerfiles
#
# Build: docker build -f base-node-hardened.Dockerfile -t myorg/base-node:20 .
# Use:   FROM myorg/base-node:20

FROM node:20-alpine

# ── Timezone & locale ────────────────────────────────────────────────────────
ENV TZ=UTC
RUN apk add --no-cache tzdata ca-certificates \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo "$TZ" > /etc/timezone \
    && apk del tzdata

# ── Security hardening ───────────────────────────────────────────────────────
# Remove unnecessary setuid/setgid binaries
RUN find / -perm /6000 -type f 2>/dev/null | xargs chmod a-s 2>/dev/null || true

# Disable npm update notifications (reduces surface for supply-chain confusion)
RUN npm config set update-notifier false

# ── Non-root user ────────────────────────────────────────────────────────────
# Pre-create app user so derived images don't need to repeat this
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# ── Working directory ────────────────────────────────────────────────────────
WORKDIR /app
RUN chown appuser:appgroup /app

# Default to non-root (derived images can override if build step needs root)
USER appuser

# Labels for image metadata (OCI standard)
LABEL org.opencontainers.image.base.name="node:20-alpine" \
      org.opencontainers.image.title="myorg/base-node" \
      org.opencontainers.image.description="Hardened Node.js 20 base image"
