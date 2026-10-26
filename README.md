# containerization

[![ci](https://github.com/docaohieu2808/containerization/actions/workflows/ci.yml/badge.svg)](https://github.com/docaohieu2808/containerization/actions/workflows/ci.yml)

A leveled ladder for building and running containers with **Docker**, **Podman**,
**Buildah** and **Cloud Native Buildpacks**. Every level is a runnable example;
CI builds and runs all of them on GitHub-hosted runners, on every push and every
Monday, so the versions below stay honest.

Each example is **self-contained**: it is built from its own directory (the build
context) and ships its own tiny sample app (a "hello" HTTP service with `/` and
`/health`). No Dockerfile reaches outside its directory with `COPY ../..`.

## Level map

| Tool | Level | Directory | What it teaches |
|---|---|---|---|
| Docker | l1 | `docker/l1-basic-dockerfile/{go,node,python}-app` | layer-cache COPY order, `npm ci`, non-root user, exec-form `HEALTHCHECK` |
| Docker | l2 | `docker/l2-multi-stage-builds/*` | builder/runtime split, `npm prune`, virtualenv copy, `FROM scratch` Go with a self-probing healthcheck |
| Docker | l3 | `docker/l3-buildkit-advanced/*` | `--mount=type=cache`, `--mount=type=secret` (token never in a layer), real multi-arch with `TARGETOS`/`TARGETARCH` |
| Docker | l4 | `docker/l4-custom-base-images/*` | hardened reusable base images (Node, Python) + an app derived from one, run read-only |
| Docker | l5 | `docker/l5-compose-advanced` | Compose profiles, `service_healthy`, file secrets, configs, replicas, read-only prod container, a test profile |
| Docker | l-max | `docker/l-max-docker-extensions` | a minimal Docker Desktop UI extension image |
| Podman | l1 | `podman/l1-rootless-containers` | rootless, user namespaces, `--userns=keep-id`, pasta networking |
| Podman | l2 | `podman/l2-pods-multi-container` | pods and the shared network namespace |
| Podman | l3 | `podman/l3-quadlet-single-container` | Quadlet `.container` unit, hardening, `podman quadlet install`, `systemctl --user` |
| Podman | l4 | `podman/l4-quadlet-pod-multi-unit` | Quadlet `.network` + `.volume` + `.pod` + two `.container` units |
| Podman | l-max | `podman/l-max-podman-kube-play` | `podman kube play` / `down` from Kubernetes YAML |
| Buildah | l1 | `buildah/l1-build-oci-images` | `buildah build` and the imperative `from/run/copy/config/commit` API |
| Buildah | l2 | `buildah/l2-scratch-minimal-images` | `FROM scratch` image from a static binary |
| Buildah | l3 | `buildah/l3-multi-arch-builds` | amd64 + arm64 manifest list in one command |
| Buildah | l-max | `buildah/l-max-buildah-scripts` | a whole image built from shell, no Dockerfile |
| Buildpacks | l1 | `buildpacks/l1-auto-detect-build` | `pack build` with a pinned Paketo builder |
| Buildpacks | l2 | `buildpacks/l2-custom-buildpack` | writing a buildpack (API 0.10): detect, build, layers, launch process |
| Buildpacks | l-max | `buildpacks/l-max-builder-composition` | `builder.toml`: pinned lifecycle, buildpacks, order, build/run images |

The levels are not the same height for each tool (Podman and Buildah have no l5):
a level exists only where there is something worth teaching and testing.

## Run a level locally

Docker examples (Docker with BuildKit/buildx; current Docker 29 tested):

```bash
docker build -t go-scratch docker/l2-multi-stage-builds/go-scratch   # context = that directory
docker run --rm -p 8080:8080 go-scratch

# secret mount: the token file is available during `npm ci` and absent from the image
docker build --secret id=npmrc,src=$HOME/.npmrc -t node-secret docker/l3-buildkit-advanced/node-secret-and-cache

# real multi-arch (push to a registry; needs QEMU only to RUN the arm64 image)
docker buildx build --platform linux/amd64,linux/arm64 -t REGISTRY/go-multiarch --push docker/l3-buildkit-advanced/go-multiarch

# l4: build the base, then the app on top
docker build -t myorg/base-node:24 docker/l4-custom-base-images/base-node
docker build --build-arg BASE_IMAGE=myorg/base-node:24 -t derived-node docker/l4-custom-base-images/derived-node-app

# l5 (profiles: dev, prod, test)
cd docker/l5-compose-advanced
docker compose --profile dev up --build --wait
docker compose --profile test run --build --rm test-runner
```

Podman / Buildah / pack scripts are plain bash and assert their own results, so a
broken setup fails loudly instead of printing success:

```bash
bash podman/l1-rootless-containers/podman-rootless-run-examples.sh
bash podman/l3-quadlet-single-container/quadlet-install-and-enable.sh   # needs a user systemd session
bash buildah/l3-multi-arch-builds/buildah-manifest-multi-arch-amd64-arm64.sh
bash buildpacks/l1-auto-detect-build/pack-build-auto-detect-all-apps.sh   # needs Docker + pack
```

## Podman 6 notes (current: 6.1.4)

* **Quadlet instead of `podman generate systemd`.** `generate systemd` is
  deprecated upstream (urgent fixes only), so this repo teaches Quadlet from the
  start. Units live in `~/.config/containers/systemd/` (rootless);
  `podman quadlet install` (Podman 5.6+) puts them there, and
  `/usr/libexec/podman/quadlet -dryrun -user` validates them without installing.
  Also available: `.build`, `.image` and `.kube` units, not covered here.
* **pasta, not slirp4netns.** Podman 6.0 removed slirp4netns (and cgroups v1, CNI,
  iptables). Rootless networking is pasta; there is nothing to configure.
* Always use fully qualified image names (`docker.io/library/nginx:...`); Quadlet
  `AutoUpdate=registry` requires them.
* `quay.io/podman/stable` has no 6.x image yet, so the `podman-6` CI job builds the
  `quadlet` generator from the `v6.1.4` tag and validates every unit with it. The
  rootless runtime jobs use the Podman preinstalled on the `ubuntu-26.04` runner
  (5.7, same Quadlet syntax and the same pasta networking).

## Buildah note: OCI format drops `HEALTHCHECK`

`buildah commit` and `buildah build` default to the OCI image format, which has no
healthcheck field, so a healthcheck is silently discarded. The scripts pass
`--format docker`; CI asserts the healthcheck is present in the committed image.

## What CI checks

Workflow: `.github/workflows/ci.yml` (push, pull request, weekly on Monday 03:17 UTC,
manual). All actions are pinned to commit SHAs; Dependabot updates them, plus the
base image of every Dockerfile directory, the Compose images, and the npm, pip and
Go manifests.

| Job | What runs |
|---|---|
| lint | hadolint on every Dockerfile, shellcheck on every script (including the buildpack `bin/` scripts), yamllint, actionlint, `docker compose config` for all profiles, TOML/JSON syntax |
| docker (9 examples) | `docker buildx build` of l1-l3, then a smoke run: reachable, healthcheck becomes healthy, runs non-root. The secret example also proves the token is not in any layer, with a positive control that does leak one |
| docker l4 | build both base images, assert uid 10001 / no setuid files / UTC, build and run the derived app with `--read-only` |
| docker l-max | build the extension image, check labels, metadata and UI inside it |
| docker l3 multi-arch | QEMU + buildx push of `linux/amd64,linux/arm64` to a local registry, `imagetools inspect` manifest check, the ELF machine type of each binary, health run of both platforms (arm64 emulated) |
| compose | `up --wait` for dev and prod (2 replicas on 3000-3001, read-only fs), `/config` and `/secret-check` assertions, test profile run to completion |
| podman rootless | l1 and l2 scripts, `podman build` + rootless run of two Dockerfiles, `kube play` / `kube down` |
| podman quadlet | l3 and l4 installed with `podman quadlet install` and started with `systemctl --user`, containers healthy, port exposure checked |
| podman 6.1.4 | `quadlet` built from the v6.1.4 tag; all units pass `-dryrun` |
| buildah | l1-l3 and l-max executed; images run under Podman; the manifest list is checked for both architectures and the correct binary in each |
| buildpacks | `pack build` with the pinned Paketo builder, the custom buildpack, and a custom builder built from `builder.toml`; each resulting image is run and probed |

## Pinned versions (verify before bumping, then update here and in the files)

| Component | Version | Where |
|---|---|---|
| Node.js | 24.22.1 (Alpine 3.24) | `docker/**/Dockerfile`, `buildah/l1` |
| Go | 1.27.3 (Alpine 3.24), `go 1.27` in go.mod | `docker/**/Dockerfile`, `buildah/l2` |
| Python | 3.14.9 (Debian trixie slim) | `docker/**/Dockerfile`, `buildah/l-max` |
| Flask / gunicorn / Express | 3.1.3 / 26.2.0 / 5.3.0 | `requirements.txt`, `package.json` |
| PostgreSQL / nginx / Alpine | 18.6 / 1.30.6 / 3.24.3 | compose, Podman scripts |
| Redis | 8.8.3 | `podman/l4` |
| pack / lifecycle | 0.40.10 / 0.21.26 | CI, `builder.toml` |
| Paketo ubuntu-noble builder / build+run images | 0.0.207 / 0.0.152 | `buildpacks/**` |
| Paketo nodejs / python / go / node-engine buildpacks | 10.14.1 / 2.66.0 / 4.23.1 / 8.11.0 (pulled from Docker Hub `paketobuildpacks/*`; `gcr.io/paketo-buildpacks` now requires authentication) | `buildpacks/**` |
| Podman (Quadlet validation) | 6.1.4 | CI `podman-6` job |

Dependabot cannot see the image names inside shell scripts, Quadlet units, the
Kubernetes manifest or `builder.toml`; those are bumped by hand and caught by
the weekly CI run when a tag disappears.

## Security baseline

* Every runtime image runs as a **non-root numeric user** (scratch images too).
* Secrets never go in `ENV`, `ARG` or a layer: build-time secrets use
  `--mount=type=secret`, runtime secrets use Compose/Podman secrets or mounted files.
* Multi-stage builds ship only what runs; the l4 images additionally strip setuid
  bits, and read-only root filesystems are exercised in CI.

## Honest limits

* The Docker Desktop extension (l-max) is built and inspected in CI, but cannot be
  installed there: that needs Docker Desktop.
* arm64 images are verified by ELF header and run under QEMU emulation, not on
  arm64 hardware.
* The rootless Podman runtime jobs run on Podman 5.7 (the runner's version); Podman
  6.1.4 is covered by Quadlet validation only.
* `podman kube play` does not cover every Kubernetes field; it is a local
  convenience, not a conformance test.

## License

MIT, see [LICENSE](LICENSE).
