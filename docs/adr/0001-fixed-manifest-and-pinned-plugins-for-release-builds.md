# Use a fixed manifest and versioned plugin matrix for release builds

Caddy Plus release builds publish a supported image set from a repository-owned version manifest and a per-Caddy-version plugin matrix, rather than discovering Caddy tags or plugin versions at release time. This keeps GitHub Container Registry output reproducible: each release build uses GitHub Actions, official Caddy Docker Hub base images, Docker Buildx/BuildKit, the `linux/amd64` and `linux/arm64` build platforms, and all-or-nothing publication semantics for every image in the manifest.

## Considered Options

- Dynamically discover Caddy tags during each pipeline run. Rejected because the build scope would vary by registry state, network availability, and tag API behavior.
- Let plugin versions float during release builds. Rejected because the same Caddy version tag could resolve to different binaries over time.
- Use one global pinned plugin set for every Caddy version. Rejected because newer plugin releases may require newer Go toolchains or Caddy APIs than older Caddy builder images provide.
- Generate a dynamic child pipeline for every Caddy version. Deferred because the first version manifest is small and a single sequential release job is easier to audit.
- Keep the release platform at `linux/amd64` only. Rejected because Apple Silicon Mac mini hosts should run the published image natively as `linux/arm64`.

## Consequences

Adding older Caddy versions or upgrading plugins is an explicit repository change followed by verification. A release build fails if any version in the manifest lacks a matching versioned plugin set or cannot build with that pinned set.
