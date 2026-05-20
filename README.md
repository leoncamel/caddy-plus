# Caddy Plus

Caddy Plus builds reproducible Caddy images with pinned plugin versions per Caddy version.

## Local Development

Activate the development environment explicitly:

```sh
devenv shell
```

Common commands:

```sh
caddy-plus-check
caddy-plus-build
caddy-plus-modules
caddy-plus-smoke
```

One-shot usage is also supported:

```sh
devenv shell caddy-plus-check
devenv shell caddy-plus-build
devenv shell caddy-plus-smoke
```

## GitHub Actions

The repository builds images with GitHub Actions on `ubuntu-latest` runners and publishes release builds to GitHub Container Registry.

Images are tagged as:

```text
ghcr.io/<owner>/<repo>:caddy-<version>
ghcr.io/<owner>/<repo>:caddy-<version>-alpine
```

The workflow uses the repository `GITHUB_TOKEN`, so no extra registry secret is required for publishing to GHCR. The workflow needs `packages: write`, which is declared in the workflow file.

Build behavior:

- Pull requests and pushes to `main` run validation only.
- Git tags matching `v*` build and push the full version manifest.
- Manual `workflow_dispatch` can build the full manifest or a single `caddy_version` from `caddy-versions.txt`.
- Manual runs can set `push_images=false` for a dry build.

## Version and Plugin Matrix

- [caddy-versions.txt](./caddy-versions.txt) defines the Caddy version matrix.
- [plugin-matrix/](./plugin-matrix) defines the pinned plugin versions for each Caddy version.

Every version in the manifest must have a matching `plugin-matrix/<caddy-version>.txt` file.

Current plugin mapping:

| Caddy version | alidns | coraza-caddy |
| --- | --- | --- |
| `2.10.0` | `v1.0.29` | `v2.1.0` |
| `2.11.2` | `v1.0.29` | `v2.5.0` |
