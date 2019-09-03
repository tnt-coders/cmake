#.rst:
# Conan
# -----
#
# CMake helper functions for dealing with the Conan package manager
#
# This module provides a wrapper around the cmake-conan module found at
# https://github.com/conan-io/cmake-conan. Upon including Conan, it will check
# if the cmake-conan module exists in your CMake binary directory. If not, it
# will automatically download it from github. After including Conan, all
# functions within in ``cmake-conan`` will be available for use.
#
# .. command:: conan_install
#
# Reads the conanfile.txt file in the current source directory and executes a
# ``conan_install`` on the required packages. After installing, a CMake target
# for each package with the prefix ``CONAN_PKG::`` will be available for use.
#
# ::
#
#     conan_install()
#
# By default this command will call ``conan_cmake_run`` with the following
# signature:
#
# ::
#
#     conan_cmake_run(
#         CONANFILE conanfile.txt
#         BASIC_SETUP CMAKE_TARGETS
#         BUILD missing
#     )
#
# The name/path of the conanfile can be overridden by passing
# ``CONANFILE [filename]``
#
# Additional arguments will be forwarded to the ``conan_cmake_run`` function as
# is.
#
# For more information on the Conan package manager see
# https://docs.conan.io/en/latest/

include_guard(GLOBAL)

# Download the cmake-conan helper script from the official repo if it doesn't exist
if(NOT EXISTS ${CMAKE_BINARY_DIR}/conan.cmake)
    message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(DOWNLOAD https://github.com/conan-io/cmake-conan/raw/v0.14/conan.cmake ${CMAKE_BINARY_DIR}/conan.cmake)
endif()

include(${CMAKE_BINARY_DIR}/conan.cmake)

function(conan_install)
    set(options)
    set(oneValueArgs CONANFILE)
    set(multiValueArgs)
    cmake_parse_arguments(args "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(conanfile "conanfile.txt")
    if(${args_CONANFILE})
        set(conanfile ${args_CONANFILE})
    endif()

    # Install the dependencies
    conan_cmake_run(
        CONANFILE ${conanfile}
        ${ARGN}
        BASIC_SETUP CMAKE_TARGETS
        BUILD missing
    )

endfunction()