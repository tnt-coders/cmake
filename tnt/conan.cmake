include_guard(GLOBAL)

# Download the cmake-conan helper script from the official repo if it doesn't exist
if (NOT EXISTS ${CMAKE_BINARY_DIR}/conan.cmake)
    message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(DOWNLOAD https://github.com/conan-io/cmake-conan/raw/v0.15/conan.cmake ${CMAKE_BINARY_DIR}/conan.cmake)
endif ()

include(${CMAKE_BINARY_DIR}/conan.cmake)

function(tnt_conan__install)

    # Perform conan basic setup if exported
    if (CONAN_EXPORTED)
        include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
        conan_basic_setup()
    endif ()

    # Make sure the conanfile exists
    if (EXISTS ${CMAKE_CURRENT_LIST_DIR}/conanfile.py)
        set(conanfile conanfile.py)
    elseif (EXISTS ${CMAKE_CURRENT_LIST_DIR}/conanfile.txt)
        set(conanfile conanfile.txt)
    else ()
        message(FATAL_ERROR "No conan file (conanfile.py or conanfile.txt) found for the current project.")
    endif ()

    # Run conan from CMake and install the project dependencies
    conan_cmake_run(
            CONANFILE ${conanfile}
            BUILD outdated
            BASIC_SETUP
            CMAKE_TARGETS
            UPDATE
            ${ARGN})
endfunction()

function(tnt_conan__package)
    set(options)
    set(one_value_args CHANNEL NAME REMOTE USER VERSION)
    set(multi_value_args)
    cmake_parse_arguments(args "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

    # Validate input
    if (NOT args_NAME)
        message(FATAL_ERROR "Missing required argument 'NAME'.")
    endif ()
    if (NOT args_REMOTE)
        message(FATAL_ERROR "Missing required argument 'REMOTE'.")
    endif ()
    if (NOT args_VERSION)
        message(FATAL_ERROR "Missing required argument 'VERSION'.")
    endif ()

    # Make sure the conanfile exists (must be conanfile.py for creating a package)
    if (NOT EXISTS ${CMAKE_CURRENT_LIST_DIR}/conanfile.py)
        message(FATAL_ERROR "No conanfile.py found for the current project.")
    endif ()

    if (NOT CONAN_EXPORTED)
        set(package_command "conan create ${CMAKE_CURRENT_LIST_DIR} ${args_NAME}/${args_VERSION}")
        if (args_USER AND args_CHANNEL)
            string(CONCAT package_command "@${args_USER}/${args_CHANNEL}")
        endif ()

        add_custom_target(conan_package
                COMMAND ${package_command}
                VERBATIM)

        set(upload_command "conan upload --all --remote ${args_REMOTE} ${args_NAME}/${args_VERSION}")
        if (args_USER AND args_CHANNEL)
            string(CONCAT upload_command "@${args_USER}/${args_CHANNEL}")
        endif ()

        add_custom_target(conan_upload
                COMMAND ${upload_command}
                VERBATIM)
    endif ()
endfunction()