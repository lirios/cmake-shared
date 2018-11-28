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

function(liri_install_doc qdoc_filename)
    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_install_doc"
        ""
        "OUTPUT_DIRECTORY_VARIABLE"
        "ENVIRONMENT"
        ${ARGN}
    )

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
                QT_INSTALL_DOCS=${QT_INSTALL_DOCS} QT_VERSION_TAG="${Qt5Core_VERSION_MAJOR}.${Qt5Core_VERSION_MINOR}" ${_arg_ENVIRONMENT} "${QDoc_EXECUTABLE}" --outputdir "${CMAKE_CURRENT_BINARY_DIR}/qdoc_html" "${qdoc_filename}"
        )
        if(_arg_OUTPUT_DIRECTORY_VARIABLE)
            set(${_arg_OUTPUT_DIRECTORY_VARIABLE} "${CMAKE_CURRENT_BINARY_DIR}/qdoc_html" PARENT_SCOPE)
        endif()
    else()
        message(FATAL_ERROR "Could not find qdoc")
    endif()
endfunction()
