include_guard(GLOBAL)

# Download the cmake-conan helper script from the official repo if it doesn't exist
if(NOT EXISTS ${CMAKE_BINARY_DIR}/conan.cmake)
    message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(DOWNLOAD https://github.com/conan-io/cmake-conan/raw/v0.15/conan.cmake ${CMAKE_BINARY_DIR}/conan.cmake)
endif()

include(${CMAKE_BINARY_DIR}/conan.cmake)