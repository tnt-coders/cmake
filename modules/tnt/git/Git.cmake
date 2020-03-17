include_guard(GLOBAL)

# This package requires the "Git" package to function
find_package(Git REQUIRED)

function(tnt_git_GetVersionInfo)

    # Use "git describe" to get version information from Git
    execute_process(
      COMMAND ${GIT_EXECUTABLE} describe --dirty --long --match=v* --tags
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      RESULT_VARIABLE gitResult
      OUTPUT_VARIABLE gitOutput OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_VARIABLE gitError ERROR_STRIP_TRAILING_WHITESPACE
    )

    # If the result is not "0" an error has occurred
    if(gitResult)
        message(FATAL_ERROR ${gitError})
    endif()

    # Parse the version string returned by Git
    # Format is "v<MAJOR>.<MINOR>.<PATCH>-<TWEAK>-<GIT_HASH>[-dirty]"
    if(gitOutput MATCHES "^v([0-9]+)[.]([0-9]+)[.]([0-9]+)-([0-9]+)")
        set(versionMajor ${CMAKE_MATCH_1})
        set(versionMinor ${CMAKE_MATCH_2})
        set(versionPatch ${CMAKE_MATCH_3})
        set(versionTweak ${CMAKE_MATCH_4})

        string(APPEND version "${versionMajor}.${versionMinor}.${versionPatch}")

        # Only include the tweak version if there has been a tweak
        if(${versionTweak})
            string(APPEND version "-${versionTweak}")
        endif()
    else()
        message(FATAL_ERROR "Git returned an invalid version: ${gitOutput}")
    endif()

    # The version is considered dirty if there are uncommitted local changes
    if(gitOutput MATCHES "-dirty$")
        set(versionIsDirty TRUE)
    else()
        set(versionIsDirty FALSE)
    endif()

    # Use "git log" to get the current commit hash from Git
    execute_process(
      COMMAND ${GIT_EXECUTABLE} log -1 --pretty=format:%H
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      RESULT_VARIABLE gitResult
      OUTPUT_VARIABLE gitOutput OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_VARIABLE gitError ERROR_STRIP_TRAILING_WHITESPACE
    )
    
    # If the result is not "0" an error has occurred
    if(gitResult)
        message(FATAL_ERROR ${gitError})
    endif()

    set(versionGitHash ${gitOutput})

    # Set global CMake variables containing project version information
    set(GIT_VERSION ${version} PARENT_SCOPE)
    set(GIT_VERSION_MAJOR ${versionMajor} PARENT_SCOPE)
    set(GIT_VERSION_MINOR ${versionMinor} PARENT_SCOPE)
    set(GIT_VERSION_PATCH ${versionPatch} PARENT_SCOPE)
    set(GIT_VERSION_TWEAK ${versionTweak} PARENT_SCOPE)
    set(GIT_VERSION_IS_DIRTY ${versionIsDirty} PARENT_SCOPE)
    set(GIT_VERSION_HASH ${versionGitHash} PARENT_SCOPE)
endfunction()