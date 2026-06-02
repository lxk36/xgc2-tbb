#!/usr/bin/env bash

set -euo pipefail

repo="${TBB_VENDOR_GIT_REPOSITORY:?}"
tag="${TBB_VENDOR_GIT_TAG:?}"
source_dir="${TBB_VENDOR_SOURCE_DIR:?}"
max_attempts="${TBB_VENDOR_FETCH_ATTEMPTS:-5}"

retry() {
  local description="$1"
  shift
  local attempt=1
  while true; do
    if "$@"; then
      return 0
    fi
    if (( attempt >= max_attempts )); then
      echo "Failed ${description} after ${attempt} attempts." >&2
      return 1
    fi
    echo "Retrying ${description} after attempt ${attempt}/${max_attempts}..." >&2
    sleep $((attempt * 5))
    attempt=$((attempt + 1))
  done
}

source_is_ready() {
  git rev-parse --verify HEAD >/dev/null
  test "$(git rev-parse HEAD)" = "$(git rev-parse "${tag}^{commit}")"
  test -f CMakeLists.txt
  test -d include/oneapi/tbb
}

if [[ ! -d "${source_dir}/.git" ]]; then
  rm -rf "${source_dir}"
  mkdir -p "$(dirname "${source_dir}")"
  retry "clone oneTBB" git clone "${repo}" "${source_dir}"
fi

cd "${source_dir}"

if source_is_ready; then
  echo "oneTBB source already available at ${tag}; skipping fetch."
  exit 0
fi

retry "fetch oneTBB refs" git fetch --tags --force origin
retry "checkout oneTBB ${tag}" git checkout --force "${tag}"
