#!/usr/bin/env bash

set -euo pipefail

package_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace_dir="${TBB_VENDOR_WS:-${package_dir}/.ci/ws}"

rm -rf "${workspace_dir}/src/tbb_vendor"
mkdir -p "${workspace_dir}/src"
cp -a "${package_dir}" "${workspace_dir}/src/tbb_vendor"
rm -rf "${workspace_dir}/src/tbb_vendor/.git"

source /opt/ros/noetic/setup.bash
cd "${workspace_dir}"
catkin_make --pkg tbb_vendor
