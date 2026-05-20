#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <caddy-version>" >&2
  exit 2
fi

CADDY_VERSION="$1"
PLUGIN_MATRIX_DIR="${PLUGIN_MATRIX_DIR:-plugin-matrix}"
BUILD_PLATFORM="${BUILD_PLATFORM:-linux/amd64}"
IMAGE_NAME="${IMAGE_NAME:-caddy-plus}"

case "$CADDY_VERSION" in
  v*)
    echo "Use a plain Caddy version without v prefix: $CADDY_VERSION" >&2
    exit 1
    ;;
esac

plugin_manifest="$PLUGIN_MATRIX_DIR/$CADDY_VERSION.txt"
if [ ! -s "$plugin_manifest" ]; then
  echo "Plugin manifest not found or empty: $plugin_manifest" >&2
  exit 1
fi

awk 'NF && $1 !~ /^#/ && $1 !~ /@/ { print "Plugin entries must pin a version: " $1; exit 1 }' "$plugin_manifest"

docker manifest inspect "caddy:$CADDY_VERSION-builder-alpine" >/dev/null
docker manifest inspect "caddy:$CADDY_VERSION-alpine" >/dev/null

tmp_manifest="$(mktemp "${TMPDIR:-/tmp}/caddy-plus-version.XXXXXX")"
cleanup() {
  rm -f "$tmp_manifest"
}
trap cleanup EXIT INT TERM

printf "%s\n" "$CADDY_VERSION" > "$tmp_manifest"

VERSION_MANIFEST="$tmp_manifest" \
  CADDY_VERSION="$CADDY_VERSION" \
  IMAGE_NAME="$IMAGE_NAME" \
  BUILD_PLATFORM="$BUILD_PLATFORM" \
  PUSH_IMAGE=false \
  scripts/build-image.sh

modules="$(docker run --rm --platform "$BUILD_PLATFORM" "$IMAGE_NAME:caddy-$CADDY_VERSION" caddy list-modules)"
printf "%s\n" "$modules" | grep '^dns\.providers\.alidns$' >/dev/null
printf "%s\n" "$modules" | grep '^http\.handlers\.waf$' >/dev/null

CADDY_VERSION="$CADDY_VERSION" \
  IMAGE_NAME="$IMAGE_NAME" \
  BUILD_PLATFORM="$BUILD_PLATFORM" \
  scripts/smoke-test.sh

echo "verified Caddy $CADDY_VERSION"
