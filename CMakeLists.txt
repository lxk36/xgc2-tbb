cmake_minimum_required(VERSION 3.0.2)
project(tbb_vendor)

include(ExternalProject)
include(ProcessorCount)

if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

find_package(catkin REQUIRED)

set(TBB_VENDOR_LOCK_FILE "${CMAKE_CURRENT_SOURCE_DIR}/tbb.lock")

function(tbb_vendor_read_lock key default_value output_var)
  set(_value "${default_value}")
  if(EXISTS "${TBB_VENDOR_LOCK_FILE}")
    file(STRINGS "${TBB_VENDOR_LOCK_FILE}" _lines REGEX "^${key}=")
    if(_lines)
      list(GET _lines 0 _line)
      string(REGEX REPLACE "^${key}=" "" _value "${_line}")
    endif()
  endif()
  set(${output_var} "${_value}" PARENT_SCOPE)
endfunction()

tbb_vendor_read_lock("TBB_REPOSITORY" "https://github.com/uxlfoundation/oneTBB.git" TBB_REPOSITORY)
tbb_vendor_read_lock("TBB_REF" "v2021.13.0" TBB_REF)
tbb_vendor_read_lock("TBB_SHA" "" TBB_SHA)

option(TBB_VENDOR_NATIVE_TESTS
  "Configure and expose upstream oneTBB native tests"
  OFF
)

set(TBB_VENDOR_PREFIX "${CATKIN_DEVEL_PREFIX}/.tbb_vendor")
set(TBB_VENDOR_INSTALL_PREFIX "${TBB_VENDOR_PREFIX}/install")
set(TBB_VENDOR_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/oneTBB")
set(TBB_VENDOR_BUILD_DIR "${TBB_VENDOR_PREFIX}/build/oneTBB")

ProcessorCount(_TBB_VENDOR_CPU_COUNT)
if(NOT _TBB_VENDOR_CPU_COUNT)
  set(_TBB_VENDOR_CPU_COUNT 2)
endif()
if(DEFINED ENV{TBB_VENDOR_JOBS} AND NOT "$ENV{TBB_VENDOR_JOBS}" STREQUAL "")
  set(TBB_VENDOR_JOBS "$ENV{TBB_VENDOR_JOBS}")
else()
  set(TBB_VENDOR_JOBS "${_TBB_VENDOR_CPU_COUNT}")
endif()

if(TBB_SHA)
  set(TBB_VENDOR_GIT_TAG "${TBB_SHA}")
else()
  set(TBB_VENDOR_GIT_TAG "${TBB_REF}")
endif()

ExternalProject_Add(tbb_vendor_external
  PREFIX "${TBB_VENDOR_PREFIX}"
  SOURCE_DIR "${TBB_VENDOR_SOURCE_DIR}"
  BINARY_DIR "${TBB_VENDOR_BUILD_DIR}"
  DOWNLOAD_COMMAND
    ${CMAKE_COMMAND} -E env
      TBB_VENDOR_GIT_REPOSITORY=${TBB_REPOSITORY}
      TBB_VENDOR_GIT_TAG=${TBB_VENDOR_GIT_TAG}
      TBB_VENDOR_SOURCE_DIR=${TBB_VENDOR_SOURCE_DIR}
      bash ${CMAKE_CURRENT_SOURCE_DIR}/scripts/fetch_tbb.sh
  UPDATE_COMMAND ""
  CMAKE_ARGS
    -DCMAKE_INSTALL_PREFIX=${TBB_VENDOR_INSTALL_PREFIX}
    -DCMAKE_INSTALL_LIBDIR=lib
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=ON
    -DTBB_TEST=${TBB_VENDOR_NATIVE_TESTS}
    -DTBB_EXAMPLES=OFF
    -DTBB_STRICT=OFF
  BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target install -- -j${TBB_VENDOR_JOBS}
  INSTALL_COMMAND ""
  BUILD_BYPRODUCTS
    "${TBB_VENDOR_INSTALL_PREFIX}/lib/libtbb.so"
    "${TBB_VENDOR_INSTALL_PREFIX}/lib/libtbbmalloc.so"
    "${TBB_VENDOR_INSTALL_PREFIX}/lib/libtbbmalloc_proxy.so"
)

add_custom_target(tbb_vendor_build ALL
  DEPENDS tbb_vendor_external
)

if(TBB_VENDOR_NATIVE_TESTS)
  add_custom_target(tbb_vendor_native_tests
    COMMAND ${CMAKE_COMMAND} --build "${TBB_VENDOR_BUILD_DIR}" --target test -- -j${TBB_VENDOR_JOBS}
    COMMAND ${CMAKE_COMMAND} -E env
      "LD_LIBRARY_PATH=${TBB_VENDOR_INSTALL_PREFIX}/lib:$ENV{LD_LIBRARY_PATH}"
      ${CMAKE_COMMAND} -E chdir "${TBB_VENDOR_BUILD_DIR}"
      ${CMAKE_CTEST_COMMAND} --output-on-failure
    DEPENDS tbb_vendor_external
    USES_TERMINAL
  )
endif()

catkin_package(
  CFG_EXTRAS tbb_vendor-extras.cmake
  EXPORTED_TARGETS tbb_vendor_external tbb_vendor_build
)

install(DIRECTORY cmake/
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/cmake
)

install(PROGRAMS
  scripts/build_tbb.sh
  scripts/check_package_compliance.sh
  scripts/fetch_tbb.sh
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)

install(FILES README.md tbb.lock
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
)
