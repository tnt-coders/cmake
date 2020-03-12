#[========================================================================[.rst:
tnt/Conan
---------

This module makes functions in the "cmake-conan" package found at
https://github.com/conan-io/cmake-conan available for use. Upon including Conan,
it will check if the "cmake-conan" module exists in your CMake binary directory.
If not, it will automatically download it from github. After including
tnt/conan/Conan, all functions within in ``cmake-conan`` will be available for
use.

For more information on the Conan package manager see
https://docs.conan.io/en/latest/

Functions
^^^^^^^^^

.. command:: tnt_conan_Install

  Reads the "conanfile.txt" file in the current project source directory and
  executes a ``conan_install`` on the required packages. After installing, a
  CMake target for each package with the prefix ``CONAN_PKG::`` will be
  available for use.

  .. code-block:: cmake

    tnt_conan_Install()

  By default this command will call ``conan_cmake_run`` with the following
  signature:

  .. code-block:: cmake

    conan_cmake_run(
        CONANFILE conanfile.txt
        BASIC_SETUP CMAKE_TARGETS
        BUILD outdated
    )

  The name/path of the conanfile can be overridden by passing
  ``CONANFILE [filename]``

  Any additional arguments will be forwarded to the ``conan_cmake_run`` function
  directly.

#]========================================================================]

include_guard(GLOBAL)

# Download the cmake-conan helper script from the official repo if it doesn't exist
if(NOT EXISTS ${CMAKE_BINARY_DIR}/conan.cmake)
    message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(DOWNLOAD https://github.com/conan-io/cmake-conan/raw/v0.15/conan.cmake ${CMAKE_BINARY_DIR}/conan.cmake)
endif()

include(${CMAKE_BINARY_DIR}/conan.cmake)

function(tnt_conan_Install)
    set(options)
    set(oneValueArgs CONANFILE)
    set(multiValueArgs)
    cmake_parse_arguments(args "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Determine which conanfile to use
    set(conanfile ${PROJECT_SOURCE_DIR}/conanfile.txt)
    if(args_CONANFILE)
        set(conanfile ${args_CONANFILE})
    endif()

    # Install the dependencies for the project using Conan
    conan_cmake_run(
      CONANFILE ${conanfile}
      ${ARGN}
      BASIC_SETUP CMAKE_TARGETS
      BUILD outdated
    )

endfunction()