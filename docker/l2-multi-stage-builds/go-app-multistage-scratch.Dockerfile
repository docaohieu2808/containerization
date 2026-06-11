# L2: Multi-stage build for Go — final image is FROM scratch
# Demonstrates: compile in full Go image, copy single static binary to scratch
# Result: ~5MB image with zero OS overhead (no shell, no libc)
#
# Build: docker build -f go-app-multistage-scratch.Dockerfile -t go-scratch:latest .
# Run:   docker run -p 8080:8080 go-scratch:latest

# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM golang:1.22-alpine AS builder

WORKDIR /build

COPY ../../test-apps/go-app/go.mod ./
RUN go mod download

COPY ../../test-apps/go-app/http-hello-world-server.go ./

# CGO_ENABLED=0 produces a fully static binary (no dynamic libc links)
# -ldflags="-w -s" strips debug symbols → smaller binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-w -s" -o http-server http-hello-world-server.go

# ── Stage 2: Runtime (scratch) ───────────────────────────────────────────────
# scratch = empty filesystem; only the binary we copy in exists
FROM scratch AS runtime

# Copy CA certificates so HTTPS calls work inside scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy passwd so USER directive resolves at runtime (scratch has no /etc/passwd)
COPY --from=builder /etc/passwd /etc/passwd

# Copy the static binary
COPY --from=builder /build/http-server /http-server

# Run as nobody (uid 65534) — scratch has no useradd, reference by numeric uid
USER 65534

EXPOSE 8080

# No shell in scratch so HEALTHCHECK exec form only
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD ["/http-server"]

ENTRYPOINT ["/http-server"]
