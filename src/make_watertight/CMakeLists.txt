message("")

file(GLOB SRC_FILES "*.cpp")
file(GLOB PUB_HEADERS "*.hpp")

set(LINK_LIBS dagmc)
set(LINK_LIBS_EXTERN_NAMES)

set(INSTALL_INCLUDE_DIR_SAVE ${INSTALL_INCLUDE_DIR})
set(INSTALL_INCLUDE_DIR ${INSTALL_INCLUDE_DIR}/make_watertight)

dagmc_install_library(makeWatertight "${SRC_FILES}" "${PUB_HEADERS}" "${LINK_LIBS}" "${LINK_LIBS_EXTERN_NAMES}")

set(INSTALL_INCLUDE_DIR ${INSTALL_INCLUDE_DIR_SAVE})

add_subdirectory(app)
if (BUILD_TESTS)
  add_subdirectory(tests)
endif ()
