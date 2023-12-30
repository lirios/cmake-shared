# SPDX-FileCopyrightText: 2022 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
# SPDX-FileCopyrightText: 2022 The Qt Company Ltd.
#
# SPDX-License-Identifier: BSD-3-Clause

include(CMakeParseArguments)

# For adjusting variables when running tests, we need to know what
# the correct variable is for separating entries in PATH-alike
# variables.
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(LIRI_PATH_SEPARATOR "\\;")
else()
    set(LIRI_PATH_SEPARATOR ":")
endif()


# Functions and macros:

set(__default_private_args "SOURCES;LIBRARIES;INCLUDE_DIRECTORIES;DEFINES;RESOURCES")
set(__default_public_args "PUBLIC_LIBRARIES;PUBLIC_INCLUDE_DIRECTORIES;PUBLIC_DEFINES")
set(__default_module_args "PRIVATE_HEADERS;CLASS_HEADERS;INSTALL_HEADERS;PKGCONFIG_DEPENDENCIES")


# This function can be used to add sources/libraries/etc. to the specified CMake target
# if the provided CONDITION evaluates to true.
function(liri_extend_target target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "Trying to extend non-existing target \"${target}\".")
    endif()

    cmake_parse_arguments(
        _arg
        ""
        "EXPORT_IMPORT_CONDITION;GLOBAL_HEADER_CONTENT"
        "CONDITION;${__default_public_args};${__default_private_args};${__default_module_args};COMPILE_FLAGS;OUTPUT_NAME"
        ${ARGN}
    )
    if(DEFINED _arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments were passed to liri_extend_target (${_arg_UNPARSED_ARGUMENTS}).")
    endif()

    # If CONDITION is not specified, we apply all properties requested by the user
    if(DEFINED _arg_CONDITION)
        if(_arg_CONDITION)
            set(_condition ON)
        else()
            set(_condition OFF)
        endif()
    else()
        set(_condition ON)
    endif()

    if(_condition)
        get_target_property(_target_type "${target}" LIRI_TARGET_TYPE)

        if(_arg_SOURCES)
            target_sources("${target}" PRIVATE ${_arg_SOURCES})
        endif()

        if(_arg_EXPORT_IMPORT_CONDITION)
            set_target_properties("${target}" PROPERTIES DEFINE_SYMBOL "${_arg_EXPORT_IMPORT_CONDITION}")
        endif()

        if(_arg_COMPILE_FLAGS)
            target_compile_options("${target}" PUBLIC "${_arg_COMPILE_FLAGS}")
        endif()

        if(_arg_OUTPUT_NAME)
            set_target_properties("${target}" PROPERTIES OUTPUT_NAME "${_arg_OUTPUT_NAME}")
        endif()

        if(_arg_PUBLIC_LIBRARIES)
            target_link_libraries("${target}" PUBLIC ${_arg_PUBLIC_LIBRARIES})
        endif()
        if(_arg_LIBRARIES)
            target_link_libraries("${target}" PRIVATE ${_arg_LIBRARIES})
        endif()

        if(_arg_PUBLIC_INCLUDE_DIRECTORIES)
            target_include_directories("${target}" PUBLIC ${_arg_PUBLIC_INCLUDE_DIRECTORIES})
        endif()
        if(_arg_INCLUDE_DIRECTORIES)
            target_include_directories("${target}" PRIVATE ${_arg_INCLUDE_DIRECTORIES})
        endif()

        if(_arg_PUBLIC_DEFINES)
            target_compile_definitions("${target}" PUBLIC ${_arg_PUBLIC_DEFINES})
        endif()
        if(_arg_DEFINES)
            target_compile_definitions("${target}" PRIVATE ${_arg_DEFINES})
        endif()

        # Custom properties for all kinds of targets
        set_property(TARGET "${target}" APPEND PROPERTY LIRI_RESOURCES "${_arg_RESOURCES}")

        # Custom properties only for Liri modules
        if(_target_type STREQUAL "module")
            set_property(TARGET "${target}" APPEND PROPERTY LIRI_MODULE_GLOBAL_HEADER_CONTENT "${_arg_GLOBAL_HEADER_CONTENT}")
            set_property(TARGET "${target}" APPEND PROPERTY LIRI_MODULE_PKGCONFIG_DEPENDENCIES "${_arg_PKGCONFIG_DEPENDENCIES}")
            set_property(TARGET "${target}" APPEND PROPERTY LIRI_MODULE_PRIVATE_HEADERS "${_arg_PRIVATE_HEADERS}")
            set_property(TARGET "${target}" APPEND PROPERTY LIRI_MODULE_CLASS_HEADERS "${_arg_CLASS_HEADERS}")
            set_property(TARGET "${target}" APPEND PROPERTY LIRI_MODULE_INSTALL_HEADERS "${_arg_INSTALL_HEADERS}")
        endif()
    endif()
endfunction()

# Perform common setup actions on targets.
function(liri_finalize_target target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "Trying to extend non-existing target \"${target}\".")
    endif()
endfunction()

# Include public functions
include(LiriFeatures)
include(LiriProperties)
include(LiriAddModule)
#include(LiriAddStatusAreaExtension)
