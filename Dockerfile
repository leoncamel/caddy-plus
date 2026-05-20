# syntax=docker/dockerfile:1.7

ARG CADDY_VERSION

FROM --platform=$BUILDPLATFORM caddy:${CADDY_VERSION}-builder-alpine AS builder

ARG CADDY_VERSION

ARG PLUGIN_MANIFEST

COPY ${PLUGIN_MANIFEST} /tmp/plugin-manifest.txt

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    set -eu; \
    plugins="$(awk 'NF && $1 !~ /^#/ { printf " --with %s", $1 }' /tmp/plugin-manifest.txt)"; \
    xcaddy build "v${CADDY_VERSION}" ${plugins}

FROM caddy:${CADDY_VERSION}-alpine

ARG CADDY_VERSION
ARG PLUGIN_SET

LABEL org.opencontainers.image.title="Caddy Plus" \
      org.opencontainers.image.description="Caddy with the Caddy Plus pinned plugin set" \
      org.opencontainers.image.version="${CADDY_VERSION}" \
      org.opencontainers.image.caddy.version="${CADDY_VERSION}" \
      org.opencontainers.image.caddy.plugins="${PLUGIN_SET}"

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
