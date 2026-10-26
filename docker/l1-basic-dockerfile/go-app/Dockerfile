# syntax=docker/dockerfile:1
# L1: basic single-stage Dockerfile for Go.
# Teaches: layer-cache friendly COPY order, non-root user, exec-form HEALTHCHECK.
# Single stage means the whole Go toolchain ships in the image; l2 fixes that.
#
# Build: docker build -t go-basic .          (context = this directory)
# Run:   docker run --rm -p 8080:8080 go-basic
FROM golang:1.27.3-alpine3.24

WORKDIR /app

# go.mod first: the module-download layer is only invalidated when deps change.
COPY go.mod ./
RUN go mod download

COPY main.go ./
RUN go build -o /app/server .

# Fixed numeric uid so the user is the same in every environment.
RUN addgroup -S -g 10001 app && adduser -S -u 10001 -G app app
USER 10001:10001

EXPOSE 8080

# Exec form: no shell needed. Busybox wget exits non-zero on connection failure or HTTP error.
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8080/health"]

CMD ["/app/server"]
