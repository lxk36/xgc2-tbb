if(DEFINED _TBB_VENDOR_EXTRAS_INCLUDED)
  return()
endif()
set(_TBB_VENDOR_EXTRAS_INCLUDED TRUE)

if(DEFINED tbb_vendor_DIR)
  get_filename_component(_TBB_VENDOR_DEVEL_PREFIX
    "${tbb_vendor_DIR}/../../.." ABSOLUTE)
elseif(DEFINED CATKIN_DEVEL_PREFIX)
  set(_TBB_VENDOR_DEVEL_PREFIX "${CATKIN_DEVEL_PREFIX}")
else()
  get_filename_component(_TBB_VENDOR_DEVEL_PREFIX
    "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)
endif()

set(TBB_VENDOR_INSTALL_DIR
  "${_TBB_VENDOR_DEVEL_PREFIX}/.tbb_vendor/install"
  CACHE PATH "oneTBB vendor installation prefix" FORCE)

set(TBB_VENDOR_INCLUDE_DIRS
  "${TBB_VENDOR_INSTALL_DIR}/include"
)

set(TBB_VENDOR_LIBRARY_DIR
  "${TBB_VENDOR_INSTALL_DIR}/lib")

set(TBB_VENDOR_LIBRARIES
  "${TBB_VENDOR_LIBRARY_DIR}/libtbb.so"
)

set(TBB_VENDOR_MALLOC_LIBRARIES
  "${TBB_VENDOR_LIBRARY_DIR}/libtbbmalloc.so"
  "${TBB_VENDOR_LIBRARY_DIR}/libtbbmalloc_proxy.so"
)

set(TBB_VENDOR_RUNTIME_LIBRARY_DIRS
  "${TBB_VENDOR_LIBRARY_DIR}"
)

macro(tbb_vendor_require)
  foreach(_tbb_vendor_include IN LISTS TBB_VENDOR_INCLUDE_DIRS)
    if(NOT EXISTS "${_tbb_vendor_include}")
      message(STATUS "tbb_vendor include path will be generated during build: ${_tbb_vendor_include}")
    endif()
  endforeach()
  foreach(_tbb_vendor_library IN LISTS TBB_VENDOR_LIBRARIES TBB_VENDOR_MALLOC_LIBRARIES)
    if(NOT EXISTS "${_tbb_vendor_library}")
      message(STATUS "tbb_vendor library will be generated during build: ${_tbb_vendor_library}")
    endif()
  endforeach()
endmacro()
