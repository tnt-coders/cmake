# CMakeModules

The CMakeModules project contains a collection of useful CMake modules that can
be easily integrated into any CMake project.

## Usage

Using these modules is very straightforward. Simply use the `FetchContent`
module that comes with CMake to integrate these modules seamlessly into your
own projects.

    include(FetchContent)
    FetchContent_Declare(CMakeModules
      GIT_REPOSITORY https://github.com/tnt-coders/cmake-modules.git
    )
    FetchContent_MakeAvailable(CMakeModules)

This will automatically add all of these modules to the `CMAKE_MODULE_PATH` and
make them immediately available for use with the `include()` function

    include(<module_name>)
