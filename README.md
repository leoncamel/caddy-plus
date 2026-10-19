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
caddy-plus-verify-version 2.11.7
```

One-shot usage is also supported:

```sh
devenv test
devenv shell caddy-plus-check
devenv shell caddy-plus-build
devenv shell caddy-plus-smoke
devenv shell caddy-plus-verify-version 2.11.7
```

## GitHub Actions

The repository builds images with GitHub Actions on `ubuntu-latest` runners and publishes release builds to GitHub Container Registry. Release builds also mirror the same images to Aliyun Container Registry.
Published images support `linux/amd64` and `linux/arm64`; the `linux/arm64` variant is the native Docker platform for Apple Silicon Mac mini hosts.

Images are tagged as:

```text
ghcr.io/<owner>/<repo>:caddy-<version>
ghcr.io/<owner>/<repo>:caddy-<version>-alpine
registry.cn-beijing.aliyuncs.com/zhangxl/hello:caddy-<version>
registry.cn-beijing.aliyuncs.com/zhangxl/hello:caddy-<version>-alpine
```

The workflow uses the repository `GITHUB_TOKEN` for GHCR, so no extra secret is required there. The workflow needs `packages: write`, which is declared in the workflow file. Aliyun ACR publishing uses the repository secrets `ACR_USERNAME` and `ACR_PASSWORD`; the ACR repository is configured by `ACR_REPOSITORY` at the top of the workflow.

Build behavior:

- Pull requests and pushes to `main` run validation plus dry builds and smoke tests for the latest supported Caddy version on `linux/amd64` and `linux/arm64`.
- Git tags matching `v*` build and push the full version manifest as multi-platform images to GHCR and Aliyun ACR.
- Manual `workflow_dispatch` can build the full manifest or a single `caddy_version` from `caddy-versions.txt`.
- Manual runs default to `push_images=false` for a single-platform `linux/amd64` dry build; opt in to publishing for the full multi-platform image set.
- Published images are pulled from both GHCR and Aliyun ACR and smoke-tested after release.

Release checklist:

1. Run `devenv test`.
2. Run `devenv shell caddy-plus-verify-version <version>` for each changed matrix entry.
3. Configure the `ACR_USERNAME` and `ACR_PASSWORD` repository secrets; the ACR repository in `ACR_REPOSITORY` must already exist.
4. Push to `main` and wait for the validation and dry-build jobs to pass.
5. Create and push a tag matching `v*` to publish the full image set to GHCR and Aliyun ACR.
6. In GitHub Packages, make the GHCR package public if consumers should pull without authentication. GitHub Container Registry packages are private on first publish.
7. Pull the published tag, for example `docker pull ghcr.io/<owner>/<repo>:caddy-2.11.7` or `docker pull registry.cn-beijing.aliyuncs.com/zhangxl/hello:caddy-2.11.7`.

On Apple Silicon Mac mini hosts, Docker selects the `linux/arm64` variant automatically. To force a local build or smoke test for another platform, set `BUILD_PLATFORM`, for example:

```sh
BUILD_PLATFORM=linux/arm64 devenv shell caddy-plus-build
BUILD_PLATFORM=linux/arm64 devenv shell caddy-plus-smoke
```

## Aliyun Yunxiao

[`.yunxiao/build-images.yml`](./.yunxiao/build-images.yml) mirrors the GitHub Actions build in Aliyun Yunxiao Flow. It uses the Codeup repository as the source and publishes to the same GHCR tags.

Create a YAML pipeline in Flow, paste the file, and replace `<CODEUP_SERVICE_CONNECTION_ID>` with the Codeup service connection ID. Add the private pipeline variables `GHCR_USERNAME` and `GHCR_TOKEN` (GHCR package write access) before releasing.

Build behavior:

- Push and merge request events run validation plus an `linux/amd64` dry build and smoke test for the latest supported Caddy version.
- A tag matching `v*`, or a manual run with `PUSH_IMAGES=true`, builds and pushes the full manifest to GHCR for `linux/amd64` and `linux/arm64`.
- `BUILD_CADDY_VERSION` limits a manual run to one version from `caddy-versions.txt`.
- The pipeline uses the public Beijing build cluster with the Docker daemon enabled, installs Buildx on demand, and registers QEMU binfmt for arm64 builds.

## Version and Plugin Matrix

- [caddy-versions.txt](./caddy-versions.txt) defines the Caddy version matrix.
- [plugin-matrix/](./plugin-matrix) defines the pinned plugin versions for each Caddy version.

Every version in the manifest must have a matching `plugin-matrix/<caddy-version>.txt` file.
Use `caddy-plus-verify-version <version>` before adding or changing a matrix entry.

Current plugin mapping:

| Caddy version | alidns | coraza-caddy | caddy-l4 |
| --- | --- | --- | --- |
| `2.10.2` | `v1.0.29` | `v2.2.0` | — |
| `2.11.2` | `v1.0.29` | `v2.5.0` | — |
| `2.11.7` | `v1.0.29` | `v2.6.2` | `v0.1.2` |

## License

Apache-2.0. See [LICENSE](./LICENSE).
