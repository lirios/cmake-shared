# SPDX-FileCopyrightText: 2021 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
#
# SPDX-License-Identifier: BSD-3-Clause

function(_liri_internal_forward_headers destination_var)
    set(options)
    set(oneValueArgs OUTPUT_DIR MODULE_NAME)
    set(multiValueArgs HEADER_NAMES)
    cmake_parse_arguments(_arg "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    if(DEFINED _arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments passed to _liri_internal_forward_headers: (${_arg_UNPARSED_ARGUMENTS}).")
    endif()
    if(NOT _arg_HEADER_NAMES)
        message(FATAL_ERROR "Missing HEADER_NAMES argument to _liri_internal_forward_headers.")
    endif()
    if(NOT _arg_OUTPUT_DIR)
        set(_arg_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    endif()

    set(_required_headers)

    foreach(_entry IN LISTS _arg_HEADER_NAMES)
        # We have an entry like either of the following examples:
        #   ClassName1,ClassName2:path/to/header.h
        #   ClassName1,ClassName2
        #   ClassName
        string(REPLACE ":" ";" _mapping ${_entry})
        list(GET _mapping 0 _classnameentry)
        string(REPLACE "," ";" _classnames ${_classnameentry})
        list(GET _classnames 0 _baseclass)

        # Determine the actual header, either from whatever the user indicated
        # or the first class name
        list(LENGTH _mapping _has_actual_header)
        if(_has_actual_header GREATER 1)
            list(GET _mapping 1 _actual_header)
        else()
            set(_actual_header)
        endif()
        if(NOT _actual_header)
            string(TOLOWER "${_baseclass}.h" _actual_header)
        endif()
        get_filename_component(_actual_header_basename "${_actual_header}" NAME)
        if(NOT IS_ABSOLUTE "${_actual_header}")
            set(_actual_header "${CMAKE_CURRENT_SOURCE_DIR}/${_actual_header}")
        endif()
        if(NOT EXISTS "${_actual_header}")
            message(FATAL_ERROR "Could not find \"${_actual_header}\".")
        endif()

        # Create headers with class name
        foreach(_classname IN LISTS _classnames)
            set(_classname_header "${_arg_OUTPUT_DIR}/${_classname}")
            file(GENERATE OUTPUT "${_classname_header}" CONTENT "#include <${_arg_MODULE_NAME}/${_actual_header_basename}>\n" TARGET "${target}")
            list(APPEND ${destination_var} "${_classname_header}")
        endforeach()

        # Include this header from the common header
        list(APPEND _required_headers "${_actual_header_basename}")

        unset(_actual_header)
    endforeach()

    # Combine required headers into one convenience header
    if(_arg_MODULE_NAME)
        set(_common_header "${_arg_OUTPUT_DIR}/${_arg_MODULE_NAME}")
        set(_contents "// This header includes all the header files of the \"${_arg_MODULE_NAME}\" module.\n\n")
        foreach(_header IN LISTS _required_headers)
            set(_contents "${_contents}#include <${_arg_MODULE_NAME}/${_header}>\n")
        endforeach()
        file(GENERATE OUTPUT "${_common_header}" CONTENT "${_contents}" TARGET "${target}")
        list(APPEND ${destination_var} "${_common_header}")
    endif()

    set(${destination_var} ${${destination_var}} PARENT_SCOPE)
endfunction()
