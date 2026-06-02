cmake_minimum_required(VERSION 3.0.2)
project(xgc2_tbb)

include(ExternalProject)
include(ProcessorCount)

if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

find_package(catkin REQUIRED)

set(XGC2_TBB_LOCK_FILE "${CMAKE_CURRENT_SOURCE_DIR}/tbb.lock")

function(xgc2_tbb_read_lock key default_value output_var)
  set(_value "${default_value}")
  if(EXISTS "${XGC2_TBB_LOCK_FILE}")
    file(STRINGS "${XGC2_TBB_LOCK_FILE}" _lines REGEX "^${key}=")
    if(_lines)
      list(GET _lines 0 _line)
      string(REGEX REPLACE "^${key}=" "" _value "${_line}")
    endif()
  endif()
  set(${output_var} "${_value}" PARENT_SCOPE)
endfunction()

xgc2_tbb_read_lock("TBB_REPOSITORY" "https://github.com/uxlfoundation/oneTBB.git" TBB_REPOSITORY)
xgc2_tbb_read_lock("TBB_REF" "v2021.13.0" TBB_REF)
xgc2_tbb_read_lock("TBB_SHA" "" TBB_SHA)

option(XGC2_TBB_NATIVE_TESTS
  "Configure and expose upstream oneTBB native tests"
  OFF
)
set(TBB_VENDOR_NATIVE_TESTS "${XGC2_TBB_NATIVE_TESTS}"
  CACHE BOOL "Compatibility alias for XGC2_TBB_NATIVE_TESTS" FORCE)

set(XGC2_TBB_PREFIX "${CATKIN_DEVEL_PREFIX}/.xgc2_tbb")
set(XGC2_TBB_INSTALL_PREFIX "${XGC2_TBB_PREFIX}/install")
set(XGC2_TBB_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/oneTBB")
set(XGC2_TBB_BUILD_DIR "${XGC2_TBB_PREFIX}/build/oneTBB")

ProcessorCount(_XGC2_TBB_CPU_COUNT)
if(NOT _XGC2_TBB_CPU_COUNT)
  set(_XGC2_TBB_CPU_COUNT 2)
endif()
if(DEFINED ENV{TBB_VENDOR_JOBS} AND NOT "$ENV{TBB_VENDOR_JOBS}" STREQUAL "")
  set(XGC2_TBB_JOBS "$ENV{TBB_VENDOR_JOBS}")
elseif(DEFINED ENV{XGC2_TBB_JOBS} AND NOT "$ENV{XGC2_TBB_JOBS}" STREQUAL "")
  set(XGC2_TBB_JOBS "$ENV{XGC2_TBB_JOBS}")
else()
  set(XGC2_TBB_JOBS "${_XGC2_TBB_CPU_COUNT}")
endif()

if(TBB_SHA)
  set(XGC2_TBB_GIT_TAG "${TBB_SHA}")
else()
  set(XGC2_TBB_GIT_TAG "${TBB_REF}")
endif()

ExternalProject_Add(xgc2_tbb_external
  PREFIX "${XGC2_TBB_PREFIX}"
  SOURCE_DIR "${XGC2_TBB_SOURCE_DIR}"
  BINARY_DIR "${XGC2_TBB_BUILD_DIR}"
  DOWNLOAD_COMMAND
    ${CMAKE_COMMAND} -E env
      TBB_VENDOR_GIT_REPOSITORY=${TBB_REPOSITORY}
      TBB_VENDOR_GIT_TAG=${XGC2_TBB_GIT_TAG}
      TBB_VENDOR_SOURCE_DIR=${XGC2_TBB_SOURCE_DIR}
      bash ${CMAKE_CURRENT_SOURCE_DIR}/.xgc2/scripts/fetch_tbb.sh
  UPDATE_COMMAND ""
  CMAKE_ARGS
    -DCMAKE_INSTALL_PREFIX=${XGC2_TBB_INSTALL_PREFIX}
    -DCMAKE_INSTALL_LIBDIR=lib
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=ON
    -DTBB_TEST=${XGC2_TBB_NATIVE_TESTS}
    -DTBB_EXAMPLES=OFF
    -DTBB_STRICT=OFF
    -DTBB_DISABLE_HWLOC_AUTOMATIC_SEARCH=ON
  BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target install -- -j${XGC2_TBB_JOBS}
  INSTALL_COMMAND ""
  BUILD_BYPRODUCTS
    "${XGC2_TBB_INSTALL_PREFIX}/lib/libtbb.so"
    "${XGC2_TBB_INSTALL_PREFIX}/lib/libtbbmalloc.so"
    "${XGC2_TBB_INSTALL_PREFIX}/lib/libtbbmalloc_proxy.so"
)

add_custom_target(xgc2_tbb_build ALL
  DEPENDS xgc2_tbb_external
)
add_custom_target(tbb_vendor_build DEPENDS xgc2_tbb_build)

if(XGC2_TBB_NATIVE_TESTS)
  add_custom_target(xgc2_tbb_native_tests
    COMMAND ${CMAKE_COMMAND} --build "${XGC2_TBB_BUILD_DIR}" --target test -- -j${XGC2_TBB_JOBS}
    COMMAND ${CMAKE_COMMAND} -E env
      "LD_LIBRARY_PATH=${XGC2_TBB_INSTALL_PREFIX}/lib:$ENV{LD_LIBRARY_PATH}"
      ${CMAKE_COMMAND} -E chdir "${XGC2_TBB_BUILD_DIR}"
      ${CMAKE_CTEST_COMMAND} --output-on-failure
    DEPENDS xgc2_tbb_external
    USES_TERMINAL
  )
endif()

catkin_add_env_hooks(99.xgc2_tbb SHELLS sh DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/env-hooks)

catkin_package(
  CFG_EXTRAS xgc2_tbb-extras.cmake
  EXPORTED_TARGETS xgc2_tbb_external xgc2_tbb_build
)

install(CODE "
  foreach(path
      \"${XGC2_TBB_INSTALL_PREFIX}/include/oneapi/tbb\"
      \"${XGC2_TBB_INSTALL_PREFIX}/lib/libtbb.so\"
      \"${XGC2_TBB_INSTALL_PREFIX}/lib/libtbbmalloc.so\"
      \"${XGC2_TBB_INSTALL_PREFIX}/lib/libtbbmalloc_proxy.so\")
    if(NOT EXISTS \"\${path}\")
      message(FATAL_ERROR \"xgc2_tbb expected build artifact is missing: \${path}\")
    endif()
  endforeach()
")

install(DIRECTORY "${XGC2_TBB_INSTALL_PREFIX}/"
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/oneTBB
  USE_SOURCE_PERMISSIONS
)

install(DIRECTORY cmake/
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/cmake
)

install(FILES README.md tbb.lock
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
)
