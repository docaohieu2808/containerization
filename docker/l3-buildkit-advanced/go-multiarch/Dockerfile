# syntax=docker/dockerfile:1
# L3: BuildKit cache mounts + real multi-arch.
# Teaches:
#   * --mount=type=cache  keeps the Go module and build caches between builds
#   * FROM --platform=$BUILDPLATFORM  runs the compiler natively on the build host
#   * TARGETOS/TARGETARCH  tell the Go compiler which platform to cross-compile for,
#     so an arm64 image really contains an arm64 binary, with no emulation of the
#     compile step.
#
# Single platform: docker buildx build -t go-multiarch --load .
# Multi-platform:  docker buildx build --platform linux/amd64,linux/arm64 -t REGISTRY/go-multiarch --push .
FROM --platform=$BUILDPLATFORM golang:1.27.3-alpine3.24 AS build
ARG TARGETOS
ARG TARGETARCH
WORKDIR /src

COPY go.mod ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

COPY main.go ./
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -o /out/server .

FROM scratch
COPY --from=build /out/server /server

USER 65532:65532
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/server", "-healthcheck"]

ENTRYPOINT ["/server"]
