function(liri_translate_desktop resultvar)
    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_translate_desktop"
        ""
        "TRANSLATIONS_PATH"
        "SOURCES"
        ${ARGN}
    )

    # Translation directory
    if(DEFINED _arg_TRANSLATIONS_PATH)
        set(_translations_path "translations")
    else()
        set(_translations_path "${_arg_TRANSLATIONS_PATH}")
    endif()
    get_filename_component(_translations_path "${_translations_path}" ABSOLUTE)

    set(_results "")

    foreach(_source_filename ${_arg_SOURCES})
        # Split file name and extension (without .in suffix)
        get_filename_component(_source_filename "${_source_filename}" ABSOLUTE)
        get_filename_component(_filename "${_source_filename}" NAME_WE)
        get_filename_component(_file_ext "${_source_filename}" EXT)
        string(REPLACE ".in" "" _file_ext "${_file_ext}")

        # Determine the destionation file
        set(_dest_filename "${CMAKE_CURRENT_BINARY_DIR}/${_filename}${_file_ext}")

        # Prepare the destination file
        add_custom_command(
            OUTPUT "${_dest_filename}"
            COMMAND grep -v -a "#TRANSLATIONS" "${_source_filename}" > "${_dest_filename}"
            DEPENDS "${_source_filename}"
            COMMENT "Preparing: ${_dest_filename}"
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            VERBATIM
        )

        # Find translated desktop files
        file(GLOB _translations "${_translation_path}/${_filename}_*${_file_ext}")
        if(_translations)
            list(SORT _translations)
            add_custom_command(
                OUTPUT "${_dest_filename}"
                COMMAND grep -h -a "\[.*]\s*=" ${_translations} >> ${_dest_filename}
                DEPENDS "${_source_filename}"
                COMMENT "Translating: ${_source_filename}"
                WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                VERBATIM
            )
        endif()

        list(APPEND _results "${_dest_filename}")
    endforeach()

    set(${resultvar} ${_results} PARENT_SCOPE)
endfunction()
