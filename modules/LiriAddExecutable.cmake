#
# Copyright (C) 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
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

# This function creates a CMake target for a generic console or GUI binary.
function(liri_add_executable target)
    # Find packages we need
    find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS Core)

    # Parse arguments
    cmake_parse_arguments(
        _arg
        "GUI;NO_TARGET_INSTALLATION"
        "OUTPUT_NAME;OUTPUT_DIRECTORY;INSTALL_DIRECTORY;DESKTOP_INSTALL_DIRECTORY;QTQUICK_COMPILER"
        "EXE_FLAGS;${__default_private_args};APPDATA;DESKTOP"
        ${ARGN}
    )
    if(DEFINED _arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments were passed to liri_add_executable (${_arg_UNPARSED_ARGUMENTS}).")
    endif()

    if("x${_arg_OUTPUT_NAME}" STREQUAL "x")
        set(_arg_OUTPUT_NAME "${target}")
    endif()

    if ("x${_arg_OUTPUT_DIRECTORY}" STREQUAL "x")
        set(_arg_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${INSTALL_BINDIR}")
    endif()

    # Add the target
    add_executable("${target}" ${_arg_EXE_FLAGS} ${_arg_SOURCES})
    set_target_properties("${target}" PROPERTIES
        LIRI_TARGET_TYPE "executable"
        OUTPUT_NAME "${_arg_OUTPUT_NAME}"
        WIN32_EXECUTABLE "${_arg_GUI}"
        MACOSX_BUNDLE "${_arg_GUI}"
    )

    # Extend the target
    liri_extend_target("${target}"
        INCLUDE_DIRECTORIES
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${CMAKE_CURRENT_BINARY_DIR}"
            ${_arg_INCLUDE_DIRECTORIES}
        DEFINES
            QT_NO_CAST_TO_ASCII QT_ASCII_CAST_WARNINGS
            QT_USE_QSTRINGBUILDER
            QT_DEPRECATED_WARNINGS
            ${_arg_DEFINES}
        LIBRARIES ${_arg_LIBRARIES}
        RESOURCES ${_arg_RESOURCES}
        DBUS_ADAPTOR_SOURCES ${_arg_DBUS_ADAPTOR_SOURCES}
        DBUS_ADAPTOR_FLAGS ${_arg_DBUS_ADAPTOR_FLAGS}
        DBUS_INTERFACE_SOURCES ${_arg_DBUS_INTERFACE_SOURCES}
        DBUS_INTERFACE_FLAGS ${_arg_DBUS_INTERFACE_FLAGS}
    )

    # Additional sources
    if(_arg_APPDATA)
        target_sources("${target}" PRIVATE "${_arg_APPDATA}")
    endif()
    if(_arg_DESKTOP)
        target_sources("${target}" PRIVATE "${_arg_DESKTOP}")
    endif()

    # Set custom properties
    if(_arg_QTQUICK_COMPILER)
        set_target_properties("${target}" PROPERTIES LIRI_ENABLE_QTQUICK_COMPILER ON)
    else()
        set_target_properties("${target}" PROPERTIES LIRI_ENABLE_QTQUICK_COMPILER OFF)
    endif()

    # Install executable
    if(NOT "${_arg_NO_TARGET_INSTALLATION}")
        if(DEFINED _arg_INSTALL_DIRECTORY)
            install(TARGETS "${target}"
                    BUNDLE DESTINATION "/Applications/${_arg_OUTPUT_NAME}"
                    RUNTIME DESTINATION "${_arg_INSTALL_DIRECTORY}")
        else()
            install(TARGETS "${target}"
                    BUNDLE DESTINATION "/Applications/${_arg_OUTPUT_NAME}"
                    RUNTIME DESTINATION ${INSTALL_TARGETS_DEFAULT_ARGS})
        endif()
    endif()

    # Install AppStream metadata
    if(DEFINED _arg_APPDATA)
        if((LINUX OR DARWIN OR FREEBSD) AND NOT APPLE)
            install(FILES ${_arg_APPDATA}
                    DESTINATION "${INSTALL_METAINFODIR}")
        endif()
    endif()

    # Install desktop entry
    if(DEFINED _arg_DESKTOP)
        if((LINUX OR DARWIN OR FREEBSD) AND NOT APPLE)
            if(DEFINED _arg_DESKTOP_INSTALL_DIRECTORY)
                install(FILES ${_arg_DESKTOP}
                        DESTINATION "${_arg_DESKTOP_INSTALL_DIRECTORY}")
            else()
                install(FILES ${_arg_DESKTOP}
                        DESTINATION "${INSTALL_APPLICATIONSDIR}")
            endif()
        endif()
    endif()
endfunction()

function(liri_finalize_executable target)
    # This function right now is just an alias to liri_finalize_target()
    # for consistency with the liri_finalize_<target type> convention
    liri_finalize_target("${target}")
endfunction()
