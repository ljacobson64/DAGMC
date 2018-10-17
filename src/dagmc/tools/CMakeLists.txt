set(LINK_LIBS dagmc)
set(LINK_LIBS_EXTERN_NAMES)

include_directories(${CMAKE_SOURCE_DIR}/src/dagmc)
include_directories(${CMAKE_BINARY_DIR}/src/dagmc)

dagmc_install_exe(pt_vol_test   pt_vol_test.cpp   "${LINK_LIBS}" "${LINK_LIBS_EXTERN_NAMES}")
dagmc_install_exe(ray_fire_test ray_fire_test.cpp "${LINK_LIBS}" "${LINK_LIBS_EXTERN_NAMES}")
dagmc_install_exe(test_geom     test_geom.cpp     "${LINK_LIBS}" "${LINK_LIBS_EXTERN_NAMES}")
