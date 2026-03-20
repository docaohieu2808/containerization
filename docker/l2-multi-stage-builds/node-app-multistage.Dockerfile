# L2: Multi-stage build for Node.js
# Demonstrates: build stage installs all deps + transpiles; runtime stage copies only dist
# Result: runtime image has no dev tools, no build cache, significantly smaller
#
# Build: docker build -f node-app-multistage.Dockerfile -t node-multistage:latest .
# Run:   docker run -p 3000:3000 node-multistage:latest

# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /build

# Install ALL dependencies (including devDependencies for build tools)
COPY ../../test-apps/node-app/package.json ./
RUN npm install

# Copy source and build (transpile/bundle if needed — here just copy for demo)
COPY ../../test-apps/node-app/express-hello-world-server.js ./

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
# Fresh base — no build tools, no dev deps, no npm cache
FROM node:20-alpine AS runtime

WORKDIR /app

# Copy only production deps manifest and install prod deps
COPY ../../test-apps/node-app/package.json ./
RUN npm install --omit=dev

# Copy only the built artifact from builder stage (not the whole filesystem)
COPY --from=builder /build/express-hello-world-server.js ./

# Non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "express-hello-world-server.js"]
