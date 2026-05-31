#!/usr/bin/env bash

set -euo pipefail

setup_file="${XGC2_TBB_SETUP:-/opt/ros/noetic/setup.bash}"
set +u
source "${setup_file}"
set -u

if [[ -n "${XGC2_TBB_OVERLAY_PREFIX:-}" ]]; then
  export CMAKE_PREFIX_PATH="${XGC2_TBB_OVERLAY_PREFIX}:${CMAKE_PREFIX_PATH:-}"
  export ROS_PACKAGE_PATH="${XGC2_TBB_OVERLAY_PREFIX}/share:${ROS_PACKAGE_PATH:-}"
fi

pkg_dir="$(rospack find xgc2_tbb)"
tbb_root="${XGC2_TBB_ROOT:-${pkg_dir}/oneTBB}"
vendor_lib="${tbb_root}/lib"

test -d "${pkg_dir}"
test -d "${tbb_root}/include/oneapi/tbb"
test -f "${vendor_lib}/libtbb.so"
test -f "${vendor_lib}/libtbbmalloc.so"
test -f "${vendor_lib}/libtbbmalloc_proxy.so"

export XGC2_TBB_ROOT="${tbb_root}"
export LD_LIBRARY_PATH="${vendor_lib}:${LD_LIBRARY_PATH:-}"

ldd "${vendor_lib}/libtbb.so" | tee /tmp/xgc2-tbb-libtbb-ldd.txt
if grep -q "not found" /tmp/xgc2-tbb-libtbb-ldd.txt; then
  exit 1
fi

probe_ws="${XGC2_TBB_SMOKE_WS:-$(mktemp -d -t xgc2-tbb-ws-XXXXXX)}"
mkdir -p "${probe_ws}/src/xgc2_tbb_link_probe/src"

cat > "${probe_ws}/src/xgc2_tbb_link_probe/package.xml" <<'XML'
<?xml version="1.0"?>
<package format="2">
  <name>xgc2_tbb_link_probe</name>
  <version>0.0.0</version>
  <description>xgc2_tbb installed package link probe.</description>
  <maintainer email="noreply@example.com">CI</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>catkin</buildtool_depend>
  <depend>xgc2_tbb</depend>
</package>
XML

cat > "${probe_ws}/src/xgc2_tbb_link_probe/CMakeLists.txt" <<'CMAKE'
cmake_minimum_required(VERSION 3.0.2)
project(xgc2_tbb_link_probe)

find_package(catkin REQUIRED COMPONENTS xgc2_tbb)
catkin_package()

add_executable(link_probe src/link_probe.cpp)
xgc2_tbb_require()
target_include_directories(link_probe PRIVATE ${XGC2_TBB_INCLUDE_DIRS})
target_link_libraries(link_probe ${XGC2_TBB_LIBRARIES})
CMAKE

cat > "${probe_ws}/src/xgc2_tbb_link_probe/src/link_probe.cpp" <<'CPP'
#include <oneapi/tbb/blocked_range.h>
#include <oneapi/tbb/parallel_reduce.h>
#include <oneapi/tbb/task_group.h>

#include <atomic>
#include <cstddef>
#include <functional>
#include <iostream>

int main()
{
  const std::size_t sum = oneapi::tbb::parallel_reduce(
      oneapi::tbb::blocked_range<std::size_t>(0, 1000),
      std::size_t{0},
      [](const oneapi::tbb::blocked_range<std::size_t> &range, std::size_t local) {
        for (std::size_t i = range.begin(); i != range.end(); ++i) {
          local += i;
        }
        return local;
      },
      std::plus<std::size_t>{});

  std::atomic<int> value{0};
  oneapi::tbb::task_group tasks;
  tasks.run([&] { value.fetch_add(1, std::memory_order_relaxed); });
  tasks.run([&] { value.fetch_add(2, std::memory_order_relaxed); });
  tasks.wait();

  if (sum != 499500 || value.load(std::memory_order_relaxed) != 3) {
    return 1;
  }

  std::cout << "xgc2_tbb link probe passed" << std::endl;
  return 0;
}
CPP

cd "${probe_ws}"
catkin_make
"${probe_ws}/devel/lib/xgc2_tbb_link_probe/link_probe"

echo "xgc2_tbb installed smoke test passed."
