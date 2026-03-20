# L3: BuildKit advanced — cache mounts, secrets, SSH forwarding
# Demonstrates:
#   --mount=type=cache  → persistent build cache across builds (npm, pip, go mod)
#   --mount=type=secret → inject secrets at build time without baking into image
#   --mount=type=ssh    → forward SSH agent for private git repos
#
# Requirements: DOCKER_BUILDKIT=1 (default in Docker 23+)
#
# Build with cache mount only:
#   docker build -f node-app-buildkit-cache-mounts.Dockerfile -t node-buildkit:latest .
#
# Build with secret (e.g. NPM_TOKEN for private registry):
#   docker build \
#     --secret id=npm_token,src=./npm-token.txt \
#     -f node-app-buildkit-cache-mounts.Dockerfile -t node-buildkit:latest .
#
# Build with SSH agent forwarding (for private git deps):
#   eval $(ssh-agent) && ssh-add ~/.ssh/id_rsa
#   docker build --ssh default \
#     -f node-app-buildkit-cache-mounts.Dockerfile -t node-buildkit:latest .

# syntax=docker/dockerfile:1.6
FROM node:20-alpine

WORKDIR /app

COPY ../../test-apps/node-app/package.json ./

# --mount=type=cache: BuildKit keeps this directory between builds
# Cache key is scoped per platform; speeds up repeated builds dramatically
RUN --mount=type=cache,target=/root/.npm \
    npm install --omit=dev

# Example: consume a build-time secret (never stored in image layers)
# The secret is only available during this RUN instruction
RUN --mount=type=secret,id=npm_token \
    if [ -f /run/secrets/npm_token ]; then \
      echo "//registry.npmjs.org/:_authToken=$(cat /run/secrets/npm_token)" > ~/.npmrc; \
    fi

# Example: SSH mount — forward agent socket for git clone of private repos
# RUN --mount=type=ssh \
#     git clone git@github.com:myorg/private-lib.git /tmp/private-lib

COPY ../../test-apps/node-app/express-hello-world-server.js ./

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "express-hello-world-server.js"]
