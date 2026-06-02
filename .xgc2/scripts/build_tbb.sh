#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"

prefix="${XGC2_TBB_PREFIX:-/opt/xgc2/tbb}"
stage_dir="${XGC2_TBB_STAGE_DIR:-${repo_root}/.ci/stage}"
source_dir="${XGC2_TBB_SOURCE_DIR:-${repo_root}/third_party/oneTBB}"
build_dir="${XGC2_TBB_BUILD_DIR:-${repo_root}/.ci/build/oneTBB}"
install_prefix="${stage_dir}${prefix}"
jobs="${XGC2_TBB_JOBS:-${TBB_VENDOR_JOBS:-2}}"

read_lock() {
  local key="$1"
  local default_value="$2"
  local value="${default_value}"
  if [[ -f "${repo_root}/tbb.lock" ]]; then
    value="$(sed -n "s/^${key}=//p" "${repo_root}/tbb.lock" | head -n 1)"
  fi
  if [[ -z "${value}" ]]; then
    value="${default_value}"
  fi
  printf '%s' "${value}"
}

tbb_repository="$(read_lock TBB_REPOSITORY https://github.com/uxlfoundation/oneTBB.git)"
tbb_ref="$(read_lock TBB_REF v2021.13.0)"
tbb_sha="$(read_lock TBB_SHA '')"
tbb_git_tag="${tbb_sha:-${tbb_ref}}"

rm -rf "${stage_dir}" "${build_dir}"
mkdir -p "${stage_dir}" "${build_dir}" "$(dirname "${source_dir}")"

TBB_VENDOR_GIT_REPOSITORY="${tbb_repository}" \
TBB_VENDOR_GIT_TAG="${tbb_git_tag}" \
TBB_VENDOR_SOURCE_DIR="${source_dir}" \
  bash "${script_dir}/fetch_tbb.sh"

cmake \
  -S "${source_dir}" \
  -B "${build_dir}" \
  -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DTBB_TEST=OFF \
  -DTBB_EXAMPLES=OFF \
  -DTBB_STRICT=OFF \
  -DTBB_DISABLE_HWLOC_AUTOMATIC_SEARCH=ON

cmake --build "${build_dir}" --target install -- -j"${jobs}"

cat > "${install_prefix}/setup.bash" <<'SH'
#!/usr/bin/env bash
export XGC2_TBB_ROOT="/opt/xgc2/tbb"
export XGC2_TBB_INSTALL_DIR="${XGC2_TBB_ROOT}"
export XGC2_TBB_INSTALL_PREFIX="${XGC2_TBB_ROOT}"
export XGC2_TBB_INCLUDE_DIRS="${XGC2_TBB_ROOT}/include"
export XGC2_TBB_LIBRARY_DIR="${XGC2_TBB_ROOT}/lib"
export XGC2_TBB_LIBRARY_DIRS="${XGC2_TBB_ROOT}/lib"
export LD_LIBRARY_PATH="${XGC2_TBB_ROOT}/lib:${LD_LIBRARY_PATH:-}"
export CMAKE_PREFIX_PATH="${XGC2_TBB_ROOT}:${CMAKE_PREFIX_PATH:-}"
SH

chmod 0755 "${install_prefix}/setup.bash"

test -d "${install_prefix}/include/oneapi/tbb"
test -f "${install_prefix}/lib/libtbb.so"
test -f "${install_prefix}/lib/libtbbmalloc.so"
test -f "${install_prefix}/lib/libtbbmalloc_proxy.so"
