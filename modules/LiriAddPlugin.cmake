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

function(liri_add_plugin name)
    # Find packages we need
    find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS Core)

    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_add_plugin"
        "QTQUICK_COMPILER"
        "TYPE"
        "${__default_private_args};${__default_public_args}"
        ${ARGN}
    )

    set(target "${name}")
    string(TOUPPER "${name}" name_upper)
    string(REGEX REPLACE "-" "_" name_upper "${name_upper}")

    # Target
    add_library("${target}" SHARED)
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
    set_target_properties("${target}" PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${INSTALL_PLUGINSDIR}/${_arg_TYPE}"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${INSTALL_BINDIR}"
    )
    extend_target("${target}"
        SOURCES ${_arg_SOURCES}
        PUBLIC_INCLUDE_DIRECTORIES
            ${_arg_PUBLIC_INCLUDE_DIRECTORIES}
        INCLUDE_DIRECTORIES
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${CMAKE_CURRENT_BINARY_DIR}"
            ${_arg_INCLUDE_DIRECTORIES}
        PUBLIC_DEFINES
            ${_arg_PUBLIC_DEFINES}
            LIRI_${name_upper}_LIB
        DEFINES
            QT_NO_CAST_TO_ASCII QT_ASCII_CAST_WARNINGS
            QT_USE_QSTRINGBUILDER
            QT_DEPRECATED_WARNINGS
            ${_arg_DEFINES}
        EXPORT_IMPORT_CONDITION
            LIRI_BUILD_${name_upper}_LIB
        PUBLIC_LIBRARIES ${_arg_PUBLIC_LIBRARIES}
        LIBRARIES ${_arg_LIBRARIES}
        DBUS_ADAPTOR_SOURCES ${_arg_DBUS_ADAPTOR_SOURCES}
        DBUS_ADAPTOR_FLAGS ${_arg_DBUS_ADAPTOR_FLAGS}
        DBUS_INTERFACE_SOURCES ${_arg_DBUS_INTERFACE_SOURCES}
        DBUS_INTERFACE_FLAGS ${_arg_DBUS_INTERFACE_FLAGS}
    )

    # Install
    install(TARGETS "${target}"
        LIBRARY DESTINATION "${INSTALL_PLUGINSDIR}/${_arg_TYPE}"
        ARCHIVE DESTINATION "${INSTALL_LIBDIR}/${_arg_TYPE}"
    )
endfunction()
