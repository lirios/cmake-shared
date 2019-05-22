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
function(liri_add_executable name)
    # Find packages we need
    find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS Core)

    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_add_executable"
        "GUI;NO_TARGET_INSTALLATION;QTQUICK_COMPILER"
        "OUTPUT_NAME;OUTPUT_DIRECTORY;INSTALL_DIRECTORY;DESKTOP_INSTALL_DIRECTORY"
        "EXE_FLAGS;${__default_private_args};APPDATA;DESKTOP"
        ${ARGN}
    )

    if("x${_arg_OUTPUT_NAME}" STREQUAL "x")
        set(_arg_OUTPUT_NAME "${name}")
    endif()

    if ("x${_arg_OUTPUT_DIRECTORY}" STREQUAL "x")
        set(_arg_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${INSTALL_BINDIR}")
    endif()

    add_executable("${name}" ${_arg_EXE_FLAGS})
    if(DEFINED _arg_RESOURCES)
        if(DEFINED _arg_QTQUICK_COMPILER)
            find_package(Qt5QuickCompiler)
            if(Qt5QuickCompiler_FOUND)
                qtquick_compiler_add_resources(RESOURCES ${_arg_RESOURCES})
            else()
                message(WARNING "Qt5QuickCompiler not found, fall back to standard resources")
                qt5_add_resources(RESOURCES ${_arg_RESOURCES})
            endif()
        else()
            qt5_add_resources(RESOURCES ${_arg_RESOURCES})
        endif()
        list(APPEND _arg_SOURCES ${RESOURCES})
    endif()
    if(DEFINED _arg_APPDATA)
        list(APPEND _arg_SOURCES ${_arg_APPDATA})
    endif()
    if(DEFINED _arg_DESKTOP)
        list(APPEND _arg_SOURCES ${_arg_DESKTOP})
    endif()
    extend_target("${name}"
        SOURCES ${_arg_SOURCES}
        INCLUDE_DIRECTORIES
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${CMAKE_CURRENT_BINARY_DIR}"
            ${_arg_INCLUDE_DIRECTORIES}
        DEFINES ${_arg_DEFINES}
        LIBRARIES ${_arg_LIBRARIES}
        DBUS_ADAPTOR_SOURCES ${_arg_DBUS_ADAPTOR_SOURCES}
        DBUS_ADAPTOR_FLAGS ${_arg_DBUS_ADAPTOR_FLAGS}
        DBUS_INTERFACE_SOURCES ${_arg_DBUS_INTERFACE_SOURCES}
        DBUS_INTERFACE_FLAGS ${_arg_DBUS_INTERFACE_FLAGS}
    )
    set_target_properties("${name}" PROPERTIES
        OUTPUT_NAME "${_arg_OUTPUT_NAME}"
        WIN32_EXECUTABLE "${_arg_GUI}"
        MACOSX_BUNDLE "${_arg_GUI}"
    )

    # Install executable
    if(NOT "${_arg_NO_TARGET_INSTALLATION}")
        if(DEFINED _arg_INSTALL_DIRECTORY)
            install(TARGETS "${name}"
                    BUNDLE DESTINATION "/Applications/${_arg_OUTPUT_NAME}"
                    RUNTIME DESTINATION "${_arg_INSTALL_DIRECTORY}")
        else()
            install(TARGETS "${name}"
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
