# Containerization

Hands-on labs for Docker, Podman, Buildah, and Cloud Native Buildpacks. Each tool is explored at progressive skill levels — from basic usage to advanced production patterns.

## Tools Covered

| Tool | Purpose |
|------|---------|
| **Docker** | Industry-standard container runtime & build toolchain |
| **Podman** | Daemonless, rootless OCI runtime (systemd-native) |
| **Buildah** | Fine-grained OCI image construction without a daemon |
| **Buildpacks** | Source-to-image builds without Dockerfiles (CNB spec) |

## Skill Levels

| Level | Label | Description |
|-------|-------|-------------|
| L1 | Basic | Core concepts, single containers, simple images |
| L2 | Intermediate | Multi-stage builds, pods, custom buildpacks |
| L3 | Advanced | BuildKit, Buildah scratch images, multi-arch |
| L4 | Expert | Custom base images, Quadlet/systemd generators |
| L5 | Production | Compose advanced patterns, rootless prod setup |
| L-max | Master | Extensions, Buildah scripts, builder composition |

## Prerequisites

- Linux host (Ubuntu 22.04+ recommended) or macOS with Docker Desktop
- `docker` >= 24, `podman` >= 4, `buildah` >= 1.30 installed
- `pack` CLI for Buildpacks (`brew install buildpacks/tap/pack`)
- Basic shell scripting knowledge

## Quick Start

```bash
# Docker — basic Dockerfile
cd docker/l1-basic-dockerfile
docker build -t myapp .
docker run --rm myapp

# Podman — rootless container
cd podman/l1-rootless-containers
podman run --rm -it alpine sh

# Buildah — build OCI image
cd buildah/l1-build-oci-images
buildah bud -t myimage .

# Buildpacks — auto-detect build
cd buildpacks/l1-auto-detect-build
pack build myapp --builder paketobuildpacks/builder:base
```

## Directory Structure

```
containerization/
├── docker/
│   ├── l1-basic-dockerfile/
│   ├── l2-multi-stage-builds/
│   ├── l3-buildkit-advanced/
│   ├── l4-custom-base-images/
│   ├── l5-compose-advanced/
│   └── l-max-docker-extensions/
├── podman/
│   ├── l1-rootless-containers/
│   ├── l2-pods-multi-container/
│   ├── l3-systemd-integration/
│   ├── l4-quadlet-systemd-generator/
│   └── l-max-podman-kube-play/
├── buildah/
│   ├── l1-build-oci-images/
│   ├── l2-scratch-minimal-images/
│   ├── l3-multi-arch-builds/
│   └── l-max-buildah-scripts/
└── buildpacks/
    ├── l1-auto-detect-build/
    ├── l2-custom-buildpack/
    └── l-max-builder-composition/
```

## Usage

Work through levels sequentially within each tool. Each directory contains config files, Dockerfiles, or scripts with inline comments explaining the concept.

Recommended order: Docker → Podman → Buildah → Buildpacks.
