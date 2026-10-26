#!/usr/bin/env bash
# Smoke test for a built image. Works with Docker (default) or Podman:
#   ENGINE=podman .github/scripts/smoke.sh ...
# REQUIRE_HEALTHCHECK=1 makes a missing HEALTHCHECK a failure (use it for images that must define one).
#
#   smoke.sh IMAGE http PORT PATH [run args...]
#       start the image, wait for HTTP 200 on PATH, check it does not run as root,
#       and if the image defines a HEALTHCHECK wait until it reports healthy
#   smoke.sh IMAGE run EXPECTED [run args...] -- COMMAND...
#       run COMMAND in the image and check its output contains EXPECTED
set -euo pipefail

engine=${ENGINE:-docker}
image=$1
mode=$2
shift 2

case "$mode" in
  run)
    expected=$1
    shift
    run_args=()
    while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do run_args+=("$1"); shift; done
    [ "${1:-}" = "--" ] && shift
    output=$("$engine" run --rm "${run_args[@]}" "$image" "$@")
    echo "$output"
    grep -qF -- "$expected" <<<"$output" || { echo "output does not contain: $expected" >&2; exit 1; }
    ;;

  http)
    port=$1
    path=$2
    shift 2

    cid=$("$engine" run -d -p "127.0.0.1:${port}:${port}" "$@" "$image")
    cleanup() {
      echo "--- container logs ---"
      "$engine" logs "$cid" 2>&1 | head -n 25 || true
      "$engine" rm -f "$cid" >/dev/null 2>&1 || true
    }
    trap cleanup EXIT

    url="http://127.0.0.1:${port}${path}"
    for _ in $(seq 1 90); do
      if curl -fsS "$url" >/dev/null 2>&1; then
        reachable=1
        break
      fi
      if [ "$("$engine" inspect -f '{{.State.Running}}' "$cid")" != "true" ]; then
        echo "container exited before answering on $url" >&2
        exit 1
      fi
      sleep 1
    done
    [ "${reachable:-0}" = 1 ] || { echo "no HTTP 200 from $url within 90s" >&2; exit 1; }
    echo "GET $url -> 200: $(curl -fsS "$url" | head -c 120)"

    # The configured user must be set and must not be root.
    user=$("$engine" inspect -f '{{.Config.User}}' "$cid")
    echo "configured user: ${user:-<none>}"
    case "$user" in
      "" | 0 | root | 0:* | root:*) echo "container runs as root" >&2; exit 1 ;;
    esac

    # If the image defines a HEALTHCHECK, it must report healthy.
    if [ "$("$engine" inspect -f '{{if .Config.Healthcheck}}yes{{end}}' "$cid")" = "yes" ]; then
      healthy=0
      for _ in $(seq 1 60); do
        if [ "$engine" = docker ]; then
          [ "$(docker inspect -f '{{.State.Health.Status}}' "$cid")" = healthy ] && { healthy=1; break; }
        else
          podman healthcheck run "$cid" >/dev/null 2>&1 && { healthy=1; break; }
        fi
        sleep 2
      done
      [ "$healthy" = 1 ] || { echo "healthcheck never became healthy" >&2; exit 1; }
      echo "healthcheck: healthy"
    elif [ "${REQUIRE_HEALTHCHECK:-0}" = 1 ]; then
      echo "image defines no HEALTHCHECK but one is required" >&2
      exit 1
    else
      echo "image defines no HEALTHCHECK (skipped)"
    fi
    ;;

  *)
    echo "unknown mode: $mode" >&2
    exit 2
    ;;
esac
