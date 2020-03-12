#[========================================================================[.rst:
tnt/Git
-------

This module contains utility functions to extract information from Git and make
it available at CMake configuration time.

Functions
^^^^^^^^^

.. command:: tnt_git_DefineProjectVersion

  Extracts the most recent version tag from the current project's Git repository
  and sets CMake variables containing version information.

  .. code-block:: cmake

    tnt_git_DefineProjectVersion()

  Version tags in the Git repository must be in the format
  "v.<major_version>.<minor_version>.<patch_version>" where ``major_version``,
  ``minor_version``, and ``patch_version`` are integer values. It is typical to
  add a version tag to the master branch of a git repository upon each official
  release.

  The following variables are defined by this function (<PROJECT_NAME> is
  determined by the most recent ``project`` command):

  .. variable:: <PROJECT_NAME>_VERSION

    The full version string in the format "<major>.<minor>.<patch>[-<tweak>]".
    The "tweak" value will only be included in this variable if the current
    commit does not exactly match the commit that the version tag was found on.
    The "tweak" number represents how many commits have occurred since the
    tagged commit.

  .. variable:: <PROJECT_NAME>_VERSION_MAJOR

    Contains the major version number for the project

  .. variable:: <PROJECT_NAME>_VERSION_MINOR

    Contains the minor version number for the project

  .. variable:: <PROJECT_NAME>_VERSION_PATCH

    Contains the patch version number for the project

  .. variable:: <PROJECT_NAME>_VERSION_TWEAK

    Contains the tweak version number for the project. The tweak version number
    is determined by how many commits have occurred since the last version tag.
    If the current commit exacly matches the commit that the version tag was
    found on, then this variable will have a value of 0.

  .. variable:: <PROJECT_NAME>_VERSION_IS_DIRTY

    If the current project has uncommitted local changes the local repository is
    considered "dirty". This variable will be TRUE if the repository is dirty
    and FALSE otherwise.

  .. variable:: <PROJECT_NAME>_VERSION_GIT_HASH

    Contains the full git commit hash for the current commit.
#]========================================================================]

include_guard(GLOBAL)

# This package requires the "Git" package to function
find_package(Git REQUIRED)

function(tnt_git_DefineProjectVersion)

    # Use "git describe" to get version information from Git
    execute_process(
      COMMAND ${GIT_EXECUTABLE} describe --dirty --long --match=v* --tags
      WORKING_DIRECTORY ${${PROJECT_NAME}_SOURCE_DIR}
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
      WORKING_DIRECTORY ${${PROJECT_NAME}_SOURCE_DIR}
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
    set(${PROJECT_NAME}_VERSION ${version} CACHE INTERNAL "Project full version string")
    set(${PROJECT_NAME}_VERSION_MAJOR ${versionMajor} CACHE INTERNAL "Project major version number")
    set(${PROJECT_NAME}_VERSION_MINOR ${versionMinor} CACHE INTERNAL "Project minor version number")
    set(${PROJECT_NAME}_VERSION_PATCH ${versionPatch} CACHE INTERNAL "Project patch version number")
    set(${PROJECT_NAME}_VERSION_TWEAK ${versionTweak} CACHE INTERNAL "Project tweak version number")
    set(${PROJECT_NAME}_VERSION_IS_DIRTY ${versionIsDirty} CACHE INTERNAL "Project version dirty status")
    set(${PROJECT_NAME}_VERSION_GIT_HASH ${versionGitHash} CACHE INTERNAL "Project version Git hash")
endfunction()