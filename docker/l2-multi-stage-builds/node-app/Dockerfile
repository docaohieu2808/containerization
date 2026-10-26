# syntax=docker/dockerfile:1
# L2: multi-stage Node build.
# Teaches: install everything in a builder, prune to production dependencies,
# and copy only the result (node_modules + source) into a clean runtime stage.
# No npm cache and no devDependencies end up in the final image.
#
# Build: docker build -t node-multistage .   (context = this directory)
# Run:   docker run --rm -p 3000:3000 node-multistage
FROM node:26.12.1-alpine3.24 AS builder
WORKDIR /build

COPY package.json package-lock.json ./
RUN npm ci

COPY server.js ./
# A real project would run its bundler/tsc here. Pruning shows the principle:
# the runtime stage only receives what it needs to run.
RUN npm prune --omit=dev

FROM node:26.12.1-alpine3.24 AS runtime
ENV NODE_ENV=production
WORKDIR /app

COPY --from=builder --chown=node:node /build/node_modules ./node_modules
COPY --from=builder --chown=node:node /build/server.js /build/package.json ./

USER node
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:3000/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]

CMD ["node", "server.js"]
