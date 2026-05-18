# tbb_vendor

ROS1 Noetic vendor package for oneAPI Threading Building Blocks.

The package mirrors the local `acados_vendor` pattern: it pins an upstream oneTBB
version, fetches the source into a local cache, builds it with CMake, installs it
under the catkin devel space, and exports include/library paths to downstream
catkin packages.

## What This Package Owns

- Pinning the upstream oneTBB source version in `tbb.lock`.
- Fetching oneTBB into `third_party/oneTBB`.
- Building oneTBB into the catkin devel space under `.tbb_vendor/install`.
- Exporting include paths and libraries to downstream catkin packages.

It does not commit oneTBB source, upstream `.git` metadata, or build artifacts.

## Build

Inside a ROS1 workspace:

```bash
catkin_make --pkg tbb_vendor
```

The build output is generated under:

```text
devel/.tbb_vendor/
```

The upstream source cache is generated under:

```text
src/common/tbb_vendor/third_party/oneTBB/
```

For runtime linking of downstream nodes:

```bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/path/to/ws/devel/.tbb_vendor/install/lib
```

## Downstream Usage

```cmake
find_package(catkin REQUIRED COMPONENTS
  tbb_vendor
  roscpp
)

tbb_vendor_require()

include_directories(
  ${TBB_VENDOR_INCLUDE_DIRS}
)

add_executable(your_target src/main.cpp)
add_dependencies(your_target ${catkin_EXPORTED_TARGETS})
if(TARGET tbb_vendor_build)
  add_dependencies(your_target tbb_vendor_build)
endif()

target_link_libraries(your_target
  ${catkin_LIBRARIES}
  ${TBB_VENDOR_LIBRARIES}
)
```

`TBB_VENDOR_LIBRARIES` links the core oneTBB runtime. If a downstream target
explicitly uses scalable malloc, also link `${TBB_VENDOR_MALLOC_LIBRARIES}`.
