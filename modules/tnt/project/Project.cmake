include_guard(GLOBAL)

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

include(tnt/class/Class)
include(tnt/conan/Conan)
include(tnt/git/Git)

function(tnt_project_New args_THIS)
    tnt_class_CreateObject(tnt_project ${args_THIS})

    set(options VERSION_FROM_GIT)
    set(oneValueArgs CONANFILE NAMESPACE)
    set(multiValueArgs)
    cmake_parse_arguments(args "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Set the project name and source directory
    tnt_class_Set(tnt_project ${args_THIS} NAME ${args_THIS})
    tnt_class_Set(tnt_project ${args_THIS} BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    tnt_class_Set(tnt_project ${args_THIS} SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

    # Set member variables
    if(args_VERSION_FROM_GIT)
        tnt_class_Set(tnt_project ${args_THIS} VERSION_FROM_GIT "${args_VERSION_FROM_GIT}")
    endif()
    if(args_CONANFILE)
        tnt_class_Set(tnt_project ${args_THIS} CONANFILE "${args_CONANFILE}")
    endif()
    if(args_NAMESPACE)
        tnt_class_Set(tnt_project ${args_THIS} NAMESPACE "${args_NAMESPACE}")
    endif()

    # Define the project version
    _tnt_project_DefineVersion(${args_THIS})
endfunction()

function(tnt_project_AddExecutable args_THIS)
    tnt_class_MemberFunction(tnt_project ${args_THIS})

    set(options)
    set(oneValueArgs TARGET)
    set(multiValueArgs SOURCES)
    cmake_parse_arguments(args "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Create the executable
    add_executable(${args_TARGET} ${args_SOURCES})

    # Initialize default include directories
    tnt_class_Get(tnt_project ${args_THIS} SOURCE_DIR sourceDir)
    set(privateIncludeDir "${sourceDir}/include/${args_TARGET}")

    # Handle namespace considerations
    tnt_class_Get(tnt_project ${args_THIS} NAMESPACE namespace)
    if (namespace)
        set(privateIncludeDir "${sourceDir}/include/${namespace}/${args_TARGET}")
    endif()

    # Set default include directories
    target_include_directories(${args_TARGET}
      PRIVATE
        ${sourceDir}/include
        ${privateIncludeDir}
        ${sourceDir}/src
    )

    # Add the target to the list of project managed targets
    tnt_class_Get(tnt_project ${args_THIS} TARGETS targets)
    list(APPEND targets ${args_TARGET})
    tnt_class_Set(tnt_project ${args_THIS} TARGETS "${targets}")
endfunction()

function(tnt_project_AddLibrary args_THIS)
    tnt_class_MemberFunction(tnt_project ${args_THIS})

    set(options)
    set(oneValueArgs TARGET)
    set(multiValueArgs SOURCES)
    cmake_parse_arguments(args "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

message("unparsed: ${args_UNPARSED_ARGUMENTS}")

    # Create the library
    add_library(${args_TARGET} ${args_SOURCES} ${ARGN})

    # Handle RPATH considerations for shared libraries
    # See "Deep CMake for Library Authors" https://www.youtube.com/watch?v=m0DwB4OvDXk
    set_target_properties(${args_TARGET} PROPERTIES BUILD_RPATH_USE_ORIGIN TRUE)

    # Initialize default include directories
    tnt_class_Get(tnt_project ${args_THIS} SOURCE_DIR sourceDir)
    set(privateIncludeDir "${sourceDir}/include/${args_TARGET}")

    # Handle namespace considerations
    tnt_class_Get(tnt_project ${args_THIS} NAMESPACE namespace)
    if (namespace)
        add_library(${namespace}::${args_TARGET} ALIAS ${args_TARGET})
        set(privateIncludeDir "${sourceDir}/include/${namespace}/${args_TARGET}")
    endif()

    # Set default include directories
    target_include_directories(${args_TARGET}
      PUBLIC
        $<BUILD_INTERFACE:${sourceDir}/include>
        $<INSTALL_INTERFACE:include>
      PRIVATE
        $<BUILD_INTERFACE:${privateIncludeDir}>
        $<BUILD_INTERFACE:${sourceDir}/src>
    )

    # Add the target to the list of project managed targets
    tnt_class_Get(tnt_project ${args_THIS} TARGETS targets)
    list(APPEND targets ${args_TARGET})
    tnt_class_Set(tnt_project ${args_THIS} TARGETS "${targets}")
endfunction()

function(tnt_project_ConanInstall args_THIS)
    tnt_class_MemberFunction(tnt_project ${args_THIS})

    # Do not run conan install if we are in the local cache
    if (CONAN_EXPORTED)
        include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
        conan_basic_setup()
    endif()

    tnt_class_Get(tnt_project ${args_THIS} CONANFILE conanfile)
    conan_cmake_run(
      CONANFILE ${conanfile}
      BUILD outdated
      BASIC_SETUP
      CMAKE_TARGETS
      ${ARGN}
    )
endfunction()

function(tnt_project_Install args_THIS)
    tnt_class_MemberFunction(tnt_project ${args_THIS})

    # Set the install destination and namespace
    tnt_class_Get(tnt_project ${args_THIS} NAME name)
    tnt_class_Get(tnt_project ${args_THIS} NAMESPACE namespace)
    set(installDestination "lib/cmake/${name}")
    if(namespace)
        set(installNamespace "${namespace}::")
    endif()

    # Create an export package of the targets
    # Use GNUInstallDirs and COMPONENTS
    # See "Deep CMake for Library Authors" https://www.youtube.com/watch?v=m0DwB4OvDXk
    # TODO: Investigate why using "COMPONENTS" broke usage of the package
    tnt_class_Get(tnt_project ${args_THIS} TARGETS targets)
    install(
      TARGETS ${targets}
      EXPORT ${name}-targets
      ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        #COMPONENT ${name}_Development
      INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        #COMPONENT ${name}_Development
      LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        #COMPONENT ${name}_Runtime
        #NAMELINK_COMPONENT ${name}_Development
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        #COMPONENT ${name}_Runtime
    )

    # Install the export package
    install(
        EXPORT ${name}-targets
        FILE ${name}-targets.cmake
        NAMESPACE ${installNamespace}
        DESTINATION ${installDestination}
    )

    # Generate a package configuration file
    tnt_class_get(tnt_project ${args_THIS} BINARY_DIR binaryDir)
    file(
      WRITE ${binaryDir}/${name}-config.cmake.in
        "@PACKAGE_INIT@\n"
        "include(\${CMAKE_CURRENT_LIST_DIR}/${name}-targets.cmake)"
    )
    configure_package_config_file(
        ${binaryDir}/${name}-config.cmake.in
        ${binaryDir}/${name}-config.cmake
      INSTALL_DESTINATION ${installDestination}
    )

    # Gather files to be installed
    list(APPEND installFiles ${binaryDir}/${name}-config.cmake)

    # If the package has a version specified, generate a package version file
    tnt_class_Get(tnt_project ${args_THIS} VERSION version)
    if(version)
        write_basic_package_version_file(${name}-config-version.cmake
          VERSION ${version}
          COMPATIBILITY SameMajorVersion
        )

        list(APPEND installFiles ${binaryDir}/${name}-config-version.cmake)
    endif()

    # Install config files for the project
    install(
      FILES ${installFiles}
      DESTINATION ${installDestination}
    )

    # Install public header files for the project
    tnt_class_Get(tnt_project ${args_THIS} SOURCE_DIR sourceDir)
    install(
      DIRECTORY ${sourceDir}/include/
      DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
      FILES_MATCHING PATTERN "*.h*"
    )
endfunction()

################################################################################
# Private methods

function(_tnt_project_DefineVersion args_THIS)
    tnt_class_MemberFunction(tnt_project ${args_THIS})
    tnt_class_Get(tnt_project ${args_THIS} VERSION_FROM_GIT versionFromGit)

    if(versionFromGit)
        tnt_git_GetVersionInfo()
        tnt_class_Set(tnt_project ${args_THIS} VERSION "${GIT_VERSION}")
        tnt_class_Set(tnt_project ${args_THIS} VERSION_MAJOR "${GIT_VERSION_MAJOR}")
        tnt_class_Set(tnt_project ${args_THIS} VERSION_MINOR "${GIT_VERSION_MINOR}")
        tnt_class_Set(tnt_project ${args_THIS} VERSION_PATCH "${GIT_VERSION_PATCH}")
        tnt_class_Set(tnt_project ${args_THIS} VERSION_TWEAK "${GIT_VERSION_TWEAK}")
        tnt_class_Set(tnt_project ${args_THIS} VERSION_IS_DIRTY "${GIT_VERSION_IS_DIRTY}")
        tnt_class_Set(tnt_project ${args_THIS} VERSION_HASH "${GIT_VERSION_HASH}")
    else()
        tnt_class_Set(tnt_project ${args_THIS} VERSION "${CMAKE_PROJECT_VERSION}")
        tnt_class_Set(tnt_project ${args_THIS} VERSION_MAJOR "${CMAKE_PROJECT_VERSION_MAJOR}")
        tnt_class_Set(tnt_project ${args_THIS} VERSION_MINOR "${CMAKE_PROJECT_VERSION_MINOR}")
        tnt_class_Set(tnt_project ${args_THIS} VERSION_PATCH "${CMAKE_PROJECT_VERSION_PATCH}")
        tnt_class_Set(tnt_project ${args_THIS} VERSION_TWEAK "${CMAKE_PROJECT_VERSION_TWEAK}")
    endif()
endfunction()