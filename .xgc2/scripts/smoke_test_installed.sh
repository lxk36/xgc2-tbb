#!/usr/bin/env bash

set -euo pipefail

tbb_root="${XGC2_TBB_ROOT:-/opt/xgc2/tbb}"
vendor_lib="${tbb_root}/lib"

test -d "${tbb_root}"
test -d "${tbb_root}/include/oneapi/tbb"
test -f "${vendor_lib}/libtbb.so"
test -f "${vendor_lib}/libtbbmalloc.so"
test -f "${vendor_lib}/libtbbmalloc_proxy.so"
test -f "${tbb_root}/setup.bash"
test -f /usr/lib/cmake/xgc2_tbb/xgc2_tbbConfig.cmake

set +u
source "${tbb_root}/setup.bash"
set -u

ldd "${vendor_lib}/libtbb.so" | tee /tmp/xgc2-tbb-libtbb-ldd.txt
if grep -q "not found" /tmp/xgc2-tbb-libtbb-ldd.txt; then
  exit 1
fi

probe_dir="${XGC2_TBB_SMOKE_DIR:-$(mktemp -d -t xgc2-tbb-smoke-XXXXXX)}"
mkdir -p "${probe_dir}"

cat > "${probe_dir}/CMakeLists.txt" <<'CMAKE'
cmake_minimum_required(VERSION 3.16)
project(xgc2_tbb_link_probe LANGUAGES CXX)

find_package(xgc2_tbb REQUIRED CONFIG)
xgc2_tbb_require()

add_executable(link_probe link_probe.cpp)
target_compile_features(link_probe PRIVATE cxx_std_17)
target_include_directories(link_probe PRIVATE ${XGC2_TBB_INCLUDE_DIRS})
target_link_libraries(link_probe ${XGC2_TBB_LIBRARIES})
CMAKE

cat > "${probe_dir}/link_probe.cpp" <<'CPP'
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

  std::cout << "xgc2-tbb link probe passed" << std::endl;
  return 0;
}
CPP

cmake -S "${probe_dir}" -B "${probe_dir}/build"
cmake --build "${probe_dir}/build" -- -j2
"${probe_dir}/build/link_probe"

echo "xgc2-tbb installed smoke test passed."
