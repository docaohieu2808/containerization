# L1: Basic Dockerfile for Go
# Demonstrates: proper COPY order, non-root user, healthcheck
# Note: For production prefer multi-stage (see l2-multi-stage-builds)
#
# Build: docker build -f go-app-basic.Dockerfile -t go-basic:latest .
# Run:   docker run -p 8080:8080 go-basic:latest

FROM golang:1.22-alpine

# Set working directory
WORKDIR /app

# Copy go.mod first (layer cache: only invalidated when module deps change)
COPY ../../test-apps/go-app/go.mod ./

# Download modules (cached unless go.mod changes)
RUN go mod download

# Copy source after module cache
COPY ../../test-apps/go-app/http-hello-world-server.go ./

# Build binary
RUN go build -o http-server http-hello-world-server.go

# Create non-root user (Alpine style)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose application port
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["./http-server"]
