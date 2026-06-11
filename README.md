# containerization

Leveled reference implementations for Docker, Podman, Buildah, and Cloud Native Buildpacks. Each level (`l1` → `l-max`) builds on the previous, demonstrating progressively advanced patterns.

## Structure

```
containerization/
├── docker/
│   ├── l1-basic-dockerfile/          # Single-stage builds (Go, Node, Python)
│   ├── l2-multi-stage-builds/        # Multi-stage + scratch final image
│   ├── l3-buildkit-advanced/         # BuildKit cache mounts (--mount=type=cache)
│   ├── l4-custom-base-images/        # Hardened base images (non-root, minimal)
│   └── l5-compose-advanced/          # Compose v2: profiles, healthchecks, secrets, configs
├── podman/
│   ├── l1-rootless-containers/       # Rootless Podman run examples
│   ├── l2-pods-multi-container/      # Pod create + multi-container pods
│   ├── l3-systemd-integration/       # podman generate systemd user services
│   ├── l4-quadlet-systemd-generator/ # Quadlet .container/.pod/.volume units
│   └── l-max-podman-kube-play/       # podman kube play from Kubernetes manifests
├── buildah/
│   ├── l1-build-oci-images/          # buildah bud + from/run/commit workflow
│   ├── l2-scratch-minimal-images/    # Scratch images via buildah from scratch
│   ├── l3-multi-arch-builds/         # Multi-arch manifests (amd64 + arm64)
│   └── l-max-buildah-scripts/        # Pure shell builds without Dockerfile
├── buildpacks/
│   ├── l1-auto-detect-build/         # pack build auto-detect
│   ├── l2-custom-buildpack/          # Custom buildpack descriptor + detect/build scripts
│   └── l-max-builder-composition/    # Custom builder with custom buildpacks
└── test-apps/                        # Minimal Go/Node/Python apps used by Dockerfiles
```

## Key patterns by level

| Level | Pattern | File |
|---|---|---|
| l2 | Multi-stage scratch + `USER 65534` | `docker/l2-multi-stage-builds/go-app-multistage-scratch.Dockerfile` |
| l3 | BuildKit `--mount=type=cache` for Go modules | `docker/l3-buildkit-advanced/go-app-buildkit-gomod-cache-mount.Dockerfile` |
| l4 | Hardened base: non-root user, read-only fs | `docker/l4-custom-base-images/base-node-hardened.Dockerfile` |
| l5 | Compose profiles + Docker secrets + healthchecks | `docker/l5-compose-advanced/docker-compose-profiles-healthcheck-secrets.yaml` |
| l4 (Podman) | Quadlet systemd unit files | `podman/l4-quadlet-systemd-generator/` |
| l-max (Buildah) | Full image build in pure shell, no Dockerfile | `buildah/l-max-buildah-scripts/buildah-pure-shell-no-dockerfile-build.sh` |

## Build examples

```bash
# l2: scratch Go image
docker build -f docker/l2-multi-stage-builds/go-app-multistage-scratch.Dockerfile \
  -t go-scratch:latest .

# l3: BuildKit cache mounts (requires BuildKit)
DOCKER_BUILDKIT=1 docker build \
  -f docker/l3-buildkit-advanced/go-app-buildkit-gomod-cache-mount.Dockerfile \
  -t go-buildkit:latest .

# l5: Compose with profiles
docker compose -f docker/l5-compose-advanced/docker-compose-profiles-healthcheck-secrets.yaml \
  --profile dev up
```

## Security baseline

All production-grade Dockerfiles in this repo follow these rules:
- Final stage uses non-root `USER` (numeric uid for scratch images)
- Multi-stage builds: only compiled artefacts copied to runtime stage
- No secrets in build args or `ENV` — use Docker secrets or runtime env injection
