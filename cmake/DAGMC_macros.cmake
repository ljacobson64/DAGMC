macro (dagmc_setup_build)
  message("")

  # All DAGMC libraries
  set(DAGMC_LIBRARY_LIST dagmc pyne_dagmc uwuw dagtally makeWatertight dagsolid fludag)

  # Keep track of which libraries are installed
  set(DAGMC_LIBRARIES MOAB CACHE INTERNAL "DAGMC_LIBRARIES")

  # Default to a release build
  if (NOT CMAKE_BUILD_TYPE)
    message(STATUS "CMAKE_BUILD_TYPE not specified, defaulting to Release")
    set(CMAKE_BUILD_TYPE Release)
  endif ()
  if (NOT CMAKE_BUILD_TYPE STREQUAL "Release" AND
      NOT CMAKE_BUILD_TYPE STREQUAL "Debug" AND
      NOT CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    message(FATAL_ERROR "Specified CMAKE_BUILD_TYPE is invalid; valid options are Release, Debug, RelWithDebInfo")
  endif ()
  string(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE_UPPER)
  message(STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")

  # Installation directories
  set(INSTALL_BIN_DIR     bin)
  set(INSTALL_LIB_DIR     lib)
  set(INSTALL_INCLUDE_DIR include)
  set(INSTALL_TESTS_DIR   tests)
  set(INSTALL_TOOLS_DIR   tools)
  set(INSTALL_SHARE_DIR   share)

  # Get some environment variables
  set(ENV_USER "$ENV{USER}")
  execute_process(COMMAND hostname       OUTPUT_VARIABLE ENV_HOST OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND uname -s       OUTPUT_VARIABLE ENV_OS   OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND date +%m/%d/%y OUTPUT_VARIABLE ENV_DATE OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND date +%H:%M:%S OUTPUT_VARIABLE ENV_TIME OUTPUT_STRIP_TRAILING_WHITESPACE)

  set(CMAKE_STATIC_LIBRARY_SUFFIX ".a")
endmacro ()

macro (dagmc_setup_options)
  message("")

  option(BUILD_MCNP5       "Build DAG-MCNP5"                         OFF)
  option(BUILD_MCNP6       "Build DAG-MCNP6"                         OFF)
  option(BUILD_MCNP_PLOT   "Build DAG-MCNP5/6 with plotting support" OFF)
  option(BUILD_MCNP_OPENMP "Build DAG-MCNP5/6 with OpenMP support"   OFF)
  option(BUILD_MCNP_MPI    "Build DAG-MCNP5/6 with MPI support"      OFF)
  option(BUILD_MCNP_PYNE_SOURCE "Build DAG-MCNP5/6 with PyNE mesh source support" OFF)

  option(BUILD_GEANT4      "Build DAG-Geant4" OFF)
  option(WITH_GEANT4_UIVIS "Build DAG-Geant4 with visualization support" ${BUILD_GEANT4})

  option(BUILD_FLUKA "Build FluDAG" OFF)

  option(BUILD_UWUW "Build UWUW library and uwuw_preproc" ON)
  option(BUILD_TALLY "Build dagtally library"              ON)

  option(BUILD_BUILD_OBB       "Build build_obb tool"       ON)
  option(BUILD_MAKE_WATERTIGHT "Build make_watertight tool" ON)
  option(BUILD_OVERLAP_CHECK "Build overlap_check tool" ON)

  option(BUILD_TESTS    "Build unit tests" ON)
  option(BUILD_CI_TESTS "Build everything needed to run the CI tests" OFF)

  option(BUILD_SHARED_LIBS "Build shared libraries" ON)
  option(BUILD_STATIC_LIBS "Build static libraries" ON)

  option(BUILD_STATIC_EXE "Build static executables" OFF)
  option(BUILD_PIC        "Build with PIC"           OFF)

  option(BUILD_RPATH "Build libraries and executables with RPATH" ON)

  option(DOUBLE_DOWN "Enable ray tracing with Embree via double down" OFF)

  if (BUILD_ALL)
    set(BUILD_MCNP5  ON)
    set(BUILD_MCNP6  ON)
    set(BUILD_GEANT4 ON)
    set(BUILD_FLUKA  ON)
  endif ()

  if (DOUBLE_DOWN AND BUILD_STATIC_LIBS)
    message(WARNING "DOUBLE_DOWN is enabled but will only be applied to the shared DAGMC library")
  endif()

  if (DOUBLE_DOWN AND BUILD_STATIC_EXE)
    message(WARNING "DOUBLE_DOWN is enabled but will only be applied to executables using the DAGMC shared library")
  endif()

if (DOUBLE_DOWN)
  find_package(DOUBLE_DOWN REQUIRED)
endif()


  if (NOT BUILD_STATIC_LIBS AND BUILD_STATIC_EXE)
    message(FATAL_ERROR "BUILD_STATIC_EXE cannot be ON while BUILD_STATIC_LIBS is OFF")
  endif ()
  if (NOT BUILD_SHARED_LIBS AND NOT BUILD_STATIC_EXE)
    message(FATAL_ERROR "BUILD_STATIC_EXE cannot be OFF while BUILD_SHARED_LIBS is OFF")
  endif ()
  if (NOT BUILD_SHARED_LIBS AND NOT BUILD_STATIC_LIBS)
    message(FATAL_ERROR "BUILD_SHARED_LIBS and BUILD_STATIC_LIBS cannot both be OFF")
  endif ()
endmacro ()

macro (dagmc_setup_flags)
  message("")

  set(CMAKE_CXX_STANDARD 11)

  if (BUILD_PIC)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
  endif ()

  set(CXX_LIBRARY)
  foreach (library IN LISTS CMAKE_CXX_IMPLICIT_LINK_LIBRARIES)
    if (library MATCHES "c\\+\\+")
      set(CXX_LIBRARY ${library})
      break()
    endif ()
  endforeach ()

  set(CMAKE_C_IMPLICIT_LINK_LIBRARIES         "")
  set(CMAKE_C_IMPLICIT_LINK_DIRECTORIES       "")
  set(CMAKE_CXX_IMPLICIT_LINK_LIBRARIES       "${CXX_LIBRARY}")
  set(CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES     "")
  set(CMAKE_Fortran_IMPLICIT_LINK_LIBRARIES   "")
  set(CMAKE_Fortran_IMPLICIT_LINK_DIRECTORIES "")

  if (BUILD_STATIC_EXE)
    message(STATUS "Building static executables")
    set(BUILD_SHARED_EXE OFF)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_STATIC_LIBRARY_SUFFIX})
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
    set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS)
    set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS)
    set(CMAKE_SHARED_LIBRARY_LINK_Fortran_FLAGS)
    set(CMAKE_EXE_LINK_DYNAMIC_C_FLAGS)
    set(CMAKE_EXE_LINK_DYNAMIC_CXX_FLAGS)
    set(CMAKE_EXE_LINK_DYNAMIC_Fortran_FLAGS)
  else ()
    message(STATUS "Building shared executables")
    set(BUILD_SHARED_EXE ON)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_SHARED_LIBRARY_SUFFIX})
  endif ()

  if (BUILD_RPATH)
    if (CMAKE_INSTALL_RPATH)
      set(INSTALL_RPATH_DIRS "${CMAKE_INSTALL_RPATH}:${CMAKE_INSTALL_PREFIX}/${INSTALL_LIB_DIR}")
    else ()
      set(INSTALL_RPATH_DIRS "${CMAKE_INSTALL_PREFIX}/${INSTALL_LIB_DIR}")
    endif ()
    message(STATUS "INSTALL_RPATH_DIRS: ${INSTALL_RPATH_DIRS}")
  endif ()

  message(STATUS "CMAKE_C_FLAGS: ${CMAKE_C_FLAGS}")
  message(STATUS "CMAKE_CXX_FLAGS: ${CMAKE_CXX_FLAGS}")
  message(STATUS "CMAKE_Fortran_FLAGS: ${CMAKE_Fortran_FLAGS}")
  message(STATUS "CMAKE_C_FLAGS_${CMAKE_BUILD_TYPE_UPPER}: ${CMAKE_C_FLAGS_${CMAKE_BUILD_TYPE_UPPER}}")
  message(STATUS "CMAKE_CXX_FLAGS_${CMAKE_BUILD_TYPE_UPPER}: ${CMAKE_CXX_FLAGS_${CMAKE_BUILD_TYPE_UPPER}}")
  message(STATUS "CMAKE_Fortran_FLAGS_${CMAKE_BUILD_TYPE_UPPER}: ${CMAKE_Fortran_FLAGS_${CMAKE_BUILD_TYPE_UPPER}}")
  message(STATUS "CMAKE_C_IMPLICIT_LINK_LIBRARIES: ${CMAKE_C_IMPLICIT_LINK_LIBRARIES}")
  message(STATUS "CMAKE_CXX_IMPLICIT_LINK_LIBRARIES: ${CMAKE_CXX_IMPLICIT_LINK_LIBRARIES}")
  message(STATUS "CMAKE_Fortran_IMPLICIT_LINK_LIBRARIES: ${CMAKE_Fortran_IMPLICIT_LINK_LIBRARIES}")
  message(STATUS "CMAKE_EXE_LINKER_FLAGS: ${CMAKE_EXE_LINKER_FLAGS}")
endmacro ()

# Setup the configuration file and install
macro (dagmc_make_configure_files)
  message("")
  message(STATUS "DAGMC cmake config file: ${CMAKE_INSTALL_PREFIX}/${INSTALL_LIB_DIR}/cmake/DAGMCConfig.cmake")
  message(STATUS "DAGMC cmake version file: ${CMAKE_INSTALL_PREFIX}/${INSTALL_LIB_DIR}/cmake/DAGMCConfigVersion.cmake")
  configure_file(cmake/DAGMCConfig.cmake.in DAGMCConfig.cmake @ONLY)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/DAGMCConfig.cmake DESTINATION ${INSTALL_LIB_DIR}/cmake/)
  configure_file(cmake/DAGMCConfigVersion.cmake.in DAGMCConfigVersion.cmake @ONLY)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/DAGMCConfigVersion.cmake DESTINATION ${INSTALL_LIB_DIR}/cmake/)
  install(EXPORT DAGMCTargets DESTINATION ${INSTALL_LIB_DIR}/cmake/)
endmacro ()

# Figure out what _link_libs_shared and _link_libs_static should be based on the
# values of _link_libs and _link_libs_extern_names
macro (dagmc_get_link_libs _link_libs _link_libs_extern_names)
  set(_link_libs_shared)
  set(_link_libs_static)

  foreach (extern_name IN ITEMS ${_link_libs_extern_names})
    list(APPEND _link_libs_shared ${${extern_name}_SHARED})
    list(APPEND _link_libs_static ${${extern_name}_STATIC})
  endforeach ()

  foreach (link_lib IN ITEMS ${_link_libs})
    list(FIND DAGMC_LIBRARY_LIST ${link_lib} index)
    if (index STREQUAL "-1")
      list(APPEND _link_libs_shared ${link_lib})
      list(APPEND _link_libs_static ${link_lib})
    else ()
      list(APPEND _link_libs_shared ${link_lib}-shared)
      list(APPEND _link_libs_static ${link_lib}-static)
    endif ()
  endforeach ()
endmacro ()

# Install a library in both shared and static mode
macro (dagmc_install_library lib_name _src_files _pub_headers _link_libs _link_libs_extern_names)
#   _src_files: source files
#   _pub_headers: public header files
#   _link_libs: e.g. dagmc, pyne_dagmc, uwuw, lapack, gfortran
#   _link_libs_extern_names: e.g. HDF5_LIBRARIES, MOAB_LIBRARIES

  message(STATUS "Building library: ${lib_name}")

  dagmc_get_link_libs("${_link_libs}" "${_link_libs_extern_names}")

  if (BUILD_SHARED_LIBS)
    add_library(${lib_name}-shared SHARED ${_src_files})
    set_target_properties(${lib_name}-shared
      PROPERTIES OUTPUT_NAME ${lib_name}
                 PUBLIC_HEADER "${_pub_headers}")
    if (BUILD_RPATH)
      set_target_properties(${lib_name}-shared
        PROPERTIES INSTALL_RPATH "${INSTALL_RPATH_DIRS}"
                   INSTALL_RPATH_USE_LINK_PATH TRUE)
    endif ()
    message(STATUS "_link_libs_shared: ${_link_libs_shared}")
    target_link_libraries(${lib_name}-shared ${_link_libs_shared})
    if (DOUBLE_DOWN)
      target_compile_definitions(${lib_name}-shared PRIVATE DOUBLE_DOWN)
      target_link_libraries(${lib_name}-shared PUBLIC dd)
    endif()
    target_include_directories(${lib_name}-shared INTERFACE $<INSTALL_INTERFACE:${INSTALL_INCLUDE_DIR}>
                                                            ${MOAB_INCLUDE_DIRS})
    install(TARGETS ${lib_name}-shared
            EXPORT DAGMCTargets
            LIBRARY DESTINATION ${INSTALL_LIB_DIR}
            PUBLIC_HEADER DESTINATION ${INSTALL_INCLUDE_DIR})
  endif ()

  if (BUILD_STATIC_LIBS)
    add_library(${lib_name}-static STATIC ${_src_files})
    set_target_properties(${lib_name}-static
      PROPERTIES OUTPUT_NAME ${lib_name})
    if (BUILD_RPATH)
      set_target_properties(${lib_name}-static
        PROPERTIES INSTALL_RPATH "" INSTALL_RPATH_USE_LINK_PATH FALSE)
    endif ()
    target_link_libraries(${lib_name}-static ${_link_libs_static})
    target_include_directories(${lib_name}-static INTERFACE $<INSTALL_INTERFACE:${INSTALL_INCLUDE_DIR}>
                                                            ${MOAB_INCLUDE_DIRS})

    install(TARGETS ${lib_name}-static
            EXPORT DAGMCTargets
            ARCHIVE DESTINATION ${INSTALL_LIB_DIR}
            PUBLIC_HEADER DESTINATION ${INSTALL_INCLUDE_DIR})
  endif ()

  # Keep a list of all libraries being installed
  set(DAGMC_LIBRARIES ${DAGMC_LIBRARIES} ${lib_name} CACHE INTERNAL "DAGMC_LIBRARIES")
endmacro ()

# Install an executable
macro (dagmc_install_exe exe_name _src_files _link_libs _link_libs_extern_names)
#   _src_files: source files
#   _link_libs: e.g. dagmc, pyne_dagmc, uwuw, lapack, gfortran
#   _link_libs_extern_names: e.g. HDF5_LIBRARIES, MOAB_LIBRARIES

  message(STATUS "Building executable: ${exe_name}")

  dagmc_get_link_libs("${_link_libs}" "${_link_libs_extern_names}")

  add_executable(${exe_name} ${_src_files})
  if (BUILD_RPATH)
    if (BUILD_STATIC_EXE)
      set_target_properties(${exe_name}
        PROPERTIES INSTALL_RPATH ""
                   INSTALL_RPATH_USE_LINK_PATH FALSE)
      target_link_libraries(${exe_name} ${_link_libs_static})
    else ()
      set_target_properties(${exe_name}
        PROPERTIES INSTALL_RPATH "${INSTALL_RPATH_DIRS}"
                   INSTALL_RPATH_USE_LINK_PATH TRUE)
      target_link_libraries(${exe_name} PUBLIC ${_link_libs_shared})
    endif ()
  else ()
    if (BUILD_STATIC_EXE)
      target_link_libraries(${exe_name} ${_link_libs_static})
    else ()
      target_link_libraries(${exe_name} PUBLIC ${_link_libs_shared})
    endif ()
  endif ()
  install(TARGETS ${exe_name} DESTINATION ${INSTALL_BIN_DIR})
endmacro ()

# Install a unit test
macro (dagmc_install_test _test_name _ext _drivers _link_libs _link_libs_extern_names)
#   _test_name: test name
#   _ext: test name extension; for example ".cc" or ".cpp"
#   _drivers: driver source files
#   _link_libs: e.g. dagmc, pyne_dagmc, uwuw, lapack, gfortran
#   _link_libs_extern_names: e.g. HDF5_LIBRARIES, MOAB_LIBRARIES

  message(STATUS "Building unit tests: ${_test_name}")

  dagmc_get_link_libs("${_link_libs}" "${_link_libs_extern_names}")

  add_executable(${_test_name} ${_test_name}.${_ext} ${_drivers})
  target_link_libraries(${_test_name} gtest)
  if (BUILD_RPATH)
    if (BUILD_STATIC_EXE)
      set_target_properties(${_test_name}
        PROPERTIES INSTALL_RPATH ""
                   INSTALL_RPATH_USE_LINK_PATH FALSE)
      target_link_libraries(${_test_name} ${_link_libs_static})
    else ()
      set_target_properties(${_test_name}
        PROPERTIES INSTALL_RPATH "${INSTALL_RPATH_DIRS}"
                   INSTALL_RPATH_USE_LINK_PATH TRUE)
      target_link_libraries(${_test_name} ${_link_libs_shared})
    endif ()
  else ()
    if (BUILD_STATIC_EXE)
      target_link_libraries(${_test_name} ${_link_libs_static})
    else ()
      target_link_libraries(${_test_name} ${_link_libs_shared})
    endif ()
  endif ()
  install(TARGETS ${_test_name} DESTINATION ${INSTALL_TESTS_DIR})
  add_test(NAME ${_test_name} COMMAND ${_test_name})
  set_property(TEST ${_test_name} PROPERTY ENVIRONMENT "LD_LIBRARY_PATH=''")
endmacro ()

# Install a file needed for unit testing
macro (dagmc_install_test_file filename)
  install(FILES ${filename} DESTINATION ${INSTALL_TESTS_DIR})
  configure_file(${CMAKE_CURRENT_LIST_DIR}/${filename} ${CMAKE_CURRENT_BINARY_DIR}/${filename} COPYONLY)
endmacro ()
