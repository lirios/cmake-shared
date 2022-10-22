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

set(_fwd_headers_exe "${CMAKE_CURRENT_LIST_DIR}/detect-class-headers")

include(LiriModuleHeaders)

# This is the main entry function for creating a Liri module, that typically
# consists of a library, public header files and private header files.
#
# A CMake target with the specified name parameter is created.
#
# Liri modules provide also a way to be used by other build systems,
# in the form of a CMake package and pkg-config file.
function(liri_add_module name)
    # Find packages we need
    find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS Core)

    # Parse arguments
    cmake_parse_arguments(
        _arg
        "QTQUICK_COMPILER;NO_MODULE_HEADERS;NO_CMAKE;NO_PKGCONFIG;STATIC"
        "DESCRIPTION;MODULE_NAME;GLOBAL_HEADER_CONTENT;VERSIONED_MODULE_NAME"
        "${__default_private_args};${__default_public_args};INSTALL_HEADERS;CLASS_HEADERS;PRIVATE_HEADERS;PKGCONFIG_DEPENDENCIES"
        ${ARGN}
    )
    if(DEFINED _arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments were passed to liri_add_module (${_arg_UNPARSED_ARGUMENTS}).")
    endif()

    # A 0.x version is going to be 1.x once it's ready, but we don't
    # want to change find_package(Liri0${name}) instructions everywhere
    # when that happens
    if(${PROJECT_VERSION_MAJOR} EQUAL 0)
        set(_module_version 1)
    else()
        set(_module_version ${PROJECT_VERSION_MAJOR})
    endif()

    # Various ways to call this module
    if(_arg_MODULE_NAME)
        set(module "${_arg_MODULE_NAME}")
    else()
        set(module "Liri${name}")
    endif()
    if(_arg_VERSIONED_MODULE_NAME)
        set(_versioned_name "${_arg_VERSIONED_MODULE_NAME}")
    else()
        set(_versioned_name "Liri${_module_version}${name}")
    endif()
    set(target "${name}")
    string(TOUPPER "${name}" name_upper)
    string(REGEX REPLACE "-" "_" name_upper "${name_upper}")
    string(TOLOWER "${name}" name_lower)

    # Default description
    if(NOT _arg_DESCRIPTION)
        set(_arg_DESCRIPTION "${_versioned_name} library")
    endif()

    ## Target:

    # Add target for the public API
    if(${_arg_STATIC})
        add_library("${target}" STATIC ${_arg_SOURCES})
    else()
        add_library("${target}" SHARED ${_arg_SOURCES})
    endif()
    add_library("Liri::${target}" ALIAS "${target}")
    set_target_properties("${target}" PROPERTIES LIRI_TARGET_TYPE "module")

    # Output file name and version
    set_target_properties("${target}"
        PROPERTIES
            OUTPUT_NAME "${_versioned_name}"
            VERSION "${PROJECT_VERSION}"
            SOVERSION "${_module_version}"
    )

    # Add target for the private API
    set(target_private "${target}Private")
    add_library("${target_private}" INTERFACE)
    add_library("Liri::${target_private}" ALIAS "${target_private}")

    # Local include directory
    set(_parent_include_dir "${PROJECT_BINARY_DIR}/include")
    set(_include_dir "${_parent_include_dir}/${module}")
    set(_private_include_dir "${_include_dir}/${PROJECT_VERSION}/${module}/private")

    # Extend the target
    liri_extend_target("${target}"
        PUBLIC_INCLUDE_DIRECTORIES
            "$<BUILD_INTERFACE:${_parent_include_dir}>"
            "$<INSTALL_INTERFACE:include>"
            ${_arg_PUBLIC_INCLUDE_DIRECTORIES}
        INCLUDE_DIRECTORIES
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${CMAKE_CURRENT_BINARY_DIR}"
            "$<BUILD_INTERFACE:${_parent_include_dir}>"
            "${_include_dir}/${PROJECT_VERSION}"
            "${_include_dir}/${PROJECT_VERSION}/${module}"
            ${_arg_INCLUDE_DIRECTORIES}
        PUBLIC_DEFINES
            ${_arg_PUBLIC_DEFINES}
            LIRI_${name_upper}_LIB
        DEFINES
            QT_NO_CAST_TO_ASCII QT_ASCII_CAST_WARNINGS
            QT_USE_QSTRINGBUILDER
            QT_DEPRECATED_WARNINGS
            ${_arg_DEFINES}
        EXPORT_IMPORT_CONDITION
            LIRI_BUILD_${name_upper}_LIB
        PUBLIC_LIBRARIES ${_arg_PUBLIC_LIBRARIES}
        LIBRARIES ${_arg_LIBRARIES}
        RESOURCES ${_arg_RESOURCES}
        DBUS_ADAPTOR_SOURCES ${_arg_DBUS_ADAPTOR_SOURCES}
        DBUS_ADAPTOR_FLAGS ${_arg_DBUS_ADAPTOR_FLAGS}
        DBUS_INTERFACE_SOURCES ${_arg_DBUS_INTERFACE_SOURCES}
        DBUS_INTERFACE_FLAGS ${_arg_DBUS_INTERFACE_FLAGS}
        GLOBAL_HEADER_CONTENT ${_arg_GLOBAL_HEADER_CONTENT}
        PRIVATE_HEADERS ${_arg_PRIVATE_HEADERS}
        CLASS_HEADERS ${_arg_CLASS_HEADERS}
        INSTALL_HEADERS ${_arg_INSTALL_HEADERS}
        PKGCONFIG_DEPENDENCIES ${_arg_PKGCONFIG_DEPENDENCIES}
    )

    # Set custom properties
    set_target_properties("${target}" PROPERTIES LIRI_MODULE_DESCRIPTION "${_arg_DESCRIPTION}")
    set_target_properties("${target}" PROPERTIES LIRI_MODULE_NAME "${module}")
    set_target_properties("${target}" PROPERTIES LIRI_MODULE_VERSIONED_NAME "${_versioned_name}")
    if(NOT _arg_NO_MODULE_HEADERS)
        set_target_properties("${target}" PROPERTIES LIRI_MODULE_HAS_HEADERS ON)
    else()
        set_target_properties("${target}" PROPERTIES LIRI_MODULE_HAS_HEADERS OFF)
    endif()
    set_target_properties("${target}" PROPERTIES
        LIRI_MODULE_PARENT_INCLUDE_DIR "${_parent_include_dir}"
        LIRI_MODULE_INCLUDE_DIR "${_include_dir}"
        LIRI_MODULE_PRIVATE_INCLUDE_DIR "${_private_include_dir}"
    )
    if(NOT _arg_NO_CMAKE)
        set_target_properties("${target}" PROPERTIES LIRI_MODULE_HAS_CMAKE ON)
    else()
        set_target_properties("${target}" PROPERTIES LIRI_MODULE_HAS_CMAKE OFF)
    endif()
    if(NOT _arg_NO_PKGCONFIG)
        set_target_properties("${target}" PROPERTIES LIRI_MODULE_HAS_PKGCONFIG ON)
    else()
        set_target_properties("${target}" PROPERTIES LIRI_MODULE_HAS_PKGCONFIG OFF)
    endif()
    if(_arg_QTQUICK_COMPILER)
        set_target_properties("${target}" PROPERTIES LIRI_ENABLE_QTQUICK_COMPILER ON)
    else()
        set_target_properties("${target}" PROPERTIES LIRI_ENABLE_QTQUICK_COMPILER OFF)
    endif()

    # Setup the private target
    target_include_directories("${target_private}" INTERFACE
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>"
        "$<BUILD_INTERFACE:${_include_dir}/${PROJECT_VERSION}>"
        "$<BUILD_INTERFACE:${_include_dir}/${PROJECT_VERSION}/${module}>"
        "$<INSTALL_INTERFACE:include/${module}/${PROJECT_VERSION}>"
        "$<INSTALL_INTERFACE:include/${module}/${PROJECT_VERSION}/${module}>"
        "$<INSTALL_INTERFACE:include/${module}/${PROJECT_VERSION}/${module}/private>"
    )

    # Headers
    if(_arg_NO_MODULE_HEADERS)
        # At least reference source code directories, this is particularly
        # indicated for those static modules that we don't want to
        # install nor generate headers for
        target_include_directories("${target}" INTERFACE
            "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
            "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>"
        )
    endif()

    # Install targets
    install(
        TARGETS "${target}" "${target_private}"
        EXPORT "${_versioned_name}Targets"
        LIBRARY DESTINATION "${INSTALL_LIBDIR}"
        ARCHIVE DESTINATION "${INSTALL_LIBDIR}"
        PUBLIC_HEADER DESTINATION "${INSTALL_INCLUDEDIR}/${module}"
        PRIVATE_HEADER DESTINATION "${INSTALL_INCLUDEDIR}/${module}/${PROJECT_VERSION}/${module}/private"
    )
endfunction()

function(liri_finalize_module target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "Trying to extend non-existing target \"${target}\".")
    endif()

    get_target_property(_name "${target}" LIRI_MODULE_NAME)
    string(TOLOWER "${_name}" _name_lower)
    string(TOUPPER "${_name}" _name_upper)
    get_target_property(_target_version "${target}" VERSION)
    get_target_property(_versioned_name "${target}" LIRI_MODULE_VERSIONED_NAME)
    get_target_property(_description "${target}" LIRI_MODULE_DESCRIPTION)
    get_target_property(_has_headers "${target}" LIRI_MODULE_HAS_HEADERS)
    get_target_property(_has_cmake "${target}" LIRI_MODULE_HAS_CMAKE)
    get_target_property(_has_pkgconfig "${target}" LIRI_MODULE_HAS_PKGCONFIG)
    get_target_property(_source_files "${target}" SOURCES)
    get_target_property(_libraries "${target}" LIBRARIES)
    get_target_property(_include_dir "${target}" LIRI_MODULE_INCLUDE_DIR)
    get_target_property(_private_include_dir "${target}" LIRI_MODULE_PRIVATE_INCLUDE_DIR)

    include(CMakePackageConfigHelpers)
    include(ECMGenerateHeaders)
    include(ECMGenerateExportHeader)
    include(ECMGeneratePkgConfigFile)

    # Common target setup code
    liri_finalize_target("${target}")

    # Module headers
    if(_has_headers)
        get_target_property(_module_install_headers "${target}" LIRI_MODULE_INSTALL_HEADERS)
        get_target_property(_module_private_headers "${target}" LIRI_MODULE_PRIVATE_HEADERS)
        get_target_property(_module_classname_headers "${target}" LIRI_MODULE_CLASS_HEADERS)

        # Prepare the list of headers to forward
        if(_module_install_headers MATCHES "NOTFOUND")
            set(_install_headers "")
        else()
            set(_install_headers "${_module_install_headers}")
        endif()
        if(_module_private_headers MATCHES "NOTFOUND")
            set(_private_headers "")
        else()
            set(_private_headers "${_module_private_headers}")
        endif()
        if(_module_classname_headers MATCHES "NOTFOUND")
            set(_classname_headers "")
        else()
            set(_classname_headers "${_module_classname_headers}")
        endif()
        foreach(_source_file IN LISTS _source_files)
            get_filename_component(_basename "${_source_file}" NAME_WLE)
            get_filename_component(_ext "${_source_file}" EXT)
            get_property(_liri_private_header SOURCE "${_source_file}" PROPERTY LIRI_PRIVATE_HEADER SET)

            if("${_ext}" STREQUAL ".h")
                set(_is_header ON)
            else()
                set(_is_header OFF)
            endif()

            if(_liri_private_header OR "${_basename}" MATCHES "_p$")
                set(_is_private ON)
            else()
                set(_is_private OFF)
            endif()

            if(_is_header)
                # Public headers
                if(NOT _is_private AND NOT _module_install_headers)
                    list(APPEND _install_headers "${_source_file}")
                endif()

                # Private headers
                if(_is_private AND NOT _module_private_headers)
                    list(APPEND _private_headers "${_source_file}")
                endif()

                # Class-name headers
                if(NOT IS_ABSOLUTE "${_source_file}")
                    set(_source_file "${CMAKE_CURRENT_SOURCE_DIR}/${_source_file}")
                endif()
                if(NOT _is_private AND EXISTS "${_source_file}")
                    execute_process(
                        COMMAND python3 ${_fwd_headers_exe} "${_source_file}"
                        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                        OUTPUT_VARIABLE _fwd_headers_out
                        RESULT_VARIABLE _fwd_headers_ret
                     )
                     string(STRIP "${_fwd_headers_out}" _fwd_headers_out)
                     if(NOT _fwd_headers_ret EQUAL 0)
                         message(FATAL_ERROR "Failed to run detect-class-headers, return code: ${_fwd_headers_ret}")
                     endif()
                     if(NOT _fwd_headers_out STREQUAL "")
                         list(APPEND _classname_headers "${_fwd_headers_out}")
                     endif()
                endif()
            endif()
        endforeach()

        # Forward private headers
        foreach(_private_header IN LISTS _private_headers)
            get_filename_component(_filename "${_private_header}" NAME)

            if(NOT IS_ABSOLUTE "${_private_header}")
                set(_private_header "${CMAKE_CURRENT_SOURCE_DIR}/${_private_header}")
            endif()
            file(GENERATE OUTPUT "${_private_include_dir}/${_filename}" CONTENT "#include \"${_private_header}\"\n" TARGET "${target}")
            install(FILES "${_private_header}"
                    DESTINATION "${INSTALL_INCLUDEDIR}/${_name}/${_target_version}/${_name}/private"
                    COMPONENT Devel)
        endforeach()

        # Forward public headers
        foreach(_install_header IN LISTS _install_headers)
            get_filename_component(_filename "${_install_header}" NAME)

            if(NOT IS_ABSOLUTE "${_install_header}")
                set(_install_header "${CMAKE_CURRENT_SOURCE_DIR}/${_install_header}")
            endif()
            file(GENERATE OUTPUT "${_include_dir}/${_filename}" CONTENT "#include \"${_install_header}\"\n" TARGET "${target}")
            install(FILES "${_install_header}"
                    DESTINATION "${INSTALL_INCLUDEDIR}/${_name}"
                    COMPONENT Devel)
        endforeach()

        if(_classname_headers)
            # Public headers and forward headers
            _liri_internal_forward_headers(
                ${target}_CLASS_HEADERS
                OUTPUT_DIR "${_include_dir}"
                HEADER_NAMES ${_classname_headers}
                MODULE_NAME "${_name}"
            )
            install(FILES ${${target}_CLASS_HEADERS}
                    DESTINATION "${INSTALL_INCLUDEDIR}/${_name}"
                    COMPONENT Devel)
        endif()

        # Version header
        set(_version_header "${_include_dir}/${_name_lower}version.h")
        configure_file(
            "${_LIRI_VERSION_HEADER_TEMPLATE}"
            "${_version_header}"
            @ONLY
        )
        set_property(SOURCE "${_version_header}" PROPERTY GENERATED ON)
        target_sources("${target}" PRIVATE "${_version_header}")
        install(FILES "${_version_header}"
                DESTINATION "${INSTALL_INCLUDEDIR}/${_name}"
                COMPONENT Devel)

        # Generate global header
        set(_global_header "${_include_dir}/${_name_lower}global.h")
        get_target_property(_global_header_content "${target}" LIRI_MODULE_GLOBAL_HEADER_CONTENT)
        if(_global_header_content MATCHES "NOTFOUND")
            set(_global_header_content "")
        else()
            set(_global_header_content "${_global_header_content}\n")
        endif()
        ecm_generate_export_header("${target}"
            VERSION "${_target_version}"
            BASE_NAME "${_name_lower}"
            EXPORT_FILE_NAME "${_global_header}"
            CUSTOM_CONTENT_FROM_VARIABLE "${_global_header_content}"
        )
        set_property(SOURCE "${_global_header}" PROPERTY GENERATED ON)
        target_sources("${target}" PRIVATE "${_global_header}")
        install(FILES "${_global_header}"
                DESTINATION "${INSTALL_INCLUDEDIR}/${_name}"
                COMPONENT Devel)
    endif()

    # CMake package generation
    if(_has_cmake)
        set(_config_install_dir "${INSTALL_LIBDIR}/cmake/${_versioned_name}")

        install(
            EXPORT "${_versioned_name}Targets"
            NAMESPACE Liri::
            DESTINATION ${_config_install_dir}
        )

        configure_package_config_file(
            "${_LIRI_MODULE_CONFIG_TEMPLATE}"
            "${CMAKE_CURRENT_BINARY_DIR}/${_versioned_name}Config.cmake"
            INSTALL_DESTINATION "${_config_install_dir}"
        )
        write_basic_package_version_file(
            ${CMAKE_CURRENT_BINARY_DIR}/${_versioned_name}ConfigVersion.cmake
            VERSION "${_target_version}"
            COMPATIBILITY AnyNewerVersion
        )

        set(_extra_cmake_files)
        if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${_versioned_name}Dependencies.cmake")
            list(APPEND _extra_cmake_files "${CMAKE_CURRENT_BINARY_DIR}/${_versioned_name}Dependencies.cmake")
        elseif(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${_versioned_name}Dependencies.cmake")
            list(APPEND _extra_cmake_files "${CMAKE_CURRENT_LIST_DIR}/${_versioned_name}Dependencies.cmake")
        endif()
        if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${_versioned_name}Macros.cmake")
            list(APPEND _extra_cmake_files "${CMAKE_CURRENT_LIST_DIR}/${_versioned_name}Macros.cmake")
        endif()

        install(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${_versioned_name}Config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${_versioned_name}ConfigVersion.cmake"
            ${_extra_cmake_files}
            DESTINATION "${_config_install_dir}"
            COMPONENT Devel
        )
    endif()

    # Generate pkg-config file
    if(_has_pkgconfig)
        get_target_property(_defines "${target}" PUBLIC_DEFINES)
        get_target_property(_deps "${target}" LIRI_MODULE_PKGCONFIG_DEPENDENCIES)

        ecm_generate_pkgconfig_file(
            BASE_NAME "${_versioned_name}"
            DESCRIPTION "${_description}"
            DEFINES ${_defines}
            DEPS ${_deps}
            FILENAME_VAR _pkgconfig_filename
            INCLUDE_INSTALL_DIR "${INSTALL_INCLUDEDIR}"
            LIB_INSTALL_DIR "${INSTALL_LIBDIR}"
        )
        set_property(SOURCE "${_pkgconfig_filename}" PROPERTY GENERATED ON)
        install(FILES "${_pkgconfig_filename}"
                DESTINATION "${INSTALL_LIBDIR}/pkgconfig")
    endif()
endfunction()
