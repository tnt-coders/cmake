#.rst:
# ConfigurePackage
# --------------
#
# CMake helper function to configure and install targets to a default location
#
# This module provides a simple and re-produceable method for configuring and
# installing targets from a CMake project. Simply list the targets you want to
# configure and install from the current project and they will be configured and
# installed in the default location. The install path can be modified by setting
# ``CMAKE_INSTALL_PREFIX`` to the desired location. If a version is specified
# for the project a default version config file will also be generated. This
# file will declare "SameMajorVersion" compatibility. After the ``install``
# phase of the project is executed, the ``find_package`` command can be used to
# import the targets into other CMake projects. Additionally a namespace may be
# specified for the package. If no namespace is provided, the default namespace
# will be the project name - <project_name>::.
#
# .. command:: configure_package
#
# Configures and installs all of the listed targets for the given project.
#
# ::
#
#     configure_package(
#       TARGETS <target>
#               [target]
#               [etc...]
#     )
#
# A namespace for the package can be specified by passing
# ``NAMESPACE [namespace]`
#
# Once the targets are installed they can easily be imported into other projects
# using the ``find_package`` command and accessed through the imported package's
# namespace.
#
# ::
#
#     find_package(<project_name> [version] REQUIRED)
#
#     target_link_libraries(target
#         <namespace>::<project_target>
#     )
#
# This function also installs all of the project's public header files (the ones
# located in the "include" folder of the project) into the
# "``CMAKE_INSTALL_PREFIX``/include" folder. By doing this, the public header
# files will be available along with the imported targets after calling
# ``find_package``.

include_guard(GLOBAL)

include(CMakePackageConfigHelpers)

function(configure_package)
    set(options)
    set(oneValueArgs NAMESPACE)
    set(multiValueArgs TARGETS)
    cmake_parse_arguments(args "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(_namespace ${PROJECT_NAME})
    if(args_NAMESPACE)
        set(_namespace ${args_NAMESPACE})
    endif()

    # Create an export package of the targets
    install(
      TARGETS ${args_TARGETS}
      EXPORT ${PROJECT_NAME}-targets
      LIBRARY DESTINATION lib
      ARCHIVE DESTINATION lib
      RUNTIME DESTINATION bin
      INCLUDES DESTINATION include
    )

    # Install the export package
    install(
      EXPORT ${PROJECT_NAME}-targets
      FILE ${PROJECT_NAME}-targets.cmake
      NAMESPACE ${_namespace}::
      DESTINATION lib/cmake/${_namespace}/${PROJECT_NAME}
    )

    # Generate a package config file configuration file
    file(
      WRITE ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake.in
        "@PACKAGE_INIT@\n"
        "include(\${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}-targets.cmake)"
    )

    # Generate the package config file
    configure_package_config_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
      INSTALL_DESTINATION lib/cmake/${_namespace}/${PROJECT_NAME}
    )

    # Gather files to be installed
    list(APPEND _install_files ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake)

    # If the project has a version specified, generate a package version file
    if (${${PROJECT_NAME}_VERSION})
        write_basic_package_version_file(${PROJECT_NAME}-config-version.cmake
          VERSION ${${PROJECT_NAME}_VERSION}
          COMPATIBILITY SameMajorVersion
        )

        list(APPEND _install_files ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake)
    endif()

    # Install config files for the project
    install(
      FILES ${_install_files}
      DESTINATION lib/cmake/${_namespace}/${PROJECT_NAME}
    )

    # Install public header files for the project
    install(
        DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/
        DESTINATION include
        FILES_MATCHING PATTERN "*.h*"
    )
endfunction()