# syntax=docker/dockerfile:1
# L-max: a minimal Docker Desktop extension (UI only, no backend).
# Teaches: an extension is an ordinary image that carries `metadata.json`, a UI
# directory and a set of labels Docker Desktop reads. It is FROM scratch because
# Docker Desktop serves the files itself; nothing in the image ever runs, so there
# is no process and no USER to set.
#
# Build:   docker build -t myorg/my-extension:0.1.0 .   (context = this directory)
# Install: docker extension install myorg/my-extension:0.1.0   (needs Docker Desktop)
FROM scratch

LABEL org.opencontainers.image.title="My Extension" \
      org.opencontainers.image.description="A minimal Docker Desktop UI extension" \
      org.opencontainers.image.vendor="myorg" \
      com.docker.desktop.extension.api.version=">= 0.3.0" \
      com.docker.desktop.extension.icon="https://example.com/extension-icon.svg" \
      com.docker.extension.publisher-url="https://example.com" \
      com.docker.extension.detailed-description="<p>Shows a static page inside Docker Desktop.</p>" \
      com.docker.extension.changelog="<ul><li>Initial version.</li></ul>"

COPY metadata.json /metadata.json
COPY ui /ui
