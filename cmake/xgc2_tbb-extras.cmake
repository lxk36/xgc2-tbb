if(DEFINED _XGC2_TBB_EXTRAS_INCLUDED)
  return()
endif()
set(_XGC2_TBB_EXTRAS_INCLUDED TRUE)

if(DEFINED xgc2_tbb_DIR)
  get_filename_component(_XGC2_TBB_PREFIX
    "${xgc2_tbb_DIR}/../../.." ABSOLUTE)
elseif(DEFINED CATKIN_DEVEL_PREFIX)
  set(_XGC2_TBB_PREFIX "${CATKIN_DEVEL_PREFIX}")
else()
  get_filename_component(_XGC2_TBB_PREFIX
    "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)
endif()

if(EXISTS "${_XGC2_TBB_PREFIX}/.xgc2_tbb/install")
  set(_XGC2_TBB_DEFAULT_ROOT "${_XGC2_TBB_PREFIX}/.xgc2_tbb/install")
else()
  set(_XGC2_TBB_DEFAULT_ROOT "${_XGC2_TBB_PREFIX}/share/xgc2_tbb/oneTBB")
endif()

set(XGC2_TBB_ROOT
  "${_XGC2_TBB_DEFAULT_ROOT}"
  CACHE PATH "xgc2 oneTBB installation root" FORCE)
set(XGC2_TBB_INSTALL_DIR "${XGC2_TBB_ROOT}")
set(XGC2_TBB_INSTALL_PREFIX "${XGC2_TBB_ROOT}")

set(XGC2_TBB_INCLUDE_DIRS
  "${XGC2_TBB_ROOT}/include"
)

set(XGC2_TBB_LIBRARY_DIR
  "${XGC2_TBB_ROOT}/lib")
set(XGC2_TBB_LIBRARY_DIRS
  "${XGC2_TBB_LIBRARY_DIR}")

set(XGC2_TBB_LIBRARIES
  "${XGC2_TBB_LIBRARY_DIR}/libtbb.so"
)

set(XGC2_TBB_MALLOC_LIBRARIES
  "${XGC2_TBB_LIBRARY_DIR}/libtbbmalloc.so"
  "${XGC2_TBB_LIBRARY_DIR}/libtbbmalloc_proxy.so"
)

set(XGC2_TBB_RUNTIME_LIBRARY_DIRS
  "${XGC2_TBB_LIBRARY_DIR}"
)

macro(xgc2_tbb_require)
  foreach(_xgc2_tbb_include IN LISTS XGC2_TBB_INCLUDE_DIRS)
    if(NOT EXISTS "${_xgc2_tbb_include}")
      message(STATUS "xgc2_tbb include path will be generated during build: ${_xgc2_tbb_include}")
    endif()
  endforeach()
  foreach(_xgc2_tbb_library IN LISTS XGC2_TBB_LIBRARIES XGC2_TBB_MALLOC_LIBRARIES)
    if(NOT EXISTS "${_xgc2_tbb_library}")
      message(STATUS "xgc2_tbb library will be generated during build: ${_xgc2_tbb_library}")
    endif()
  endforeach()
endmacro()

set(TBB_VENDOR_INSTALL_DIR "${XGC2_TBB_ROOT}")
set(TBB_VENDOR_INCLUDE_DIRS "${XGC2_TBB_INCLUDE_DIRS}")
set(TBB_VENDOR_LIBRARY_DIR "${XGC2_TBB_LIBRARY_DIR}")
set(TBB_VENDOR_LIBRARY_DIRS "${XGC2_TBB_LIBRARY_DIRS}")
set(TBB_VENDOR_LIBRARIES "${XGC2_TBB_LIBRARIES}")
set(TBB_VENDOR_MALLOC_LIBRARIES "${XGC2_TBB_MALLOC_LIBRARIES}")
set(TBB_VENDOR_RUNTIME_LIBRARY_DIRS "${XGC2_TBB_RUNTIME_LIBRARY_DIRS}")

macro(tbb_vendor_require)
  xgc2_tbb_require()
endmacro()
