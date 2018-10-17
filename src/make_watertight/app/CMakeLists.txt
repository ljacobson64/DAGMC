set(LINK_LIBS makeWatertight)
set(LINK_LIBS_EXTERN_NAMES)

include_directories(${CMAKE_SOURCE_DIR}/src/make_watertight)

dagmc_install_exe(make_watertight  make_watertight.cpp  "${LINK_LIBS}" "${LINK_LIBS_EXTERN_NAMES}")
dagmc_install_exe(check_watertight check_watertight.cpp "${LINK_LIBS}" "${LINK_LIBS_EXTERN_NAMES}")
