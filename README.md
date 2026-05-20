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
caddy-plus-verify-version 2.11.2
```

One-shot usage is also supported:

```sh
devenv test
devenv shell caddy-plus-check
devenv shell caddy-plus-build
devenv shell caddy-plus-smoke
devenv shell caddy-plus-verify-version 2.11.2
```

## GitHub Actions

The repository builds images with GitHub Actions on `ubuntu-latest` runners and publishes release builds to GitHub Container Registry.
Published images support `linux/amd64` and `linux/arm64`; the `linux/arm64` variant is the native Docker platform for Apple Silicon Mac mini hosts.

Images are tagged as:

```text
ghcr.io/<owner>/<repo>:caddy-<version>
ghcr.io/<owner>/<repo>:caddy-<version>-alpine
```

The workflow uses the repository `GITHUB_TOKEN`, so no extra registry secret is required for publishing to GHCR. The workflow needs `packages: write`, which is declared in the workflow file.

Build behavior:

- Pull requests and pushes to `main` run validation plus dry builds and smoke tests for the latest supported Caddy version on `linux/amd64` and `linux/arm64`.
- Git tags matching `v*` build and push the full version manifest as multi-platform images.
- Manual `workflow_dispatch` can build the full manifest or a single `caddy_version` from `caddy-versions.txt`.
- Manual runs default to `push_images=false` for a single-platform `linux/amd64` dry build; opt in to publishing for the full multi-platform image set.
- Published images are pulled from GHCR and smoke-tested after release.

Release checklist:

1. Run `devenv test`.
2. Run `devenv shell caddy-plus-verify-version <version>` for each changed matrix entry.
3. Push to `main` and wait for the validation and dry-build jobs to pass.
4. Create and push a tag matching `v*` to publish the full image set.
5. In GitHub Packages, make the GHCR package public if consumers should pull without authentication. GitHub Container Registry packages are private on first publish.
6. Pull the published tag, for example `docker pull ghcr.io/<owner>/<repo>:caddy-2.11.2`.

On Apple Silicon Mac mini hosts, Docker selects the `linux/arm64` variant automatically. To force a local build or smoke test for another platform, set `BUILD_PLATFORM`, for example:

```sh
BUILD_PLATFORM=linux/arm64 devenv shell caddy-plus-build
BUILD_PLATFORM=linux/arm64 devenv shell caddy-plus-smoke
```

## Version and Plugin Matrix

- [caddy-versions.txt](./caddy-versions.txt) defines the Caddy version matrix.
- [plugin-matrix/](./plugin-matrix) defines the pinned plugin versions for each Caddy version.

Every version in the manifest must have a matching `plugin-matrix/<caddy-version>.txt` file.
Use `caddy-plus-verify-version <version>` before adding or changing a matrix entry.

Current plugin mapping:

| Caddy version | alidns | coraza-caddy |
| --- | --- | --- |
| `2.10.0` | `v1.0.29` | `v2.1.0` |
| `2.11.2` | `v1.0.29` | `v2.5.0` |

## License

Apache-2.0. See [LICENSE](./LICENSE).
