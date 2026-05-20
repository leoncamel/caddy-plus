# Caddy Plus

Caddy Plus defines a reproducible set of Caddy images with project-approved plugins across supported Caddy release lines.

## Language

**Caddy Version Matrix**:
The set of Caddy v2 versions for which both official alpine builder and alpine runtime images exist. Versions outside that pairable v2 alpine image set are not part of the build target.
_Avoid_: all historical Caddy versions, every tag

**Version Manifest**:
The repository-owned list that defines which Caddy versions belong to the Caddy Version Matrix for builds. The build scope comes from this manifest rather than live registry discovery during each pipeline run.
_Avoid_: dynamic tag scan, registry scrape

**Image Publication Target**:
The registry location where Caddy Plus images are published after a successful build. The default target is GitHub Container Registry for this repository.
_Avoid_: Docker Hub, non-GHCR registry

**Official Caddy Base Image**:
The Docker Hub Caddy image used as the builder and runtime base for Caddy Plus images. Caddy Plus does not use a third-party registry mirror as its canonical base image source.
_Avoid_: mirrored Caddy image, private base image

**Image Version Tag**:
The immutable image tag that identifies a Caddy Plus image for one Caddy version. It includes the Caddy version and may include the alpine suffix; it does not use `latest`.
_Avoid_: latest, floating tag

**Image Identity**:
The metadata that identifies what a Caddy Plus image contains, including its Caddy version, source revision, and Versioned Plugin Set. Image Identity is visible through image labels.
_Avoid_: undocumented image contents, implicit identity

**Build Platform**:
The target operating system and CPU architecture for a Caddy Plus image. The initial Build Platform is `linux/amd64` only.
_Avoid_: multi-arch by default, implicit platform

**Release Build**:
A build run that publishes Caddy Plus images to the Image Publication Target. Release Builds are explicit runs, such as release/tag pipelines or manual pipelines, rather than every ordinary source change.
_Avoid_: default push build, every commit publishes

**Supported Image Set**:
The complete set of Caddy Plus images promised by the current Version Manifest, Versioned Plugin Sets, and Build Platform. A Release Build succeeds only when every image in this set is built and published.
_Avoid_: partial release, best-effort matrix

**Versioned Plugin Set**:
The pinned Caddy plugin module versions selected for one Caddy version. Each Caddy version in the Version Manifest has exactly one Versioned Plugin Set.
_Avoid_: global plugin set, floating plugin version

**Plugin Update**:
An explicit repository change that revises the pinned module versions in one or more Versioned Plugin Sets. Plugin Updates are separate from Release Builds.
_Avoid_: automatic plugin refresh during release

## Example Dialogue

Developer: Should the pipeline build Caddy v1 tags too?

Domain expert: No. The Caddy Version Matrix only includes Caddy v2 versions with matching alpine builder and runtime images.

Developer: Can the pipeline discover new Caddy tags every time it runs?

Domain expert: No. The Version Manifest is the source of truth for build scope.

Developer: Should we use a private mirror for the Caddy base images?

Domain expert: No. Caddy Plus uses the Official Caddy Base Image.

Developer: Can consumers pull `latest`?

Domain expert: No. Consumers choose a specific Image Version Tag so the Caddy version is explicit.

Developer: How do we know which plugins are inside an image?

Domain expert: The Image Identity records the Caddy version and Versioned Plugin Set through image labels.

Developer: Does each Image Version Tag include arm64 too?

Domain expert: No. The initial Build Platform is linux/amd64.

Developer: Does every pull request publish the whole image matrix?

Domain expert: No. Publishing happens through a Release Build.

Developer: Can a release pass if one old version fails?

Domain expert: No. The Supported Image Set is all-or-nothing for a Release Build.

Developer: Can older Caddy versions use older plugin versions?

Domain expert: Yes. Each Caddy version has its own Versioned Plugin Set, so plugin versions can move at the pace each Caddy version can support.

Developer: Can plugin versions float to whatever is newest at build time?

Domain expert: No. Every Versioned Plugin Set pins module versions so the Supported Image Set is reproducible.

Developer: Can a Release Build update a Versioned Plugin Set before publishing?

Domain expert: No. A Plugin Update is a separate repository change.
