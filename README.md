# xgc2-tbb

This repository wraps upstream oneAPI Threading Building Blocks as a native
Debian package named `xgc2-tbb`. It is not a ROS or catkin package on the
`master` branch.

XGC2 packages should depend on this system package instead of `xgc2_tbb` or
`tbb_vendor`.

## Scope

- Pinning the upstream oneTBB source version in `tbb.lock`.
- Fetching upstream source during CI/build.
- Publishing `xgc2-tbb` for Ubuntu 20.04, 22.04, and 24.04 on amd64 and arm64.
- Installing oneTBB under `/opt/xgc2/tbb`.
- Exporting CMake variables through `xgc2_tbbConfig.cmake`.

This repository is a wrapper. It does not commit the upstream oneTBB source
tree.

## Install

```bash
sudo apt update
sudo apt install xgc2-tbb
```

Installed layout:

```text
/opt/xgc2/tbb/
/opt/xgc2/tbb/include/
/opt/xgc2/tbb/lib/
/opt/xgc2/tbb/setup.bash
/usr/lib/cmake/xgc2_tbb/xgc2_tbbConfig.cmake
/etc/ld.so.conf.d/xgc2-tbb.conf
```

## CMake Consumers

```cmake
find_package(xgc2_tbb REQUIRED CONFIG)
xgc2_tbb_require()

target_include_directories(your_target PRIVATE
  ${XGC2_TBB_INCLUDE_DIRS}
)
target_link_libraries(your_target
  ${XGC2_TBB_LIBRARIES}
)
```

The config also defines the imported target `xgc2_tbb::tbb`.

Compatibility variables are exported for old `tbb_vendor` naming:

```cmake
${TBB_VENDOR_INCLUDE_DIRS}
${TBB_VENDOR_LIBRARIES}
tbb_vendor_require()
```

## Shell Setup

```bash
source /opt/xgc2/tbb/setup.bash
```

The setup file exports `XGC2_TBB_*`, prepends `/opt/xgc2/tbb/lib` to
`LD_LIBRARY_PATH`, and prepends `/opt/xgc2/tbb` to `CMAKE_PREFIX_PATH`.

## Build Locally

```bash
./.xgc2/scripts/check_package_compliance.sh
./.xgc2/scripts/build_deb.sh
sudo apt-get install -y ./.ci/debs/xgc2-tbb_*.deb
./.xgc2/scripts/smoke_test_installed.sh
```

The GitHub CI runs the same build and smoke test inside Ubuntu 20.04, 22.04,
and 24.04 containers for amd64 and arm64, then publishes the resulting debs to
the XGC2 APT repository.

## Branches

- `master`: native system package, active branch.
- `noetic`: old ROS Noetic vendor package backup.
