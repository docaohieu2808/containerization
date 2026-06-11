# L3: BuildKit cache mount for Go modules
# Demonstrates: persistent GOMODCACHE and GOCACHE across builds
#
# Build: DOCKER_BUILDKIT=1 docker build \
#          -f go-app-buildkit-gomod-cache-mount.Dockerfile -t go-buildkit:latest .

# syntax=docker/dockerfile:1.6
FROM golang:1.22-alpine AS builder

WORKDIR /build

COPY ../../test-apps/go-app/go.mod ./
COPY ../../test-apps/go-app/http-hello-world-server.go ./

# --mount=type=cache for both module download cache and build cache
# GOMODCACHE: downloaded modules reused across builds
# GOCACHE: compiled packages reused across builds
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-w -s" -o http-server http-hello-world-server.go

FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
# Copy passwd so USER directive resolves; reference nobody by numeric uid in scratch
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /build/http-server /http-server
USER 65534
EXPOSE 8080
ENTRYPOINT ["/http-server"]
