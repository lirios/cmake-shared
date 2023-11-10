# SPDX-FileCopyrightText: 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
#
# SPDX-License-Identifier: BSD-3-Clause

function(liri_install_doc qdoc_filename)
    # Parse arguments
    cmake_parse_arguments(
        _arg
        ""
        "OUTPUT_DIRECTORY_VARIABLE"
        "ENVIRONMENT"
        ${ARGN}
    )
    if(DEFINED _arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments were passed to liri_install_doc (${_arg_UNPARSED_ARGUMENTS}).")
    endif()

    find_package(Qt5Core QUIET)
    if(TARGET Qt5::qmake)
        # Find QT_INSTALL_DOCS AND QT_HOST_DATA
        get_target_property(QMake_EXECUTABLE Qt5::qmake LOCATION)
        if(NOT QT_INSTALL_DOCS)
            exec_program("${QMake_EXECUTABLE}" ARGS "-query QT_INSTALL_DOCS" RETURN_VALUE return_code OUTPUT_VARIABLE QT_INSTALL_DOCS)
        endif()
        if(NOT QT_HOST_DATA)
            exec_program("${QMake_EXECUTABLE}" ARGS "-query QT_HOST_DATA" RETURN_VALUE return_code OUTPUT_VARIABLE QT_HOST_DATA)
        endif()

        # Find path
        get_filename_component(_path ${QMake_EXECUTABLE} DIRECTORY)
    else()
        message(FATAL_ERROR "Could not find qmake")
    endif()

    # Find qdoc executable
    find_program(QDoc_EXECUTABLE
        NAMES
            qdoc-qt5
            qdoc
        PATHS
            "${_path}"
        NO_DEFAULT_PATH
    )
    if(QDoc_EXECUTABLE)
        add_custom_target(docs
            ALL
            COMMAND
                QT_INSTALL_DOCS=${QT_INSTALL_DOCS} QT_VER="${Qt5Core_VERSION_MAJOR}.${Qt5Core_VERSION_MINOR}" QT_VERSION="${Qt5Core_VERSION_MAJOR}.${Qt5Core_VERSION_MINOR}" QT_VERSION_TAG="${Qt5Core_VERSION_MAJOR}.${Qt5Core_VERSION_MINOR}" ${_arg_ENVIRONMENT} "${QDoc_EXECUTABLE}" --outputdir "${CMAKE_CURRENT_BINARY_DIR}/qdoc_html" "${qdoc_filename}"
        )
        if(_arg_OUTPUT_DIRECTORY_VARIABLE)
            set(${_arg_OUTPUT_DIRECTORY_VARIABLE} "${CMAKE_CURRENT_BINARY_DIR}/qdoc_html" PARENT_SCOPE)
        endif()
    else()
        message(FATAL_ERROR "Could not find qdoc")
    endif()
endfunction()
