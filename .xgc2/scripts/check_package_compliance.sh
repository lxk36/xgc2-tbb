#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${repo_root}"

bash -n .xgc2/scripts/*.sh

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
  echo "Nested .git directory found. xgc2-tbb must not vendor submodules directly." >&2
  echo "${nested_git}" >&2
  exit 1
fi

if git ls-files | grep -E '(^|/)(build|devel|install|third_party/oneTBB|\.tbb_vendor|\.xgc2_tbb)(/|$)' >/dev/null; then
  echo "Generated build/vendor artifacts are tracked." >&2
  git ls-files | grep -E '(^|/)(build|devel|install|third_party/oneTBB|\.tbb_vendor|\.xgc2_tbb)(/|$)' >&2
  exit 1
fi

required_files=(
  README.md
  tbb.lock
  .github/workflows/ci.yml
  .github/workflows/release.yml
  .xgc2/product.yml
  .xgc2/scripts/build_deb.sh
  .xgc2/scripts/build_tbb.sh
  .xgc2/scripts/fetch_tbb.sh
  .xgc2/scripts/smoke_test_installed.sh
)

for file in "${required_files[@]}"; do
  if [[ ! -f "${file}" ]]; then
    echo "Missing required file: ${file}" >&2
    exit 1
  fi
done

for removed_file in CMakeLists.txt package.xml cmake/xgc2_tbb-extras.cmake cmake/tbb_vendor-extras.cmake; do
  if [[ -e "${removed_file}" ]]; then
    echo "master system package branch must not keep ROS/catkin file: ${removed_file}" >&2
    exit 1
  fi
done

if [[ -d env-hooks || -d cmake ]]; then
  echo "master system package branch must not keep ROS env-hook/cmake package directories." >&2
  exit 1
fi

if ! grep -q '^TBB_REF=' tbb.lock; then
  echo "tbb.lock must pin TBB_REF." >&2
  exit 1
fi

for distribution in focal jammy noble; do
  grep -q "^[[:space:]]*${distribution}: [0-9].*~${distribution}$" .xgc2/product.yml
done
grep -q 'PACKAGE_DISTRIBUTION' .xgc2/scripts/build_deb.sh
grep -q 'PACKAGE_DISTRIBUTION="${{ matrix.distribution }}"' .github/workflows/ci.yml
grep -q 'PACKAGE_DISTRIBUTION="${{ matrix.distribution }}"' .github/workflows/release.yml

echo "xgc2-tbb package compliance checks passed."
