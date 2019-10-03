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

function(liri_add_qml_plugin name)
    # Find packages we need
    find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS Qml Quick)

    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_add_qml_plugin"
	"STATIC"
        "MODULE_PATH;VERSION;QTQUICK_COMPILER"
        "${__default_private_args};${__default_public_args};QML_FILES"
        ${ARGN}
    )

    if(NOT DEFINED _arg_MODULE_PATH)
        message(FATAL_ERROR "Missing argument MODULE_PATH.")
    endif()

    if(NOT DEFINED _arg_VERSION)
        set(_arg_VERSION "1.0")
    endif()

    set(target "${name}plugin")
    string(TOUPPER "${name}" name_upper)
    string(REGEX REPLACE "-" "_" name_upper "${name_upper}")

    # Find qmlplugindump
    get_target_property(QMake_EXECUTABLE Qt5::qmake LOCATION)
    get_filename_component(_qmake_path ${QMake_EXECUTABLE} DIRECTORY)
    find_program(QmlPluginDump_EXECUTABLE
        NAMES
            qmlplugindump-qt5
            qmlplugindump
        PATHS
            "${_qmake_path}"
        NO_DEFAULT_PATH
    )

    # plugins.qmltypes target
    if(NOT TARGET qmltypes)
        add_custom_target(qmltypes)
    endif()
    set(qmltypes_target "${target}-qmltypes")
    set(plugins_qmltypes "${CMAKE_CURRENT_BINARY_DIR}/plugins.qmltypes")
    string(REPLACE "/" "." _module_name "${_arg_MODULE_PATH}")
    add_custom_target("${qmltypes_target}"
        BYPRODUCTS "${plugins_qmltypes}"
        COMMAND ${QmlPluginDump_EXECUTABLE} -noinstantiate -nonrelocatable ${_module_name} ${_arg_VERSION} "${CMAKE_INSTALL_PREFIX}/${INSTALL_QMLDIR}" > "${plugins_qmltypes}"
    )
    add_dependencies(qmltypes "${qmltypes_target}")

    # Append plugins.qmltypes
    if(EXISTS "${plugins_qmltypes}")
        list(APPEND _arg_QML_FILES "${plugins_qmltypes}")
    endif()

    # Target
    if(_arg_STATIC)
        add_library("${target}" STATIC)
    else()
        add_library("${target}" SHARED)
    endif()
    if(DEFINED _arg_RESOURCES)
        if(${_arg_QTQUICK_COMPILER})
            find_package(Qt5QuickCompiler)
            if(Qt5QuickCompiler_FOUND)
                qtquick_compiler_add_resources(RESOURCES ${_arg_RESOURCES})
                list(APPEND _arg_SOURCES ${_arg_RESOURCES})
            else()
                message(WARNING "Qt5QuickCompiler not found, fall back to standard resources")
                qt5_add_resources(RESOURCES ${_arg_RESOURCES})
            endif()
        else()
            qt5_add_resources(RESOURCES ${_arg_RESOURCES})
        endif()
        list(APPEND _arg_SOURCES ${RESOURCES})
    endif()

    set(_static_defines "")
    if (_arg_STATIC)
        set(_static_defines "QT_STATICPLUGIN")
    endif()

    liri_extend_target("${target}"
        SOURCES
            ${_arg_SOURCES}
            ${_arg_QML_FILES}
        INCLUDE_DIRECTORIES
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${CMAKE_CURRENT_BINARY_DIR}"
            ${_arg_INCLUDE_DIRECTORIES}
        PUBLIC_INCLUDE_DIRECTORIES ${_arg_PUBLIC_INCLUDE_DIRECTORIES}
        LIBRARIES "Qt5::Qml;Qt5::Quick;${_arg_LIBRARIES}"
        PUBLIC_LIBRARIES ${_arg_PUBLIC_LIBRARIES}
        PUBLIC_DEFINES
            ${_arg_PUBLIC_DEFINES}
            LIRI_${name_upper}_LIB
        DEFINES
            ${_arg_DEFINES}
            QT_NO_CAST_TO_ASCII QT_ASCII_CAST_WARNINGS
            QT_NO_JAVA_STYLE_ITERATORS
            QT_USE_QSTRINGBUILDER
            QT_DEPRECATED_WARNINGS
	    "${_static_defines}"
	    QT_PLUGIN
        EXPORT_IMPORT_CONDITION
            LIRI_BUILD_${name_upper}_LIB
        DBUS_ADAPTOR_SOURCES ${_arg_DBUS_ADAPTOR_SOURCES}
        DBUS_ADAPTOR_FLAGS ${_arg_DBUS_ADAPTOR_FLAGS}
        DBUS_INTERFACE_SOURCES ${_arg_DBUS_INTERFACE_SOURCES}
        DBUS_INTERFACE_FLAGS ${_arg_DBUS_INTERFACE_FLAGS}
    )

    # Install
    install(FILES ${_arg_QML_FILES}
            DESTINATION "${INSTALL_QMLDIR}/${_arg_MODULE_PATH}")
    if(MINGW)
        set_target_properties(${target} PROPERTIES PREFIX "" IMPORT_PREFIX "")
    endif()
    if(NOT _arg_STATIC)
        install(TARGETS "${target}" DESTINATION "${INSTALL_QMLDIR}/${_arg_MODULE_PATH}")
    endif()
endfunction()
