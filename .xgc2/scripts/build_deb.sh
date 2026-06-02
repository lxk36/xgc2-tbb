#!/usr/bin/env bash

set -euo pipefail

package_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
build_root="${XGC2_TBB_DEB_BUILD_ROOT:-${package_dir}/.ci/debbuild}"
source_dir="${build_root}/src/xgc2_tbb"
output_dir="${XGC2_TBB_DEB_OUTPUT_DIR:-${package_dir}/.ci/debs}"
ros_distro="${ROS_DISTRO:-noetic}"
os_name="${XGC2_TBB_OS_NAME:-ubuntu}"
os_version="${XGC2_TBB_OS_VERSION:-focal}"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required tool not found: $1" >&2
    exit 1
  fi
}

require_tool bloom-generate
require_tool fakeroot

if command -v rosdep >/dev/null 2>&1; then
  if ! rosdep resolve --rosdistro "${ros_distro}" catkin >/dev/null 2>&1; then
    rosdep update --rosdistro "${ros_distro}"
  fi
fi

rm -rf "${build_root}" "${output_dir}"
mkdir -p "${source_dir}" "${output_dir}"

tar \
  --exclude=.git \
  --exclude=.ci \
  --exclude=build \
  --exclude=devel \
  --exclude=install \
  --exclude=third_party/oneTBB \
  -C "${package_dir}" \
  -cf - . | tar -x -C "${source_dir}"

cd "${source_dir}"
bloom-generate rosdebian \
  --os-name "${os_name}" \
  --os-version "${os_version}" \
  --ros-distro "${ros_distro}"

# oneTBB is bundled under package share as a private ROS vendor runtime.
# The package exports env hooks and CMake extras instead of system ldconfig
# metadata, so let smoke_test_installed.sh verify the private link path.
sed -i \
  '/^override_dh_shlibdeps:/,/^override_dh_auto_install:/c\
override_dh_shlibdeps:\
	:\
\
override_dh_auto_install:' \
  debian/rules

sed -i \
  -e 's/\${shlibs:Depends}, //g' \
  -e 's/, \${shlibs:Depends}//g' \
  -e 's/\${shlibs:Depends}//g' \
  debian/control

fakeroot debian/rules binary

find "$(dirname "${source_dir}")" -maxdepth 1 -type f -name "ros-${ros_distro}-xgc2-tbb_*.deb" \
  -exec cp -v {} "${output_dir}/" \;

if ! find "${output_dir}" -maxdepth 1 -type f -name "ros-${ros_distro}-xgc2-tbb_*.deb" | grep -q .; then
  echo "No ros-${ros_distro}-xgc2-tbb deb was produced." >&2
  exit 1
fi

dpkg-deb -I "${output_dir}"/ros-"${ros_distro}"-xgc2-tbb_*.deb
echo "Debian artifacts written to ${output_dir}"
