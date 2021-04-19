include_guard(GLOBAL)

# Creates the object by defining its existence and scope
# Variables must be set in current and parent scope to work correctly
macro(tnt_class_CreateObject args_CLASS args_THIS)
    # Create the object
    set(_${args_CLASS}_${args_THIS}_EXISTS TRUE)
    set(_${args_CLASS}_${args_THIS}_EXISTS TRUE PARENT_SCOPE)

    # Set the scope of the tnt_project object
    set(_${args_CLASS}_${args_THIS}_SCOPE ${CMAKE_CURRENT_SOURCE_DIR})
    set(_${args_CLASS}_${args_THIS}_SCOPE ${CMAKE_CURRENT_SOURCE_DIR} PARENT_SCOPE)
endmacro()

# Called at the beginning of each member function to verify the object is valid
function(tnt_class_MemberFunction args_CLASS args_THIS)
    if(NOT _${args_CLASS}_${args_THIS}_EXISTS)
        message(FATAL_ERROR "No ${args_CLASS} object '${args_THIS}' exists in the current scope")
    endif()
endfunction()

# Sets the specified member variable for the provided object
function(tnt_class_Set args_CLASS args_THIS args_MEMBER args_VALUE)
    set_property(
      DIRECTORY ${_${args_CLASS}_${args_THIS}_SCOPE}
      PROPERTY _${args_CLASS}_${args_THIS}_${args_MEMBER}
        ${args_VALUE}
    )
endfunction()

# Gets the specified member variable for the provided object
function(tnt_class_Get args_CLASS args_THIS args_MEMBER args_VALUE)
    get_property(value
      DIRECTORY ${_${args_CLASS}_${args_THIS}_SCOPE}
      PROPERTY _${args_CLASS}_${args_THIS}_${args_MEMBER}
    )
    set(${args_VALUE} ${value} PARENT_SCOPE)
endfunction()