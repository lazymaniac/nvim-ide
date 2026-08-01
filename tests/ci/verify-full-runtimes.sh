#!/usr/bin/env bash
set -euo pipefail

require_command() {
  local executable=$1
  command -v "$executable" >/dev/null 2>&1 || {
    printf 'missing required CI executable: %s\n' "$executable" >&2
    return 1
  }
}

version_of() {
  case "$1" in
    go) go env GOVERSION | sed 's/^go//' ;;
    java) java -version 2>&1 | sed -nE '1s/.*version "?([0-9]+(\.[0-9]+){0,2}).*/\1/p' ;;
    javac) javac -version 2>&1 | sed -nE '1s/^javac ([0-9]+(\.[0-9]+){0,2}).*/\1/p' ;;
    node) node --version | sed 's/^v//' ;;
    python3) python3 -c 'import platform; print(platform.python_version())' ;;
    ruby) ruby -e 'print RUBY_VERSION' ;;
    rustc) rustc --version | sed -nE 's/^rustc ([0-9]+(\.[0-9]+){0,2}).*/\1/p' ;;
    cargo) cargo --version | sed -nE 's/^cargo ([0-9]+(\.[0-9]+){0,2}).*/\1/p' ;;
    ghc) ghc --numeric-version ;;
    cabal) cabal --numeric-version ;;
    luarocks) luarocks --version | sed -nE '1s/.* ([0-9]+(\.[0-9]+){0,2}).*/\1/p' ;;
    tree-sitter) tree-sitter --version | sed -nE '1s/.* ([0-9]+(\.[0-9]+){0,2}).*/\1/p' ;;
    *)
      printf 'no version probe for %s\n' "$1" >&2
      return 1
      ;;
  esac
}

compare_versions() {
  local actual=$1
  local boundary=$2
  local relation=$3
  python3 - "$actual" "$boundary" "$relation" <<'PY'
import re
import sys

actual, boundary, relation = sys.argv[1:]

def version(value):
    match = re.match(r"^(\d+)(?:\.(\d+))?(?:\.(\d+))?", value)
    if not match:
        raise SystemExit(f"unparseable version: {value!r}")
    return tuple(int(part or 0) for part in match.groups())

actual_version = version(actual)
boundary_version = version(boundary)
valid = actual_version >= boundary_version if relation == "minimum" else actual_version < boundary_version
if not valid:
    operator = ">=" if relation == "minimum" else "<"
    raise SystemExit(f"version requirement failed: {actual} must be {operator} {boundary}")
PY
}

assert_version() {
  local executable=$1
  local minimum=$2
  local actual
  actual="$(version_of "$executable")"
  [[ -n "$actual" ]] || {
    printf 'empty version from %s\n' "$executable" >&2
    return 1
  }
  compare_versions "$actual" "$minimum" minimum
}

assert_version_below() {
  local executable=$1
  local maximum=$2
  local actual
  actual="$(version_of "$executable")"
  [[ -n "$actual" ]] || {
    printf 'empty version from %s\n' "$executable" >&2
    return 1
  }
  compare_versions "$actual" "$maximum" maximum
}

for executable in \
  ansible ansible-playbook bash bundle cabal cc cmake curl dart flutter gem ghc ghcup git go gradle gzip \
  java javac kotlinc lua luarocks mvn ninja node npm podman psql python3 R rg ruby rustc cargo sbt \
  scala tar terraform tree-sitter unzip; do
  require_command "$executable"
done

assert_version go 1.26.0
assert_version java 21.0.0
assert_version javac 21.0.0
assert_version node 24.15.0
assert_version python3 3.10.0
assert_version_below python3 3.14.0
assert_version ruby 3.0.0
assert_version rustc 1.42.0
assert_version cargo 1.42.0
assert_version ghc 8.10.0
assert_version cabal 3.0.0
assert_version luarocks 3.0.0
assert_version tree-sitter 0.26.1

venv_root="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/nv-ide-venv.XXXXXX")"
python3 -m venv "$venv_root"
test -x "$venv_root/bin/python"
rm -rf "$venv_root"

ruby -rrbconfig -e "header = File.join(RbConfig::CONFIG.fetch('rubyhdrdir'), 'ruby.h'); exit(File.file?(header) ? 0 : 1)"

if [[ "$(uname -s)" == Darwin && "$(uname -m)" == arm64 ]]; then
  arch -x86_64 /usr/bin/true
fi

ansible --version
cmake --version
clojure -Sdescribe
dart --version
flutter --version
gradle --version
kotlinc -version
lua -v
mvn --version
ninja --version
podman --version
psql --version
R --version
sbt --script-version
scala -version
terraform version
tree-sitter --version
