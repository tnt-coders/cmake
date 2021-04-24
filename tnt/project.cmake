include_guard(GLOBAL)

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

function(tnt_project__add_executable)
    set(options)
    set(one_value_args NAMESPACE TARGET)
    set(multi_value_args SOURCES)
    cmake_parse_arguments(args "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

    # Create the executable
    add_executable(${args_TARGET} ${args_SOURCES})

    # Initialize default include directories
    set(private_include_dir "${PROJECT_SOURCE_DIR}/include/${args_TARGET}")

    # Handle namespace considerations
    if (args_NAMESPACE)
        set(private_include_dir "${PROJECT_SOURCE_DIR}/include/${args_NAMESPACE}/${args_TARGET}")
    endif ()

    # Set default include directories
    target_include_directories(${args_TARGET}
            PRIVATE
            ${PROJECT_SOURCE_DIR}/include
            ${private_include_dir}
            ${PROJECT_SOURCE_DIR}/src)
endfunction()

function(tnt_project__add_library)
    set(options INTERFACE)
    set(one_value_args NAMESPACE TARGET)
    set(multi_value_args SOURCES)
    cmake_parse_arguments(args "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

    # Create the library
    if (${args_INTERFACE})
        add_library(${args_TARGET} INTERFACE ${args_UNPARSED_ARGUMENTS})
    else ()
        add_library(${args_TARGET} ${args_SOURCES} ${args_UNPARSED_ARGUMENTS})

        # Handle RPATH considerations for shared libraries
        # See "Deep CMake for Library Authors" https://www.youtube.com/watch?v=m0DwB4OvDXk
        set_target_properties(${args_TARGET} PROPERTIES BUILD_RPATH_USE_ORIGIN TRUE)
    endif ()

    # Initialize default include directories
    set(private_include_dir "${PROJECT_SOURCE_DIR}/include/${args_TARGET}")

    # Handle namespace considerations
    if (args_NAMESPACE)
        add_library(${args_NAMESPACE}::${args_TARGET} ALIAS ${args_TARGET})
        set(private_include_dir "${PROJECT_SOURCE_DIR}/include/${args_NAMESPACE}/${args_TARGET}")
    endif ()

    # Set default include directories
    if (${args_INTERFACE})
        target_include_directories(${args_TARGET}
                INTERFACE
                $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
                $<INSTALL_INTERFACE:include>)
    else ()
        target_include_directories(${args_TARGET}
                PUBLIC
                $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
                $<INSTALL_INTERFACE:include>
                PRIVATE
                $<BUILD_INTERFACE:${private_include_dir}>
                $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>)
    endif ()
endfunction()

function(tnt_project__install)
    set(options)
    set(one_value_args NAMESPACE)
    set(multi_value_args TARGETS)
    cmake_parse_arguments(args "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

    # Validate input arguments
    if (NOT args_TARGETS)
        message(FATAL_ERROR "Missing required input argument 'TARGETS'.")
    endif ()

    # Set the install destination and namespace
    set(install_destination "lib/cmake/${PROJECT_NAME}")
    if (args_NAMESPACE)
        set(install_namespace "${args_NAMESPACE}::")
    endif ()

    # Create an export package of the targets
    # Use GNUInstallDirs and COMPONENTS
    # See "Deep CMake for Library Authors" https://www.youtube.com/watch?v=m0DwB4OvDXk
    # TODO: Investigate why using "COMPONENTS" broke usage of the package
    install(
            TARGETS ${args_TARGETS}
            EXPORT ${PROJECT_NAME}-targets
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            #COMPONENT ${PROJECT_NAME}_Development
            INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
            #COMPONENT ${PROJECT_NAME}_Development
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            #COMPONENT ${PROJECT_NAME}_Runtime
            #NAMELINK_COMPONENT ${PROJECT_NAME}_Development
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
            #COMPONENT ${PROJECT_NAME}_Runtime)

    # Install the export package
    install(
            EXPORT ${PROJECT_NAME}-targets
            FILE ${PROJECT_NAME}-targets.cmake
            NAMESPACE ${install_namespace}
            DESTINATION ${install_destination})

    # Generate a package configuration file
    file(
            WRITE ${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config.cmake.in
            "@PACKAGE_INIT@\n"
            "include(\${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}-targets.cmake)")
    configure_package_config_file(
            ${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config.cmake.in
            ${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
            INSTALL_DESTINATION ${install_destination})

    # Gather files to be installed
    list(APPEND install_files ${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config.cmake)

    # If the package has a version specified, generate a package version file
    if (PROJECT_VERSION)
        write_basic_package_version_file(${PROJECT_NAME}-config-version.cmake
                VERSION ${PROJECT_VERSION}
                COMPATIBILITY SameMajorVersion)

        list(APPEND install_files ${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake)
    endif ()

    # Install config files for the project
    install(
            FILES ${install_files}
            DESTINATION ${install_destination})

    # Install public header files for the project
    install(
            DIRECTORY ${PROJECT_SOURCE_DIR}/include/
            DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
            FILES_MATCHING PATTERN "*.h*")
endfunction()
