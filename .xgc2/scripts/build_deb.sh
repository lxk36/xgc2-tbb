#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"

package_name="xgc2-tbb"
version="${PACKAGE_VERSION:-0.1.0-1}"
prefix="${XGC2_TBB_PREFIX:-/opt/xgc2/tbb}"
stage_dir="${XGC2_TBB_STAGE_DIR:-${repo_root}/.ci/stage}"
output_dir="${XGC2_TBB_DEB_OUTPUT_DIR:-${repo_root}/.ci/debs}"
pkg_root="${repo_root}/.ci/pkg/${package_name}"
arch="$(dpkg --print-architecture)"

rm -rf "${stage_dir}" "${output_dir}" "${pkg_root}"
mkdir -p "${output_dir}"

"${script_dir}/build_tbb.sh"

mkdir -p \
  "${pkg_root}/DEBIAN" \
  "${pkg_root}/etc/ld.so.conf.d" \
  "${pkg_root}/usr/lib/cmake/xgc2_tbb" \
  "${pkg_root}/usr/share/doc/${package_name}"

cp -a "${stage_dir}/opt" "${pkg_root}/"

cat > "${pkg_root}/etc/ld.so.conf.d/xgc2-tbb.conf" <<EOF
${prefix}/lib
EOF

cat > "${pkg_root}/usr/lib/cmake/xgc2_tbb/xgc2_tbbConfig.cmake" <<'CMAKE'
if(DEFINED _XGC2_TBB_CONFIG_INCLUDED)
  return()
endif()
set(_XGC2_TBB_CONFIG_INCLUDED TRUE)

set(XGC2_TBB_ROOT "/opt/xgc2/tbb")
set(XGC2_TBB_INSTALL_DIR "${XGC2_TBB_ROOT}")
set(XGC2_TBB_INSTALL_PREFIX "${XGC2_TBB_ROOT}")

set(XGC2_TBB_INCLUDE_DIRS "${XGC2_TBB_ROOT}/include")
set(XGC2_TBB_LIBRARY_DIR "${XGC2_TBB_ROOT}/lib")
set(XGC2_TBB_LIBRARY_DIRS "${XGC2_TBB_LIBRARY_DIR}")
set(XGC2_TBB_LIBRARIES "${XGC2_TBB_LIBRARY_DIR}/libtbb.so")
set(XGC2_TBB_MALLOC_LIBRARIES
  "${XGC2_TBB_LIBRARY_DIR}/libtbbmalloc.so"
  "${XGC2_TBB_LIBRARY_DIR}/libtbbmalloc_proxy.so")
set(XGC2_TBB_RUNTIME_LIBRARY_DIRS "${XGC2_TBB_LIBRARY_DIR}")

macro(xgc2_tbb_require)
  foreach(_xgc2_tbb_include IN LISTS XGC2_TBB_INCLUDE_DIRS)
    if(NOT EXISTS "${_xgc2_tbb_include}")
      message(FATAL_ERROR "xgc2-tbb include path is missing: ${_xgc2_tbb_include}")
    endif()
  endforeach()
  foreach(_xgc2_tbb_library IN LISTS XGC2_TBB_LIBRARIES XGC2_TBB_MALLOC_LIBRARIES)
    if(NOT EXISTS "${_xgc2_tbb_library}")
      message(FATAL_ERROR "xgc2-tbb library is missing: ${_xgc2_tbb_library}")
    endif()
  endforeach()
endmacro()

if(NOT TARGET xgc2_tbb::tbb)
  add_library(xgc2_tbb::tbb SHARED IMPORTED)
  set_target_properties(xgc2_tbb::tbb PROPERTIES
    IMPORTED_LOCATION "${XGC2_TBB_LIBRARY_DIR}/libtbb.so"
    INTERFACE_INCLUDE_DIRECTORIES "${XGC2_TBB_INCLUDE_DIRS}")
endif()

set(TBB_VENDOR_INSTALL_DIR "${XGC2_TBB_ROOT}")
set(TBB_VENDOR_INCLUDE_DIRS "${XGC2_TBB_INCLUDE_DIRS}")
set(TBB_VENDOR_LIBRARY_DIR "${XGC2_TBB_LIBRARY_DIR}")
set(TBB_VENDOR_LIBRARY_DIRS "${XGC2_TBB_LIBRARY_DIRS}")
set(TBB_VENDOR_LIBRARIES "${XGC2_TBB_LIBRARIES}")
set(TBB_VENDOR_MALLOC_LIBRARIES "${XGC2_TBB_MALLOC_LIBRARIES}")
set(TBB_VENDOR_RUNTIME_LIBRARY_DIRS "${XGC2_TBB_RUNTIME_LIBRARY_DIRS}")
macro(tbb_vendor_require)
  xgc2_tbb_require()
endmacro()
CMAKE

cat > "${pkg_root}/DEBIAN/control" <<EOF
Package: ${package_name}
Version: ${version}
Section: libs
Priority: optional
Architecture: ${arch}
Maintainer: XGC2 <apt@example.com>
Depends: libc6, libgcc-s1, libstdc++6
Conflicts: ros-noetic-xgc2-tbb
Replaces: ros-noetic-xgc2-tbb
Description: XGC2 packaged oneAPI Threading Building Blocks runtime
 System-level oneTBB headers, shared libraries, setup helper, and CMake
 package configuration for XGC2 projects.
EOF

cat > "${pkg_root}/DEBIAN/postinst" <<'SH'
#!/bin/sh
set -e
if command -v ldconfig >/dev/null 2>&1; then
  ldconfig
fi
SH
cat > "${pkg_root}/DEBIAN/postrm" <<'SH'
#!/bin/sh
set -e
if command -v ldconfig >/dev/null 2>&1; then
  ldconfig
fi
SH
chmod 0755 "${pkg_root}/DEBIAN/postinst" "${pkg_root}/DEBIAN/postrm"

cp -a "${repo_root}/README.md" "${repo_root}/tbb.lock" "${pkg_root}/usr/share/doc/${package_name}/"

find "${pkg_root}" -type d -exec chmod 0755 {} +
find "${pkg_root}" -type f -exec chmod 0644 {} +
chmod 0755 "${pkg_root}/DEBIAN" "${pkg_root}/DEBIAN/postinst" "${pkg_root}/DEBIAN/postrm"
chmod 0755 "${pkg_root}${prefix}/setup.bash"

fakeroot dpkg-deb --build "${pkg_root}" "${output_dir}/${package_name}_${version}_${arch}.deb" >/dev/null
dpkg-deb -I "${output_dir}/${package_name}_${version}_${arch}.deb"
echo "Debian artifacts written to ${output_dir}"
