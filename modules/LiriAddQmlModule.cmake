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

function(liri_add_qml_module name)
    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_add_qml_module"
        ""
        "MODULE_PATH;VERSION"
        "QML_FILES"
        ${ARGN}
    )

    if(NOT DEFINED _arg_MODULE_PATH)
        message(FATAL_ERROR "Missing argument MODULE_PATH.")
    endif()

    if(NOT DEFINED _arg_VERSION)
        set(_arg_VERSION "1.0")
    endif()

    # Target
    set(target "${name}plugin")
    add_custom_target("${target}" SOURCES ${_arg_QML_FILES})

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
    set(plugins_qmltypes "${CMAKE_CURRENT_SOURCE_DIR}/plugins.qmltypes")
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

    # Install
    install(FILES ${_arg_QML_FILES}
            DESTINATION "${INSTALL_QMLDIR}/${_arg_MODULE_PATH}")
endfunction()
