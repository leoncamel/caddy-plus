{ pkgs, ... }:

{
  env.BUILD_PLATFORM = "linux/amd64";

  packages = [
    pkgs.coreutils
    pkgs.curl
    pkgs.docker-client
    pkgs.git
    pkgs.jq
    pkgs.ruby
    pkgs.shellcheck
    pkgs.yq-go
  ];

  scripts.caddy-plus-build.exec = ''
    scripts/build-image.sh "$@"
  '';

  scripts.caddy-plus-check.exec = ''
    shellcheck scripts/build-image.sh scripts/smoke-test.sh scripts/verify-version.sh
    yq eval '.' .github/workflows/build-images.yml >/dev/null
    awk 'NF && $1 !~ /^#/ && $1 ~ /^v/ { print "Caddy versions must not start with v: " $1; exit 1 }' caddy-versions.txt
    while IFS= read -r version; do
      case "$version" in ""|\#*) continue ;; esac
      test -s "plugin-matrix/$version.txt"
      awk 'NF && $1 !~ /^#/ && $1 !~ /@/ { print "Plugin entries must pin a version: " $1; exit 1 }' "plugin-matrix/$version.txt"
    done < caddy-versions.txt
    echo "local checks passed"
  '';

  scripts.caddy-plus-modules.exec = ''
    CADDY_VERSION="''${CADDY_VERSION:-2.10.0}"
    IMAGE_NAME="''${IMAGE_NAME:-caddy-plus}"
    docker run --rm --platform "$BUILD_PLATFORM" "$IMAGE_NAME:caddy-$CADDY_VERSION" caddy list-modules
  '';

  scripts.caddy-plus-smoke.exec = ''
    scripts/smoke-test.sh "$@"
  '';

  scripts.caddy-plus-verify-version.exec = ''
    scripts/verify-version.sh "$@"
  '';

  enterShell = ''
    echo "Caddy Plus devenv"
    echo "  caddy-plus-check   - lint local scripts and manifests"
    echo "  caddy-plus-build   - build the local image set without pushing"
    echo "  caddy-plus-modules - list Caddy modules in caddy-plus:caddy-\$CADDY_VERSION"
    echo "  caddy-plus-smoke   - run a local Coraza WAF smoke test"
    echo "  caddy-plus-verify-version <version> - verify a Caddy/plugin matrix entry"
  '';

  enterTest = ''
    caddy-plus-check
  '';
}
