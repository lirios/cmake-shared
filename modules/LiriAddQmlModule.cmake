# SPDX-FileCopyrightText: 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
#
# SPDX-License-Identifier: BSD-3-Clause

function(liri_add_qml_module name)
    # Parse arguments
    cmake_parse_arguments(
        _arg
        ""
        "MODULE_PATH;VERSION"
        "QML_FILES"
        ${ARGN}
    )
    if(DEFINED _arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments were passed to liri_add_qml_module (${_arg_UNPARSED_ARGUMENTS}).")
    endif()

    if(NOT DEFINED _arg_MODULE_PATH)
        message(FATAL_ERROR "Missing argument MODULE_PATH.")
    endif()

    if(NOT DEFINED _arg_VERSION)
        set(_arg_VERSION "1.0")
    endif()

    # Target
    set(target "${name}plugin")
    add_custom_target("${target}" SOURCES ${_arg_QML_FILES})
    set_target_properties("${target}" PROPERTIES LIRI_TARGET_TYPE "qmlmodule")

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

    # Install
    install(FILES ${_arg_QML_FILES}
            DESTINATION "${INSTALL_QMLDIR}/${_arg_MODULE_PATH}")
endfunction()
