# L1: Basic Dockerfile for Node.js
# Demonstrates: proper COPY order for layer caching, non-root user, healthcheck
#
# Build: docker build -f node-app-basic.Dockerfile -t node-basic:latest .
# Run:   docker run -p 3000:3000 node-basic:latest

FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy dependency manifests first (layer cache: only invalidated when deps change)
COPY ../../test-apps/node-app/package.json ./

# Install dependencies (cached layer unless package.json changes)
RUN npm install --omit=dev

# Copy application source after deps (layer cache: invalidated only on source change)
COPY ../../test-apps/node-app/express-hello-world-server.js ./

# Create non-root user and switch to it (security hardening)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose application port
EXPOSE 3000

# Healthcheck: Docker marks container unhealthy if /health returns non-200
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Start application
CMD ["node", "express-hello-world-server.js"]
