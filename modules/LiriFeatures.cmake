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

include(CheckCXXSourceCompiles)

function(liri_config_compile_test name)
    # Parse arguments
    cmake_parse_arguments(
        _arg
        ""
        "LABEL;C_STANDARD;CXX_STANDARD"
        "COMPILE_OPTIONS;DEFINITIONS;LIBRARIES;CODE"
        ${ARGN}
    )

    # Save the original value of these special variables
    set(_save_CMAKE_C_STANDARD "${CMAKE_C_STANDARD}")
    set(_save_CMAKE_CXX_STANDARD "${CMAKE_CXX_STANDARD}")
    set(_save_CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS}")
    set(_save_CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS}")
    set(_save_CMAKE_REQUIRED_LIBRARIES "${CMAKE_REQUIRED_LIBRARIES}")

    # Set all variables required by check_cxx_source_compiles
    if(_arg_C_STANDARD)
       set(CMAKE_C_STANDARD "${_arg_C_STANDARD}")
    endif()
    if(_arg_CXX_STANDARD)
       set(CMAKE_CXX_STANDARD "${_arg_CXX_STANDARD}")
    endif()
    if(_arg_COMPILE_OPTIONS)
        set(CMAKE_REQUIRED_FLAGS ${_arg_COMPILE_OPTIONS})
    endif()
    if(_arg_DEFINITIONS)
        set(CMAKE_REQUIRED_DEFINITIONS ${_arg_DEFINITIONS})
    endif()
    if(_arg_LIBRARIES)
        set(CMAKE_REQUIRED_LIBRARIES ${_arg_LIBRARIES})
    endif()

    check_cxx_source_compiles("${_arg_CODE}" _have_${name})

    # Restore the original values
    set(CMAKE_C_STANDARD "${_save_CMAKE_C_STANDARD}")
    set(CMAKE_CXX_STANDARD "${_save_CMAKE_CXX_STANDARD}")
    set(CMAKE_REQUIRED_FLAGS "${_save_CMAKE_REQUIRED_FLAGS}")
    set(CMAKE_REQUIRED_DEFINITIONS "${_save_CMAKE_REQUIRED_DEFINITIONS}")
    set(CMAKE_REQUIRED_LIBRARIES "${_save_CMAKE_REQUIRED_LIBRARIES}")

    set(TEST_${name} "${_have${name}}" CACHE INTERNAL "${_arg_LABEL}")
endfunction()
