# xgc2_tbb

ROS1 Noetic vendor package for the XGC2 oneAPI Threading Building Blocks
runtime. Bloom produces the Debian package name `ros-noetic-xgc2-tbb`.

The package pins an upstream oneTBB version, fetches the source into a local
cache, builds it with CMake, installs the runtime into a catkin install/share
layout, and exports include/library paths to downstream catkin packages.

## What This Package Owns

- Pinning the upstream oneTBB source version in `tbb.lock`.
- Fetching oneTBB into `third_party/oneTBB`.
- Building oneTBB into the catkin devel space under `.xgc2_tbb/install`.
- Installing oneTBB into `share/xgc2_tbb/oneTBB` for the Debian package.
- Exporting include paths and libraries to downstream catkin packages.

It does not commit oneTBB source, upstream `.git` metadata, or build artifacts.

## Build

Inside a ROS1 workspace:

```bash
catkin_make --pkg xgc2_tbb
```

The build output is generated under:

```text
devel/.xgc2_tbb/
```

The upstream source cache is generated under:

```text
src/common/tbb_vendor/third_party/oneTBB/
```

For runtime linking of downstream nodes:

```bash
source devel/setup.bash
```

## Downstream Usage

```cmake
find_package(catkin REQUIRED COMPONENTS
  xgc2_tbb
  roscpp
)

xgc2_tbb_require()

include_directories(
  ${XGC2_TBB_INCLUDE_DIRS}
)

add_executable(your_target src/main.cpp)
add_dependencies(your_target ${catkin_EXPORTED_TARGETS})
if(TARGET xgc2_tbb_build)
  add_dependencies(your_target xgc2_tbb_build)
endif()

target_link_libraries(your_target
  ${catkin_LIBRARIES}
  ${XGC2_TBB_LIBRARIES}
)
```

`XGC2_TBB_LIBRARIES` links the core oneTBB runtime. If a downstream target
explicitly uses scalable malloc, also link `${XGC2_TBB_MALLOC_LIBRARIES}`.
The old `TBB_VENDOR_*` variables and `tbb_vendor_require()` macro remain as
source-level compatibility aliases after `find_package(xgc2_tbb)`.

## Debian Package

Build the Noetic/Focal Debian package locally:

```bash
./scripts/build_deb.sh
```

The package is written under:

```text
.ci/debs/ros-noetic-xgc2-tbb_<version>_<arch>.deb
```

Install and smoke test it in a Noetic environment:

```bash
sudo apt-get install ./.ci/debs/ros-noetic-xgc2-tbb_*.deb
./scripts/smoke_test_installed.sh
```

The smoke test verifies the installed package path, checks `libtbb.so` dynamic
dependencies, builds a small catkin package against `xgc2_tbb`, and runs a
parallel oneTBB probe.

## CI And APT Publishing

`.github/workflows/ci.yml` runs package compliance, builds debs for amd64 and
arm64 in `ros:noetic-ros-base-focal`, installs the deb, runs the smoke test, and
generates a flat APT repository artifact.

To publish to a self-hosted repository on non-PR CI runs, provide these secrets:

```text
APT_REPO_HOST
APT_REPO_PORT
APT_REPO_USER
APT_REPO_SSH_KEY
APT_REPO_KNOWN_HOSTS
```

No private repository URL is hardcoded in this package.
