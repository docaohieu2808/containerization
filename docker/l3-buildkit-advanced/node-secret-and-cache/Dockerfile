# syntax=docker/dockerfile:1
# L3: BuildKit cache and secret mounts for npm.
# Teaches:
#   * --mount=type=cache   persistent ~/.npm cache between builds
#   * --mount=type=secret  a private-registry .npmrc that exists ONLY while the
#     `npm ci` instruction runs. It is never written to a layer, so
#     `docker history` and `docker save` cannot reveal it. required=false lets the
#     same Dockerfile build without a secret when no private registry is needed.
#
# Build without a secret:
#   docker build -t node-buildkit .
# Build with a private-registry .npmrc (the file holds the token; keep it out of git):
#   docker build --secret id=npmrc,src=$HOME/.npmrc -t node-buildkit .
#
# A related mount, not enabled here because it needs an SSH agent: forward it for
# private git dependencies with `RUN --mount=type=ssh git clone ...` and
# `docker build --ssh default .`
FROM node:24.22.1-alpine3.24

ENV NODE_ENV=production
WORKDIR /app

COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=secret,id=npmrc,target=/root/.npmrc,required=false \
    npm ci --omit=dev

COPY server.js ./

USER node
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:3000/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]

CMD ["node", "server.js"]
