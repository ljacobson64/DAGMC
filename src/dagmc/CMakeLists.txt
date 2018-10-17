message("")

file(GLOB SRC_FILES "*.cpp")
file(GLOB PUB_HEADERS "*.hpp")

# Configure version header
configure_file(DagMCVersion.hpp.in DagMCVersion.hpp)
list(APPEND PUB_HEADERS ${CMAKE_CURRENT_BINARY_DIR}/DagMCVersion.hpp)

set(LINK_LIBS)
set(LINK_LIBS_EXTERN_NAMES MOAB_LIBRARIES HDF5_LIBRARIES)

include_directories(${CMAKE_BINARY_DIR}/src/dagmc)

dagmc_install_library(dagmc "${SRC_FILES}" "${PUB_HEADERS}" "${LINK_LIBS}" "${LINK_LIBS_EXTERN_NAMES}")

add_subdirectory(tools)

if (BUILD_TESTS)
  add_subdirectory(tests)
endif ()
