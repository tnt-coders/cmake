include_guard(GLOBAL)

# This package requires the "Git" package to function
find_package(Git REQUIRED)

function(tnt_git__get_version_info)

    # Use "git describe" to get version information from Git
    execute_process(
            COMMAND ${GIT_EXECUTABLE} describe --dirty --long --match=v* --tags
            WORKING_DIRECTORY git
            RESULT_VARIABLE git_result
            OUTPUT_VARIABLE git_output OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_VARIABLE git_error ERROR_STRIP_TRAILING_WHITESPACE)

    # If the result is not "0" an error has occurred
    if (git_result)
        message(FATAL_ERROR ${git_error})
    endif ()

    # Parse the version string returned by Git
    # Format is "v<MAJOR>.<MINOR>.<PATCH>-<TWEAK>-<GIT_HASH>[-dirty]"
    if (git_output MATCHES "^v([0-9]+)[.]([0-9]+)[.]([0-9]+)-([0-9]+)")
        set(version_major ${CMAKE_MATCH_1})
        set(version_minor ${CMAKE_MATCH_2})
        set(version_patch ${CMAKE_MATCH_3})
        set(version_tweak ${CMAKE_MATCH_4})

        string(APPEND version "${version_major}.${version_minor}.${version_patch}")
    else ()
        message(FATAL_ERROR "Git returned an invalid version: ${git_output}")
    endif ()

    # The version is considered dirty if there are uncommitted local changes
    if (git_output MATCHES "-dirty$")
        set(version_is_dirty TRUE)
    else ()
        set(version_is_dirty FALSE)
    endif ()

    # Use "git log" to get the current commit hash from Git
    execute_process(
            COMMAND ${GIT_EXECUTABLE} log -1 --pretty=format:%H
            WORKING_DIRECTORY git
            RESULT_VARIABLE git_result
            OUTPUT_VARIABLE git_output OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_VARIABLE git_error ERROR_STRIP_TRAILING_WHITESPACE)

    # If the result is not "0" an error has occurred
    if (git_result)
        message(FATAL_ERROR ${git_error})
    endif ()

    set(version_git_hash ${git_output})

    # Set global CMake variables containing project version information
    set(GIT_VERSION ${version} PARENT_SCOPE)
    set(GIT_VERSION_MAJOR ${version_major} PARENT_SCOPE)
    set(GIT_VERSION_MINOR ${version_minor} PARENT_SCOPE)
    set(GIT_VERSION_PATCH ${version_patch} PARENT_SCOPE)
    set(GIT_VERSION_TWEAK ${version_tweak} PARENT_SCOPE)
    set(GIT_VERSION_IS_DIRTY ${version_is_dirty} PARENT_SCOPE)
    set(GIT_VERSION_HASH ${version_git_hash} PARENT_SCOPE)
endfunction()