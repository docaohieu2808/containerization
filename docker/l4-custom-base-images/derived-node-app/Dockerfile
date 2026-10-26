# syntax=docker/dockerfile:1
# L4: an application image derived from the hardened Node base (../base-node).
# Teaches: the app Dockerfile shrinks to "install deps, copy code" because the
# user, timezone, certs and hardening are inherited from the base.
#
# Build the base first, then this image:
#   docker build -t myorg/base-node:24 ../base-node
#   docker build --build-arg BASE_IMAGE=myorg/base-node:24 -t derived-node .
# Run read-only (the app only needs to read its own files):
#   docker run --rm --read-only -p 3000:3000 derived-node
ARG BASE_IMAGE=myorg/base-node:24
FROM ${BASE_IMAGE}

ENV NODE_ENV=production

COPY --chown=app:app package.json package-lock.json /app/
RUN npm ci --omit=dev

COPY --chown=app:app server.js /app/

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:3000/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]

CMD ["node", "server.js"]
