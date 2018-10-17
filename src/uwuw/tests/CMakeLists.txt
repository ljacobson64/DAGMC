set(DRIVERS uwuw_unit_test_driver.cpp)

set(LINK_LIBS uwuw)
set(LINK_LIBS_EXTERN_NAMES)

include_directories(${GTEST_INCLUDE_DIR})
include_directories(${CMAKE_SOURCE_DIR}/src/pyne)
include_directories(${CMAKE_SOURCE_DIR}/src/uwuw)

dagmc_install_test(uwuw_unit_tests              cpp "${DRIVERS}" "${LINK_LIBS}" "${LINK_LIBS_EXTERN_NAMES}")
dagmc_install_test(uwuw_unit_tests_tally        cpp "${DRIVERS}" "${LINK_LIBS}" "${LINK_LIBS_EXTERN_NAMES}")
dagmc_install_test(uwuw_unit_tests_preprocessor cpp "${DRIVERS}" "${LINK_LIBS}" "${LINK_LIBS_EXTERN_NAMES}")

dagmc_install_test_file(test_uwuw.h5m)
dagmc_install_test_file(mat_lib.h5)
dagmc_install_test_file(dag_file.h5m)
