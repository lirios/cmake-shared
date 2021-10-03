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

    # Include other functions and macros
    include(CMakePackageConfigHelpers)
    include(ECMGenerateHeaders)
    include(GenerateExportHeader)
    include(ECMGeneratePkgConfigFile)

    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_add_module"
        "NO_MODULE_HEADERS;NO_CMAKE;NO_PKGCONFIG;STATIC"
        "DESCRIPTION;MODULE_NAME;VERSIONED_MODULE_NAME;QTQUICK_COMPILER"
        "${__default_private_args};${__default_public_args};INSTALL_HEADERS;FORWARDING_HEADERS;PRIVATE_HEADERS;PKGCONFIG_DEPENDENCIES"
        ${ARGN}
    )

    # A 0.x version is going to be 1.x once it's ready, but we don't
    # want to change find_package(Liri0${name}) instructions everywhere
    # when that happens
    if(${PROJECT_VERSION_MAJOR} EQUAL 0)
        set(_module_version 1)
    else()
        set(_module_version ${PROJECT_VERSION_MAJOR})
    endif()

    # Various ways to call this module
    if(DEFINED _arg_MODULE_NAME)
        set(module "${_arg_MODULE_NAME}")
    else()
        _liri_module_name("${name}" module)
    endif()
    string(TOUPPER "${module}" module_upper)
    string(TOLOWER "${module}" module_lower)
    if(DEFINED _arg_VERSIONED_MODULE_NAME)
        set(versioned_module_name "${_arg_VERSIONED_MODULE_NAME}")
    else()
        set(versioned_module_name "Liri${_module_version}${name}")
    endif()
    set(target "${name}")
    string(TOUPPER "${name}" name_upper)
    string(REGEX REPLACE "-" "_" name_upper "${name_upper}")
    string(TOLOWER "${name}" name_lower)

    if(NOT _arg_DESCRIPTION)
        set(_arg_DESCRIPTION "${versioned_module_name} library")
    endif()

    ## Target:

    # Add target for the public API
    if(${_arg_STATIC})
        add_library("${target}" STATIC)
    else()
        add_library("${target}" SHARED)
    endif()
    add_library("Liri::${target}" ALIAS "${target}")

    # Add resources
    if(DEFINED _arg_RESOURCES)
        if(${_arg_QTQUICK_COMPILER})
            find_package(Qt5QuickCompiler)
            if(Qt5QuickCompiler_FOUND)
                qtquick_compiler_add_resources(RESOURCES ${_arg_RESOURCES})
                list(APPEND _arg_SOURCES ${_arg_RESOURCES})
            else()
                message(WARNING "Qt5QuickCompiler not found, fall back to standard resources")
                qt5_add_resources(RESOURCES ${_arg_RESOURCES})
            endif()
        else()
            qt5_add_resources(RESOURCES ${_arg_RESOURCES})
        endif()
        list(APPEND _arg_SOURCES ${RESOURCES})
    endif()

    # Add target for the private API
    set(target_private "${target}Private")
    add_library("${target_private}" INTERFACE)
    add_library("Liri::${target_private}" ALIAS "${target_private}")

    if(NOT ${_arg_NO_MODULE_HEADERS})
        set_target_properties("${target}" PROPERTIES MODULE_HAS_HEADERS ON)
    else()
        set_target_properties("${target}" PROPERTIES MODULE_HAS_HEADERS OFF)
    endif()

    set_target_properties("${target}" PROPERTIES OUTPUT_NAME "${versioned_module_name}")

    # Local include directory
    set(parent_include_dir "${PROJECT_BINARY_DIR}/include")
    set(include_dir "${parent_include_dir}/${module}")

    # Setup the public target
    liri_extend_target("${target}"
        SOURCES ${_arg_SOURCES}
        PUBLIC_INCLUDE_DIRECTORIES
            "$<BUILD_INTERFACE:${parent_include_dir}>"
            "$<INSTALL_INTERFACE:include>"
            ${_arg_PUBLIC_INCLUDE_DIRECTORIES}
        INCLUDE_DIRECTORIES
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${CMAKE_CURRENT_BINARY_DIR}"
            "$<BUILD_INTERFACE:${parent_include_dir}>"
            "${include_dir}/${PROJECT_VERSION}"
            "${include_dir}/${PROJECT_VERSION}/${module}"
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
        DBUS_ADAPTOR_SOURCES ${_arg_DBUS_ADAPTOR_SOURCES}
        DBUS_ADAPTOR_FLAGS ${_arg_DBUS_ADAPTOR_FLAGS}
        DBUS_INTERFACE_SOURCES ${_arg_DBUS_INTERFACE_SOURCES}
        DBUS_INTERFACE_FLAGS ${_arg_DBUS_INTERFACE_FLAGS}
    )

    set_target_properties("${target}"
        PROPERTIES
            VERSION "${PROJECT_VERSION}"
            SOVERSION "${_module_version}"
    )

    # Setup the private target
    target_include_directories("${target_private}" INTERFACE
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>"
        "$<BUILD_INTERFACE:${include_dir}/${PROJECT_VERSION}>"
        "$<BUILD_INTERFACE:${include_dir}/${PROJECT_VERSION}/${module}>"
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
    else()
        # Automatically generate the list of private headers
        if(NOT DEFINED _arg_PRIVATE_HEADERS)
            set(_private_headers)

            foreach(_source_file IN LISTS _arg_SOURCES)
                get_filename_component(directory "${_source_file}" DIRECTORY)
                get_filename_component(filename "${_source_file}" NAME)
                get_filename_component(basename "${_source_file}" NAME_WLE)
                get_filename_component(ext "${_source_file}" EXT)

                string(COMPARE EQUAL "${ext}" ".h" is_header)
                string(REGEX MATCH "_p$" is_private "${basename}")

                if(is_header AND is_private)
                    list(APPEND _private_headers "${CMAKE_CURRENT_SOURCE_DIR}/${directory}/${filename}")
                endif()
            endforeach()

            if(_private_headers)
                set(_arg_PRIVATE_HEADERS "${_private_headers}")
            endif()
        endif()

        if(DEFINED _arg_FORWARDING_HEADERS)
            # Public headers and forward headers
            ecm_generate_headers(
                ${target}_FORWARDING_HEADERS
                PREFIX "."
                OUTPUT_DIR "${include_dir}"
                HEADER_NAMES ${_arg_FORWARDING_HEADERS}
                REQUIRED_HEADERS ${target}_REQUIRED_HEADERS
                COMMON_HEADER "${module}"
            )
        endif()

        # Version header
        configure_file(
            "${_LIRI_VERSION_HEADER_TEMPLATE}"
            "${include_dir}/${module_lower}version.h"
            @ONLY
        )

        # Forward export header
        generate_export_header("${target}"
            BASE_NAME "${module_lower}"
            EXPORT_FILE_NAME "${include_dir}/${module_lower}global.h")

        # Forward headers to install
        if(DEFINED _arg_INSTALL_HEADERS)
            foreach(_header_filename ${_arg_INSTALL_HEADERS})
                get_filename_component(_base_header_filename "${_header_filename}" NAME)
                set(_fwd_header_filename "${include_dir}/${_base_header_filename}")
                file(WRITE "${_fwd_header_filename}" "#include \"${CMAKE_CURRENT_SOURCE_DIR}/${_header_filename}\"")
            endforeach()
        endif()

        # Forward private headers
        if(DEFINED _arg_PRIVATE_HEADERS)
            # Generate
            foreach(_header_filename ${_arg_PRIVATE_HEADERS})
                if(NOT IS_ABSOLUTE "${_header_filename}")
                    set(_header_filename "${CMAKE_CURRENT_SOURCE_DIR}/${_header_filename}")
                endif()
                get_filename_component(_base_header_filename "${_header_filename}" NAME)
                set(_fwd_header_filename "${include_dir}/${PROJECT_VERSION}/${module}/private/${_base_header_filename}")
                file(WRITE "${_fwd_header_filename}" "#include \"${_header_filename}\"")
            endforeach()

            # Install
            install(FILES ${_arg_PRIVATE_HEADERS}
                    DESTINATION "${INSTALL_INCLUDEDIR}/${module}/${PROJECT_VERSION}/${module}/private"
                    COMPONENT Devel)
        endif()

        # Install public headers
        install(
            FILES
                ${_arg_INSTALL_HEADERS}
                ${${target}_FORWARDING_HEADERS}
                ${${target}_REQUIRED_HEADERS}
                "${include_dir}/${module_lower}version.h"
                "${include_dir}/${module_lower}global.h"
            DESTINATION
                "${INSTALL_INCLUDEDIR}/${module}"
            COMPONENT
                Devel
        )
    endif()

    # Install CMake target
    install(
        TARGETS "${target}" "${target_private}"
        EXPORT "${versioned_module_name}Targets"
        LIBRARY DESTINATION "${INSTALL_LIBDIR}"
        ARCHIVE DESTINATION "${INSTALL_LIBDIR}"
        PUBLIC_HEADER DESTINATION "${INSTALL_INCLUDEDIR}/${module}"
        PRIVATE_HEADER DESTINATION "${INSTALL_INCLUDEDIR}/${module}/${PROJECT_VERSION}/${module}/private"
    )

    ## CMake package generation:
    if(NOT ${_arg_NO_CMAKE})
        set(config_install_dir "${INSTALL_LIBDIR}/cmake/${versioned_module_name}")
        install(
            EXPORT "${versioned_module_name}Targets"
            NAMESPACE Liri::
            DESTINATION ${config_install_dir}
        )

        configure_package_config_file(
            "${_LIRI_MODULE_CONFIG_TEMPLATE}"
            "${CMAKE_CURRENT_BINARY_DIR}/${versioned_module_name}Config.cmake"
            INSTALL_DESTINATION "${config_install_dir}"
        )
        write_basic_package_version_file(
            ${CMAKE_CURRENT_BINARY_DIR}/${versioned_module_name}ConfigVersion.cmake
            VERSION ${PROJECT_VERSION}
            COMPATIBILITY AnyNewerVersion
        )

        set(extra_cmake_files)
        if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${versioned_module_name}Macros.cmake")
            list(APPEND extra_cmake_files "${CMAKE_CURRENT_LIST_DIR}/${versioned_module_name}Macros.cmake")
        endif()

        install(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${versioned_module_name}Config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${versioned_module_name}ConfigVersion.cmake"
            ${extra_cmake_files}
            DESTINATION "${config_install_dir}"
            COMPONENT Devel
        )
    endif()

    # Generate pkg-config file
    if(NOT ${_arg_NO_PKGCONFIG})
        get_target_property(_pkgconfig_public_defines "${target}" "PUBLIC_DEFINES")

        ecm_generate_pkgconfig_file(
            BASE_NAME "${versioned_module_name}"
            DESCRIPTION ${_arg_DESCRIPTION}
            DEFINES ${_pkgconfig_public_defines}
            DEPS ${_arg_PKGCONFIG_DEPENDENCIES}
            FILENAME_VAR _pkgconfig_filename
            INCLUDE_INSTALL_DIR "${INSTALL_INCLUDEDIR}"
            LIB_INSTALL_DIR "${INSTALL_LIBDIR}"
        )
        install(FILES "${_pkgconfig_filename}"
                DESTINATION "${INSTALL_LIBDIR}/pkgconfig")
    endif()
endfunction()
