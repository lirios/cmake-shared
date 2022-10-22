# SPDX-FileCopyrightText: 2021 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
#
# SPDX-License-Identifier: BSD-3-Clause

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
