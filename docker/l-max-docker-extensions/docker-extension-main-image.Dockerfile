# MAX: Docker Desktop Extension — main extension image Dockerfile
# This image IS the extension; it packages metadata + UI assets
# Docker Desktop loads this image and reads metadata.json to configure the extension
#
# Build: docker build -f docker-extension-main-image.Dockerfile -t myorg/my-extension:latest .
# Install into Docker Desktop: docker extension install myorg/my-extension:latest

FROM alpine:3.19

# Copy extension metadata — required by Docker Desktop
COPY docker-extension-metadata.json /metadata.json

# Copy UI assets (React/Vue/HTML) — served by Docker Desktop's built-in web server
# In a real extension this would be built by your frontend toolchain
COPY ui/ /ui/

# Copy any host binaries the extension needs (optional)
# COPY --platform=linux/amd64 bin/linux/my-binary /linux/my-binary
# COPY --platform=windows/amd64 bin/windows/my-binary.exe /windows/my-binary.exe
# COPY --platform=darwin/amd64 bin/darwin/my-binary /darwin/my-binary

# Labels required by Docker Desktop for extension discovery
LABEL org.opencontainers.image.title="My Extension" \
      org.opencontainers.image.description="A Docker Desktop extension skeleton" \
      org.opencontainers.image.vendor="myorg" \
      com.docker.desktop.extension.api.version=">= 0.3.3" \
      com.docker.desktop.extension.icon="https://myorg.example.com/extension-icon.svg"
