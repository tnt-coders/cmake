#[========================================================================[.rst:
tnt/Project
-------------------

This module provides simple and re-produceable methods for configuring and
installing targets from a CMake project.

Functions
^^^^^^^^^

.. command:: tnt_project_AddLibrary

  Adds a library to the project.

  .. code-block:: cmake

    tnt_project_AddLibrary(<target>
        <source_file>
        [<source_file>]
        [<etc.>]
    )

  The following variables are modified by this function:

  .. variable:: <PROJECT_NAME>_TARGETS

    This variable is updated when a library is added with this function. Any
    new targets created by ``tnt_project_AddLibrary`` will be added to the list
    stored in ``<PROJECT_NAME>_TARGETS``. ``<PROJECT_NAME>`` is defined by the
    last "project" command.

.. command:: tnt_project_Install

  Configures and installs all of the defined targets for the current project.

  .. code-block:: cmake

    tnt_project_Install()

  The install path can be modified by setting ``CMAKE_INSTALL_PREFIX`` to the
  desired location. If a version is specified for the project a default version
  config file will also be generated. This file will declare "SameMajorVersion"
  compatibility. If a namespace was defined for the project with the
  ``tnt_project_SetNamespace()`` macro, targets will be installed in the
  specified namespace. All targets defined by ``<PROJECT_NAME>_TARGETS`` will be
  installed with this function is executed.

  Once the targets are installed they can easily be imported into other projects
  using the ``find_package`` command and accessed through the imported package's
  namespace.

  .. code-block:: cmake

    find_package(<project_name> [version] REQUIRED)

    target_link_libraries(target
        [<namespace>::]<project_target>
    )

  This function also installs all of the project's public header files (the ones
  located in the "include" folder of the project) into the
  "``CMAKE_INSTALL_PREFIX``/include" folder. By doing this, the public header
  files will be available along with the imported targets after calling
  ``find_package``.

.. command:: tnt_project_SetNamespace

  Sets the namespace for the current project.

  .. code-block:: cmake

    tnt_project_SetNamespace(<namespace>)

  The namespace set by this command will be used for all other commands defined
  within this package.
#]========================================================================]

include_guard(GLOBAL)

# PackageConfigHelper functions are required to parse input arguments
include(CMakePackageConfigHelpers)

function(tnt_project_Install)

    # If a namespace was specified for the project, use it
    set(installDestination lib/cmake/${PROJECT_NAME})
    if(${PROJECT_NAME}_NAMESPACE)
        set(installDestination lib/cmake/$${{PROJECT_NAME}_NAMESPACE}/${PROJECT_NAME})
        set(installNamespace ${{PROJECT_NAME}_NAMESPACE}::)
    endif()

    # Create an export package of the targets
    install(
      TARGETS ${{PROJECT_NAME}_TARGETS}
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
      NAMESPACE ${installNamespace}
      DESTINATION ${installDestination}
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
      INSTALL_DESTINATION ${installDestination}
    )

    # Gather files to be installed
    list(APPEND installFiles ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake)

    # If the project has a version specified, generate a package version file
    if (${${PROJECT_NAME}_VERSION})
        write_basic_package_version_file(${PROJECT_NAME}-config-version.cmake
          VERSION ${${PROJECT_NAME}_VERSION}
          COMPATIBILITY SameMajorVersion
        )

        list(APPEND installFiles ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake)
    endif()

    # Install config files for the project
    install(
      FILES ${installFiles}
      DESTINATION ${installDestination}
    )

    # Install public header files for the project
    install(
        DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/
        DESTINATION include
        FILES_MATCHING PATTERN "*.h*"
    )
endfunction()

macro(tnt_project_SetNamespace)
    set(${PROJECT_NAME}_NAMESPACE ${ARGV0})
endmacro()