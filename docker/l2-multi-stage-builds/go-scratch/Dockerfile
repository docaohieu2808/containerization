# syntax=docker/dockerfile:1
# L2: multi-stage Go build that ends in `FROM scratch`.
# Teaches: compile in a full toolchain image, ship one static binary, numeric
# non-root USER (scratch has no /etc/passwd), and a HEALTHCHECK that works
# without a shell: the binary probes itself via `-healthcheck`.
#
# Build: docker build -t go-scratch .        (context = this directory)
# Run:   docker run --rm -p 8080:8080 go-scratch
FROM golang:1.27.3-alpine3.24 AS build
WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY main.go ./
# CGO_ENABLED=0 -> fully static binary; -s -w strips symbol/debug info.
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/server .

FROM scratch
COPY --from=build /out/server /server

USER 65532:65532
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/server", "-healthcheck"]

ENTRYPOINT ["/server"]
