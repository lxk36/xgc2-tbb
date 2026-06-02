#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

xmllint --noout package.xml
bash -n scripts/*.sh

nested_git="$(
  find . \
    -path ./.git -prune -o \
    -path ./.ci -prune -o \
    -path ./build -prune -o \
    -path ./devel -prune -o \
    -path ./install -prune -o \
    -path ./third_party/oneTBB -prune -o \
    -name .git -print
)"
if [[ -n "${nested_git}" ]]; then
  echo "Nested .git directory found. xgc2_tbb must not vendor submodules directly." >&2
  echo "${nested_git}" >&2
  exit 1
fi

if git ls-files | grep -E '(^|/)(build|devel|install|third_party/oneTBB|\.tbb_vendor|\.xgc2_tbb)(/|$)' >/dev/null; then
  echo "Generated build/vendor artifacts are tracked." >&2
  git ls-files | grep -E '(^|/)(build|devel|install|third_party/oneTBB|\.tbb_vendor|\.xgc2_tbb)(/|$)' >&2
  exit 1
fi

required_files=(
  package.xml
  CMakeLists.txt
  tbb.lock
  .github/workflows/ci.yml
  .github/workflows/update-tbb.yml
  cmake/xgc2_tbb-extras.cmake
  cmake/tbb_vendor-extras.cmake
  env-hooks/99.xgc2_tbb.sh.develspace.in
  env-hooks/99.xgc2_tbb.sh.installspace.in
  scripts/build_deb.sh
  scripts/publish_apt_repo.sh
  scripts/publish_self_hosted_apt.sh
  scripts/smoke_test_installed.sh
)

for file in "${required_files[@]}"; do
  if [[ ! -f "${file}" ]]; then
    echo "Missing required file: ${file}" >&2
    exit 1
  fi
done

if ! grep -q '^TBB_REF=' tbb.lock; then
  echo "tbb.lock must pin TBB_REF." >&2
  exit 1
fi

if ! grep -q '<name>xgc2_tbb</name>' package.xml; then
  echo "package.xml must declare the xgc2_tbb ROS package name." >&2
  exit 1
fi

echo "xgc2_tbb package compliance checks passed."
