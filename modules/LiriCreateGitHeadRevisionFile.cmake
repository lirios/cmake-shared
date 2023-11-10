# SPDX-FileCopyrightText: 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
#
# SPDX-License-Identifier: BSD-3-Clause

set(_template_file "${CMAKE_CURRENT_LIST_DIR}/LiriGitRevision.h.in")

function(liri_create_git_head_revision_file _file)
    if(NOT GIT_FOUND)
        find_package(Git QUIET)
    endif()

    set(_git_rev "")

    if(GIT_FOUND)
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" rev-parse HEAD
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            OUTPUT_VARIABLE _git_rev
        )
        string(STRIP "${_git_rev}" _git_rev)
    endif()

    if("x${_git_rev}" STREQUAL "x")
        set(_git_rev "tarball")
    endif()

    configure_file("${_template_file}" "${CMAKE_CURRENT_BINARY_DIR}/${_file}" @ONLY)
endfunction()
