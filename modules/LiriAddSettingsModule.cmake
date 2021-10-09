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

function(liri_add_settings_module name)
    # Parse arguments
    cmake_parse_arguments(
        _arg
        ""
        "METADATA;TRANSLATIONS_PATH"
        "CONTENTS"
        ${ARGN}
    )
    if(DEFINED _arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments were passed to liri_add_settings_module (${_arg_UNPARSED_ARGUMENTS}).")
    endif()

    # Find packages we need
    find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS Core LinguistTools)

    string(TOLOWER "${name}" name_lower)

    # Assume a default value if metadata is not specified
    if(NOT _arg_METADATA)
        set(_arg_METADATA "${CMAKE_CURRENT_SOURCE_DIR}/metadata.desktop")
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
    set(_sources ${_arg_CONTENTS} ${_arg_METADATA} ${_qm_FILES})

    # Target
    set(target "${name}Settings")
    add_custom_target("${target}" ALL SOURCES ${_sources})
    set_target_properties("${target}" PROPERTIES LIRI_TARGET_TYPE "settings")

    # Install
    install(
        FILES ${_arg_METADATA}
        DESTINATION "${INSTALL_DATADIR}/liri-settings/modules/${name_lower}"
    )
    install(
        FILES ${_arg_CONTENTS}
        DESTINATION "${INSTALL_DATADIR}/liri-settings/modules/${name_lower}"
    )
    install(
        FILES ${_qm_FILES}
        DESTINATION "${INSTALL_DATADIR}/liri-settings/translations/modules"
    )
endfunction()
