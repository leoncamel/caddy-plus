#!/bin/sh
set -eu

VERSION_MANIFEST="${VERSION_MANIFEST:-caddy-versions.txt}"
PLUGIN_MATRIX_DIR="${PLUGIN_MATRIX_DIR:-plugin-matrix}"
BUILD_PLATFORM="${BUILD_PLATFORM:-linux/amd64}"
PUSH_IMAGE="${PUSH_IMAGE:-false}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
BUILD_CACHE="${BUILD_CACHE:-none}"

if [ -z "${IMAGE_NAME:-}" ] && [ "${GITHUB_REPOSITORY:-}" ]; then
  IMAGE_NAME="ghcr.io/$(printf "%s" "$GITHUB_REPOSITORY" | tr "[:upper:]" "[:lower:]")"
elif [ -z "${IMAGE_NAME:-}" ] && [ "${CI_REGISTRY_IMAGE:-}" ]; then
  IMAGE_NAME="$CI_REGISTRY_IMAGE"
elif [ -z "${IMAGE_NAME:-}" ]; then
  IMAGE_NAME="caddy-plus"
fi

if [ ! -f "$VERSION_MANIFEST" ]; then
  echo "Version manifest not found: $VERSION_MANIFEST" >&2
  exit 1
fi

if [ ! -d "$PLUGIN_MATRIX_DIR" ]; then
  echo "Plugin matrix directory not found: $PLUGIN_MATRIX_DIR" >&2
  exit 1
fi

if [ "${CADDY_VERSION:-}" ]; then
  if ! awk -v selected="$CADDY_VERSION" 'NF && $1 !~ /^#/ && $1 == selected { found = 1 } END { exit found ? 0 : 1 }' "$VERSION_MANIFEST"; then
    echo "Selected Caddy version is not in $VERSION_MANIFEST: $CADDY_VERSION" >&2
    exit 1
  fi
  versions="$CADDY_VERSION"
else
  versions="$(awk 'NF && $1 !~ /^#/ { print $1 }' "$VERSION_MANIFEST")"
fi

if [ -z "$versions" ]; then
  echo "No Caddy versions selected" >&2
  exit 1
fi

revision="${GITHUB_SHA:-${CI_COMMIT_SHA:-}}"
source_url="${CI_PROJECT_URL:-}"

if [ "${GITHUB_REPOSITORY:-}" ]; then
  source_url="${GITHUB_SERVER_URL:-https://github.com}/$GITHUB_REPOSITORY"
fi

build_mode="--load"
if [ "$PUSH_IMAGE" = "true" ]; then
  build_mode="--push"
fi

case "$BUILD_CACHE" in
  none | "")
    ;;
  gha)
    if [ "$PUSH_IMAGE" != "true" ]; then
      echo "BUILD_CACHE=gha requires PUSH_IMAGE=true because the gha cache exporter is not supported with the docker --load exporter" >&2
      exit 1
    fi
    ;;
  *)
    echo "Unsupported BUILD_CACHE value: $BUILD_CACHE" >&2
    exit 1
    ;;
esac

for version in $versions; do
  case "$version" in
    v*)
      echo "Use plain Caddy versions without v prefix: $version" >&2
      exit 1
      ;;
  esac

  echo "Building Caddy Plus for Caddy $version"

  plugin_manifest="$PLUGIN_MATRIX_DIR/$version.txt"
  if [ ! -f "$plugin_manifest" ]; then
    echo "Plugin manifest not found for Caddy $version: $plugin_manifest" >&2
    exit 1
  fi

  plugin_set="$(awk 'NF && $1 !~ /^#/ { print $1 }' "$plugin_manifest" | paste -sd, -)"
  if [ -z "$plugin_set" ]; then
    echo "Plugin manifest has no plugin entries: $plugin_manifest" >&2
    exit 1
  fi

  set -- docker buildx build \
    --file "$DOCKERFILE" \
    --platform "$BUILD_PLATFORM" \
    --build-arg "CADDY_VERSION=$version" \
    --build-arg "PLUGIN_MANIFEST=$plugin_manifest" \
    --build-arg "PLUGIN_SET=$plugin_set" \
    --label "org.opencontainers.image.source=$source_url" \
    --label "org.opencontainers.image.revision=$revision" \
    --label "org.opencontainers.image.version=$version" \
    --label "org.opencontainers.image.caddy.version=$version" \
    --label "org.opencontainers.image.caddy.plugins=$plugin_set" \
    --tag "$IMAGE_NAME:caddy-$version" \
    --tag "$IMAGE_NAME:caddy-$version-alpine"

  if [ "$BUILD_CACHE" = "gha" ]; then
    set -- "$@" --cache-from type=gha --cache-to type=gha,mode=max
  fi

  set -- "$@" "$build_mode" .

  "$@"
done
