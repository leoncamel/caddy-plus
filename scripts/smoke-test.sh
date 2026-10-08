#!/bin/sh
set -eu

IMAGE_NAME="${IMAGE_NAME:-caddy-plus}"
CADDY_VERSION="${CADDY_VERSION:-2.10.0}"
BUILD_PLATFORM="${BUILD_PLATFORM:-linux/amd64}"
CONTAINER_NAME="${CONTAINER_NAME:-caddy-plus-smoke}"
HOST_PORT="${HOST_PORT:-8080}"
SMOKE_CADDYFILE="${SMOKE_CADDYFILE:-tests/Caddyfile.smoke}"
L4_HOST_PORT="${L4_HOST_PORT:-8081}"
SMOKE_L4_CADDYFILE="${SMOKE_L4_CADDYFILE:-tests/Caddyfile.l4}"

image_tag="$IMAGE_NAME:caddy-$CADDY_VERSION"

cleanup() {
  docker rm -f "$CONTAINER_NAME" "${CONTAINER_NAME}-l4" >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

docker run --rm --platform "$BUILD_PLATFORM" \
  -v "$PWD/$SMOKE_CADDYFILE:/etc/caddy/Caddyfile:ro" \
  "$image_tag" \
  caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile

cleanup

docker run -d --platform "$BUILD_PLATFORM" \
  --name "$CONTAINER_NAME" \
  -p "$HOST_PORT:8080" \
  -v "$PWD/$SMOKE_CADDYFILE:/etc/caddy/Caddyfile:ro" \
  "$image_tag" >/dev/null

for _ in 1 2 3 4 5; do
  if curl -fsS "http://127.0.0.1:$HOST_PORT/" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

ok_body="$(curl -fsS "http://127.0.0.1:$HOST_PORT/")"
blocked_status="$(curl -sS -o /dev/null -w "%{http_code}" "http://127.0.0.1:$HOST_PORT/?test=attack")"

if [ "$ok_body" != "ok" ]; then
  echo "Expected ok response, got: $ok_body" >&2
  exit 1
fi

if [ "$blocked_status" != "403" ]; then
  echo "Expected WAF block status 403, got: $blocked_status" >&2
  exit 1
fi
modules="$(docker exec "$CONTAINER_NAME" caddy list-modules)"

if printf "%s\n" "$modules" | grep -qx 'layer4'; then
  docker run -d --platform "$BUILD_PLATFORM" \
    --name "${CONTAINER_NAME}-l4" \
    -p "$L4_HOST_PORT:9443" \
    -v "$PWD/$SMOKE_L4_CADDYFILE:/etc/caddy/Caddyfile:ro" \
    "$image_tag" >/dev/null

  for _ in 1 2 3 4 5; do
    if printf 'l4-echo-test' | nc -w 2 127.0.0.1 "$L4_HOST_PORT" | grep -q 'l4-echo-test'; then
      break
    fi
    sleep 1
  done

  l4_body="$(printf 'l4-echo-test' | nc -w 2 127.0.0.1 "$L4_HOST_PORT")"

  if [ "$l4_body" != "l4-echo-test" ]; then
    echo "Expected l4 echo response: l4-echo-test, got: $l4_body" >&2
    exit 1
  fi

  echo "l4 smoke test passed"
fi

echo "smoke test passed"
