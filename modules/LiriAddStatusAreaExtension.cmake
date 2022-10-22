# SPDX-FileCopyrightText: 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
#
# SPDX-License-Identifier: BSD-3-Clause

function(liri_add_statusareaextension name)
    # Parse arguments
    cmake_parse_arguments(
        _arg
        ""
        "METADATA;CONTENTS_DIRECTORY;TRANSLATIONS_PATH"
        "QML_FILES"
        ${ARGN}
    )
    if(DEFINED _arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments were passed to liri_add_statusareaextension (${_arg_UNPARSED_ARGUMENTS}).")
    endif()

    # Find packages we need
    find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS Core LinguistTools)

    string(TOLOWER "${name}" name_lower)

    # Assume a default value if metadata is not specified
    if(NOT _arg_METADATA)
        set(_arg_METADATA "${CMAKE_CURRENT_SOURCE_DIR}/metadata.desktop")
    endif()

    # Assume a default value for the contents directgory
    if(NOT _arg_CONTENTS_DIRECTORY)
        set(_arg_CONTENTS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/contents")
    endif()

    # Translation directory
    if(DEFINED _arg_TRANSLATIONS_PATH)
        set(_translations_path "${_arg_TRANSLATIONS_PATH}")
    else()
        set(_translations_path "${CMAKE_CURRENT_SOURCE_DIR}/translations")
    endif()
    get_filename_component(_translations_path "${_translations_path}" ABSOLUTE)

    # Translations
    file(GLOB _translations "${_translations_path}/*_*.ts")
    qt5_add_translation(_qm_FILES ${_translations})

    # Sources
    set(_sources ${_arg_QML_FILES} ${_arg_METADATA} ${_qm_FILES})

    # Target
    set(target "${name}StatusAreaExtension")
    add_custom_target("${target}" ALL SOURCES ${_sources})
    set_target_properties("${target}" PROPERTIES LIRI_TARGET_TYPE "statusarea")

    # Install
    install(
        FILES ${_arg_METADATA}
        DESTINATION "${INSTALL_DATADIR}/liri-shell/statusarea/${name_lower}"
    )
    install(
        DIRECTORY ${_arg_CONTENTS_DIRECTORY}/
        DESTINATION "${INSTALL_DATADIR}/liri-shell/statusarea/${name_lower}/contents"
    )
    install(
        FILES ${_qm_FILES}
        DESTINATION "${INSTALL_DATADIR}/liri-shell/statusarea/${name_lower}/translations"
    )
endfunction()
