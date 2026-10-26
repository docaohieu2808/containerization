# syntax=docker/dockerfile:1
# L1: basic single-stage Dockerfile for Node.js.
# Teaches: manifest-before-source COPY order, reproducible installs with `npm ci`,
# non-root user, exec-form HEALTHCHECK.
#
# Build: docker build -t node-basic .        (context = this directory)
# Run:   docker run --rm -p 3000:3000 node-basic
FROM node:24.22.1-alpine3.24

ENV NODE_ENV=production
WORKDIR /app

# Dependency manifests first: the install layer is only invalidated when they change.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY server.js ./

# The official image ships a non-root `node` user (uid 1000).
USER node

EXPOSE 3000

# Node 24 has fetch built in, so no curl/wget is needed.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:3000/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]

CMD ["node", "server.js"]
