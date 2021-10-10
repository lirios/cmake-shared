#
# Copyright (C) 2021 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

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
