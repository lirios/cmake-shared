# SPDX-FileCopyrightText: 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
#
# SPDX-License-Identifier: BSD-3-Clause

function(liri_add_test target)
    # Find packages we need
    find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS Core Test)

    # Parse arguments
    cmake_parse_arguments(
        _arg
        "RUN_SERIAL"
        ""
        "${__default_private_args}"
        ${ARGN}
    )
    if(DEFINED _arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments were passed to liri_add_test (${_arg_UNPARSED_ARGUMENTS}).")
    endif()

    # Absolute installation paths
    if(IS_ABSOLUTE "${INSTALL_BINDIR}")
        set(_bindir "${INSTALL_BINDIR}")
    else()
        set(_bindir "${CMAKE_INSTALL_PREFIX}/${INSTALL_BINDIR}")
    endif()
    if(IS_ABSOLUTE "${INSTALL_PLUGINSDIR}")
        set(_pluginsdir "${INSTALL_PLUGINSDIR}")
    else()
        set(_pluginsdir "${CMAKE_INSTALL_PREFIX}/${INSTALL_PLUGINSDIR}")
    endif()
    if(IS_ABSOLUTE "${INSTALL_QMLDIR}")
        set(_qmldir "${INSTALL_QMLDIR}")
    else()
        set(_qmldir "${CMAKE_INSTALL_PREFIX}/${INSTALL_QMLDIR}")
    endif()

    # Target
    liri_add_executable("${target}"
        SOURCES ${_arg_SOURCES}
        OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        INCLUDE_DIRECTORIES
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${CMAKE_CURRENT_BINARY_DIR}"
            ${_arg_INCLUDE_DIRECTORIES}
        DEFINES ${_arg_DEFINES}
        LIBRARIES "Qt5::Core;Qt5::Test;${_arg_LIBRARIES}"
        DBUS_ADAPTOR_SOURCES ${_arg_DBUS_ADAPTOR_SOURCES}
        DBUS_ADAPTOR_FLAGS ${_arg_DBUS_ADAPTOR_FLAGS}
        DBUS_INTERFACE_SOURCES ${_arg_DBUS_INTERFACE_SOURCES}
        DBUS_INTERFACE_FLAGS ${_arg_DBUS_INTERFACE_FLAGS}
        NO_TARGET_INSTALLATION
    )
    liri_finalize_executable("${target}")
    add_test(
        NAME "${target}"
        COMMAND "${target}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    )
    set_tests_properties("${target}" PROPERTIES RUN_SERIAL ${_arg_RUN_SERIAL})
    set_property(TEST "${target}" APPEND PROPERTY ENVIRONMENT "PATH=${_bindir}${LIRI_PATH_SEPARATOR}$ENV{PATH}")
    set_property(TEST "${target}" APPEND PROPERTY ENVIRONMENT "QT_PLUGIN_PATH=${_pluginsdir}${LIRI_PATH_SEPARATOR}$ENV{QT_PLUGIN_PATH}")
    set_property(TEST "${target}" APPEND PROPERTY ENVIRONMENT "QML2_IMPORT_PATH=${_qmldir}${LIRI_PATH_SEPARATOR}$ENV{QML2_IMPORT_PATH}")
endfunction()
