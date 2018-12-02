# Save the location of some templates while CMAKE_CURRENT_LIST_DIR has the value we want:
set(_LIRI_VERSION_HEADER_TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/LiriModuleVersion.h.in")
set(_LIRI_MODULE_CONFIG_TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/LiriModuleConfig.cmake.in")

# Install locations:
set(INSTALL_BINDIR "bin" CACHE PATH "Executables [PREFIX/bin]")
set(INSTALL_INCLUDEDIR "include" CACHE PATH "Header files [PREFIX/include]")
set(INSTALL_LIBDIR "lib" CACHE PATH "Libraries [PREFIX/lib]")
set(INSTALL_PLUGINSDIR "${INSTALL_LIBDIR}/plugins" CACHE PATH
    "Plugins [LIBDIR/plugins]")
set(INSTALL_LIBEXECDIR "libexec" CACHE PATH "Helper programs [PREFIX/libexec]")
set(INSTALL_QMLDIR "${INSTALL_LIBDIR}/qml" CACHE PATH "QML2 imports [LIBDIR/qml]")
set(INSTALL_DATADIR "share" CACHE PATH  "Arch-independent data [PREFIX/share]")
set(INSTALL_APPLICATIONSDIR "share/applications" CACHE PATH
    "Desktop entries [PREFIX/share/applications]")
set(INSTALL_METAINFODIR "share/metainfo" CACHE PATH
    "AppStream metadata [PREFIX/share/metainfo]")
set(INSTALL_DOCDIR "${INSTALL_DATADIR}/doc" CACHE PATH "Documentation [DATADIR/doc]")
set(INSTALL_SYSCONFDIR "etc" CACHE PATH "Settings used by Liri programs [PREFIX/etc]")

# Make Qt Creator QML syntax highlighting aware of our modules:
set(QML_IMPORT_PATH "${CMAKE_INSTALL_PREFIX}/${INSTALL_QMLDIR}" CACHE PATH
    "QML import path for Qt Creator")

# Set default installation paths for some targets:
set(INSTALL_TARGETS_DEFAULT_ARGS
    RUNTIME DESTINATION "${INSTALL_BINDIR}"
    LIBRARY DESTINATION "${INSTALL_LIBDIR}"
    ARCHIVE DESTINATION "${INSTALL_LIBDIR}" COMPONENT Devel
    INCLUDES DESTINATION "${INSTALL_INCLUDEDIR}"
)

# For adjusting variables when running tests, we need to know what
# the correct variable is for separating entries in PATH-alike
# variables.
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(LIRI_PATH_SEPARATOR "\\;")
else()
    set(LIRI_PATH_SEPARATOR ":")
endif()


# Functions and macros:


# Print all variables defined in the current scope.
macro(_debug_print_variables)
    cmake_parse_arguments(__arg "DEDUP" "" "MATCH;IGNORE" ${ARGN})
    message("Known Variables:")
    get_cmake_property(__variableNames VARIABLES)
    list (SORT __variableNames)
    if (__arg_DEDUP)
        list(REMOVE_DUPLICATES __variableNames)
    endif()

    foreach(__var ${__variableNames})
        set(__ignore OFF)
        foreach(__i ${__arg_IGNORE})
            if(__var MATCHES "${__i}")
                set(__ignore ON)
                break()
            endif()
        endforeach()

        if (__ignore)
            continue()
        endif()

        set(__show OFF)
        foreach(__i ${__arg_MATCH})
            if(__var MATCHES "${__i}")
                set(__show ON)
                break()
            endif()
        endforeach()

        if (__show)
            message("    ${__var}=${${__var}}.")
        endif()
    endforeach()
endmacro()


macro(assert)
    if (${ARGN})
    else()
        message(FATAL_ERROR "ASSERT: ${ARGN}.")
    endif()
endmacro()


# A version of cmake_parse_arguments that makes sure all arguments are processed and errors out
# with a message about ${type} having received unknown arguments.
macro(_liri_parse_all_arguments result type flags options multiopts)
    cmake_parse_arguments(${result} "${flags}" "${options}" "${multiopts}" ${ARGN})
    if(DEFINED ${result}_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments were passed to ${type} (${${result}_UNPARSED_ARGUMENTS}).")
    endif()
endmacro()


function(_liri_module_name name result)
    set("${result}" "Liri${name}" PARENT_SCOPE)
endfunction()


function(_qdbusxml2cpp_command target infile)
    _liri_parse_all_arguments(
        _arg "_qdbusxml2cpp_command"
        "ADAPTOR;INTERFACE"
        ""
        "FLAGS"
        ${ARGN}
    )

    if((_arg_ADAPTOR AND _arg_INTERFACE) OR (NOT _arg_ADAPTOR AND NOT _arg_INTERFACE))
        message(FATAL_ERROR "_qdbusxml2cpp_command needs either ADAPTOR or INTERFACE.")
    endif()

    set(_option "-a")
    set(_type "adaptor")
    if(_arg_INTERFACE)
        set(_option "-p")
        set(_type "interface")
    endif()

    # Determine the base name by removing .xml extension and taking
    # the last extension
    get_filename_component(_basename "${infile}" NAME)
    string(TOLOWER "${_basename}" _basename)
    string(REGEX REPLACE "(.*\\.)?([^\\.]+)\\.xml" "\\2" _basename "${_basename}")

    set(_header_filename "${CMAKE_CURRENT_BINARY_DIR}/${_basename}_${_type}.h")
    set(_source_filename "${CMAKE_CURRENT_BINARY_DIR}/${_basename}_${_type}.cpp")

    add_custom_command(
        OUTPUT "${_header_filename}" "${_source_filename}"
        COMMAND Qt5::qdbusxml2cpp ${_arg_FLAGS} "${_option}" "${_header_filename}:${_source_filename}" "${infile}"
        DEPENDS "${infile}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        VERBATIM
    )

    qt5_wrap_cpp(_moc_sources TARGET "${target}" "${_header_filename}")
    set_source_files_properties("${_moc_sources}" PROPERTIES HEADER_FILE_ONLY OFF)
    target_sources("${target}" PRIVATE "${_header_filename}" "${_source_filename}" "${_moc_sources}")
endfunction()


set(__default_private_args "SOURCES;LIBRARIES;INCLUDE_DIRECTORIES;DEFINES;RESOURCES;DBUS_ADAPTOR_FLAGS;DBUS_ADAPTOR_SOURCES;DBUS_INTERFACE_FLAGS;DBUS_INTERFACE_SOURCES")
set(__default_public_args "PUBLIC_LIBRARIES;PUBLIC_INCLUDE_DIRECTORIES;PUBLIC_DEFINES")


# This function can be used to add sources/libraries/etc. to the specified CMake target
# if the provided CONDITION evaluates to true.
function(extend_target target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "Trying to extend non-existing target \"${target}\".")
    endif()
    _liri_parse_all_arguments(
        _arg "extend_target"
        ""
        "EXPORT_IMPORT_CONDITION"
        "${__default_public_args};${__default_private_args};COMPILE_FLAGS"
        ${ARGN}
    )

    set(dbus_sources "")
    foreach(adaptor ${_arg_DBUS_ADAPTOR_SOURCES})
        _qdbusxml2cpp_command("${target}" "${adaptor}" ADAPTOR FLAGS "${_arg_DBUS_ADAPTOR_FLAGS}")
        list(APPEND dbus_sources "${sources}")
    endforeach()
    foreach(interface ${_arg_DBUS_INTERFACE_SOURCES})
        _qdbusxml2cpp_command("${target}" "${interface}" INTERFACE FLAGS "${_arg_DBUS_INTERFACE_FLAGS}")
        list(APPEND dbus_sources "${sources}")
    endforeach()
    if(_arg_DBUS_ADAPTOR_SOURCES OR _arg_DBUS_INTERFACE_SOURCES)
        # This implicitely requires Qt5::DBus
        list(FIND _arg_LIBRARIES "Qt5::DBus" _qt5_dbus_index)
        if(${_qt5_dbus_index} EQUAL -1)
            find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS DBus)
            message(STATUS "Adding Qt5::DBus target to ${target}")
            list(APPEND _arg_LIBRARIES "Qt5::DBus")
        endif()
    endif()

    target_sources("${target}" PRIVATE ${_arg_SOURCES} ${dbus_sources})
    if(DEFINED _arg_COMPILE_FLAGS)
        set_source_files_properties(${_arg_SOURCES} PROPERTIES COMPILE_FLAGS "${_arg_COMPILE_FLAGS}")
    endif()
    if(DEFINED _arg_EXPORT_IMPORT_CONDITION)
        set_target_properties("${target}" PROPERTIES DEFINE_SYMBOL "${_arg_EXPORT_IMPORT_CONDITION}")
    endif()
    target_include_directories("${target}" PUBLIC ${_arg_PUBLIC_INCLUDE_DIRECTORIES} PRIVATE ${_arg_INCLUDE_DIRECTORIES})
    target_compile_definitions("${target}" PUBLIC ${_arg_PUBLIC_DEFINES} PRIVATE ${_arg_DEFINES})
    target_link_libraries("${target}" PUBLIC ${_arg_PUBLIC_LIBRARIES} PRIVATE ${_arg_LIBRARIES})
endfunction()


# This is the main entry function for creating a Liri module, that typically
# consists of a library, public header files and private header files.
#
# A CMake target with the specified name parameter is created.
#
# Liri modules provide also a way to be used by other build systems,
# in the form of a CMake package and pkg-config file.
function(liri_add_module name)
    # Include other functions and macros
    include(CMakePackageConfigHelpers)
    include(ECMGenerateHeaders)
    include(GenerateExportHeader)
    include(ECMGeneratePkgConfigFile)

    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_add_module"
        "NO_MODULE_HEADERS;NO_CMAKE;NO_PKGCONFIG;STATIC"
        "DESCRIPTION;MODULE_NAME;VERSIONED_MODULE_NAME"
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
    extend_target("${target}"
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
    if(NOT ${_arg_NO_MODULE_HEADERS})
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
                get_filename_component(_base_header_filename "${_header_filename}" NAME)
                set(_fwd_header_filename "${include_dir}/${PROJECT_VERSION}/${module}/private/${_base_header_filename}")
                file(WRITE "${_fwd_header_filename}" "#include \"${CMAKE_CURRENT_SOURCE_DIR}/${_header_filename}\"")
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


# This function creates a CMake target for a generic console or GUI binary.
# Please consider to use a more specific version target like the one created
# by liri_add_test or add_qt_tool below.
function(liri_add_executable name)
    # Find packages we need
    find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS Core)

    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_add_executable"
        "GUI;NO_TARGET_INSTALLATION"
        "OUTPUT_NAME;OUTPUT_DIRECTORY;INSTALL_DIRECTORY;DESKTOP_INSTALL_DIRECTORY"
        "EXE_FLAGS;${__default_private_args};APPDATA;DESKTOP"
        ${ARGN}
    )

    if("x${_arg_OUTPUT_NAME}" STREQUAL "x")
        set(_arg_OUTPUT_NAME "${name}")
    endif()

    if ("x${_arg_OUTPUT_DIRECTORY}" STREQUAL "x")
        set(_arg_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${INSTALL_BINDIR}")
    endif()

    add_executable("${name}" ${_arg_EXE_FLAGS})
    if(DEFINED _arg_RESOURCES)
        qt5_add_resources(RESOURCES ${_arg_RESOURCES})
        list(APPEND _arg_SOURCES ${RESOURCES})
    endif()
    if(DEFINED _arg_APPDATA)
        list(APPEND _arg_SOURCES ${_arg_APPDATA})
    endif()
    if(DEFINED _arg_DESKTOP)
        list(APPEND _arg_SOURCES ${_arg_DESKTOP})
    endif()
    extend_target("${name}"
        SOURCES ${_arg_SOURCES}
        INCLUDE_DIRECTORIES
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${CMAKE_CURRENT_BINARY_DIR}"
            ${_arg_INCLUDE_DIRECTORIES}
        DEFINES ${_arg_DEFINES}
        LIBRARIES ${_arg_LIBRARIES}
        DBUS_ADAPTOR_SOURCES ${_arg_DBUS_ADAPTOR_SOURCES}
        DBUS_ADAPTOR_FLAGS ${_arg_DBUS_ADAPTOR_FLAGS}
        DBUS_INTERFACE_SOURCES ${_arg_DBUS_INTERFACE_SOURCES}
        DBUS_INTERFACE_FLAGS ${_arg_DBUS_INTERFACE_FLAGS}
    )
    set_target_properties("${name}" PROPERTIES
        OUTPUT_NAME "${_arg_OUTPUT_NAME}"
        WIN32_EXECUTABLE "${_arg_GUI}"
        MACOSX_BUNDLE "${_arg_GUI}"
    )

    # Install executable
    if(NOT "${_arg_NO_TARGET_INSTALLATION}")
        if(DEFINED _arg_INSTALL_DIRECTORY)
            install(TARGETS "${name}" DESTINATION "${_arg_INSTALL_DIRECTORY}")
        else()
            install(TARGETS "${name}" DESTINATION ${INSTALL_TARGETS_DEFAULT_ARGS})
        endif()
    endif()

    # Install AppStream metadata
    if(DEFINED _arg_APPDATA)
        if((LINUX OR DARWIN OR FREEBSD) AND NOT APPLE)
            install(FILES ${_arg_APPDATA}
                    DESTINATION "${INSTALL_METAINFODIR}")
        endif()
    endif()

    # Install desktop entry
    if(DEFINED _arg_DESKTOP)
        if((LINUX OR DARWIN OR FREEBSD) AND NOT APPLE)
            if(DEFINED _arg_DESKTOP_INSTALL_DIRECTORY)
                install(FILES ${_arg_DESKTOP}
                        DESTINATION "${_arg_DESKTOP_INSTALL_DIRECTORY}")
            else()
                install(FILES ${_arg_DESKTOP}
                        DESTINATION "${INSTALL_APPLICATIONSDIR}")
            endif()
        endif()
    endif()
endfunction()


function(liri_add_test name)
    # Find packages we need
    find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS Core Test)

    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_add_test"
        "RUN_SERIAL"
        ""
        "${__default_private_args}"
        ${ARGN}
    )

    # Target
    liri_add_executable("${name}"
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
    add_test(
        NAME "${name}"
        COMMAND "${name}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    )
    set_tests_properties("${name}" PROPERTIES RUN_SERIAL ${_arg_RUN_SERIAL})
    set_property(TEST "${name}" APPEND PROPERTY ENVIRONMENT "PATH=${CMAKE_INSTALL_PREFIX}/${INSTALL_BINDIR}${LIRI_PATH_SEPARATOR}$ENV{PATH}")
    set_property(TEST "${name}" APPEND PROPERTY ENVIRONMENT "QT_PLUGIN_PATH=${CMAKE_INSTALL_PREFIX}/${INSTALL_PLUGINSDIR}${LIRI_PATH_SEPARATOR}$ENV{QT_PLUGIN_PATH}")
    set_property(TEST "${name}" APPEND PROPERTY ENVIRONMENT "QML2_IMPORT_PATH=${CMAKE_INSTALL_PREFIX}/${INSTALL_QMLDIR}${LIRI_PATH_SEPARATOR}$ENV{QML2_IMPORT_PATH}")
endfunction()


function(liri_add_plugin name)
    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_add_plugin"
        ""
        "TYPE"
        "${__default_private_args};${__default_public_args}"
        ${ARGN}
    )

    set(target "${name}")
    string(TOUPPER "${name}" name_upper)
    string(REGEX REPLACE "-" "_" name_upper "${name_upper}")

    # Target
    add_library("${target}" SHARED)
    if(DEFINED _arg_RESOURCES)
        qt5_add_resources(RESOURCES ${_arg_RESOURCES})
        list(APPEND _arg_SOURCES ${RESOURCES})
    endif()
    set_target_properties("${target}" PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${INSTALL_PLUGINSDIR}/${_arg_TYPE}"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${INSTALL_BINDIR}"
    )
    extend_target("${target}"
        SOURCES ${_arg_SOURCES}
        PUBLIC_INCLUDE_DIRECTORIES
            ${_arg_PUBLIC_INCLUDE_DIRECTORIES}
        INCLUDE_DIRECTORIES
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${CMAKE_CURRENT_BINARY_DIR}"
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

    # Install
    install(TARGETS "${target}"
        LIBRARY DESTINATION "${INSTALL_PLUGINSDIR}/${_arg_TYPE}"
        ARCHIVE DESTINATION "${INSTALL_LIBDIR}/${_arg_TYPE}"
    )
endfunction()


function(liri_add_qml_plugin name)
    # Find packages we need
    find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS Qml Quick)

    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_add_qml_plugin"
        ""
        "MODULE_PATH"
        "${__default_private_args};${__default_public_args};QML_FILES"
        ${ARGN}
    )

    if(NOT DEFINED _arg_MODULE_PATH)
        message(FATAL_ERROR "Missing argument MODULE_PATH.")
    endif()

    set(target "${name}plugin")
    string(TOUPPER "${name}" name_upper)
    string(REGEX REPLACE "-" "_" name_upper "${name_upper}")

    # Target
    add_library("${target}" SHARED)
    if(DEFINED _arg_RESOURCES)
        qt5_add_resources(RESOURCES ${_arg_RESOURCES})
        list(APPEND _arg_SOURCES ${RESOURCES})
    endif()
    extend_target("${target}"
        SOURCES
            ${_arg_SOURCES}
            ${_arg_QML_FILES}
        INCLUDE_DIRECTORIES
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${CMAKE_CURRENT_BINARY_DIR}"
            ${_arg_INCLUDE_DIRECTORIES}
        PUBLIC_INCLUDE_DIRECTORIES ${_arg_PUBLIC_INCLUDE_DIRECTORIES}
        LIBRARIES "Qt5::Qml;Qt5::Quick;${_arg_LIBRARIES}"
        PUBLIC_LIBRARIES ${_arg_PUBLIC_LIBRARIES}
        PUBLIC_DEFINES
            ${_arg_PUBLIC_DEFINES}
            LIRI_${name_upper}_LIB
        DEFINES
            ${_arg_DEFINES}
            QT_NO_CAST_TO_ASCII QT_ASCII_CAST_WARNINGS
            QT_USE_QSTRINGBUILDER
            QT_DEPRECATED_WARNINGS
        EXPORT_IMPORT_CONDITION
            LIRI_BUILD_${name_upper}_LIB
        DBUS_ADAPTOR_SOURCES ${_arg_DBUS_ADAPTOR_SOURCES}
        DBUS_ADAPTOR_FLAGS ${_arg_DBUS_ADAPTOR_FLAGS}
        DBUS_INTERFACE_SOURCES ${_arg_DBUS_INTERFACE_SOURCES}
        DBUS_INTERFACE_FLAGS ${_arg_DBUS_INTERFACE_FLAGS}
    )

    # Install
    install(FILES ${_arg_QML_FILES}
            DESTINATION "${INSTALL_QMLDIR}/${_arg_MODULE_PATH}")
    install(TARGETS "${target}" DESTINATION "${INSTALL_QMLDIR}/${_arg_MODULE_PATH}")
endfunction()


function(liri_add_qml_module name)
    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_add_qml_module"
        ""
        "MODULE_PATH"
        "QML_FILES"
        ${ARGN}
    )

    # Target
    set(target "${name}plugin")
    add_custom_target("${target}" SOURCES ${_arg_QML_FILES})

    # Install
    install(FILES ${_arg_QML_FILES}
            DESTINATION "${INSTALL_QMLDIR}/${_arg_MODULE_PATH}")
endfunction()


function(liri_add_indicator name)
    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_add_indicator"
        ""
        "METADATA;TRANSLATIONS_PATH"
        "QML_FILES"
        ${ARGN}
        )

    # Find packages we need
    find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS Core LinguistTools)

    string(TOLOWER "${name}" name_lower)

    # Assume a default value if metadata is not specified
    if(NOT _arg_METADATA)
        set(_arg_METADATA "${CMAKE_CURRENT_SOURCE_DIR}/metadata.desktop.in")
    endif()

    # Translation directory
    if(DEFINED _arg_TRANSLATIONS_PATH)
        set(_translations_path "translations")
    else()
        set(_translations_path "${_arg_TRANSLATIONS_PATH}")
    endif()
    get_filename_component(_translations_path "${_translations_path}" ABSOLUTE)

    # Translate desktop file
    liri_translate_desktop(_desktop_files
        SOURCES "${_arg_METADATA}"
        TRANSLATIONS_PATH "${_translations_path}"
    )

    # Sources
    set(_sources ${_arg_QML_FILES} ${_desktop_files})

    # Translations
    file(GLOB _translations "${_translations_path}/*.ts")
    qt5_add_translation(_qm_FILES ${_translations})

    # Target
    set(target "${name}Indicator")
    add_custom_target("${target}" ALL SOURCES ${_sources})

    # Install
    install(
        FILES ${_desktop_files}
        DESTINATION "${INSTALL_DATADIR}/liri-shell/indicators/${name_lower}"
    )
    install(
        FILES ${_arg_QML_FILES}
        DESTINATION "${INSTALL_DATADIR}/liri-shell/indicators/${name_lower}/contents"
    )
    install(
        FILES ${_qm_FILES}
        DESTINATION "${INSTALL_DATADIR}/liri-shell/indicators/${name_lower}/translations"
    )
endfunction()


function(liri_add_settings_module name)
    # Parse arguments
    _liri_parse_all_arguments(
        _arg "liri_add_settings_module"
        ""
        "METADATA;TRANSLATIONS_PATH"
        "CONTENTS"
        ${ARGN}
        )

    # Find packages we need
    find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS Core LinguistTools)

    string(TOLOWER "${name}" name_lower)

    # Assume a default value if metadata is not specified
    if(NOT _arg_METADATA)
        set(_arg_METADATA "${CMAKE_CURRENT_SOURCE_DIR}/metadata.desktop.in")
    endif()

    # Translation directory
    if(DEFINED _arg_TRANSLATIONS_PATH)
        set(_translations_path "${_arg_TRANSLATIONS_PATH}")
    else()
        set(_translations_path "${CMAKE_CURRENT_SOURCE_DIR}/translations")
    endif()
    get_filename_component(_translations_path "${_translations_path}" ABSOLUTE)

    # Translate desktop file
    liri_translate_desktop(_desktop_files
        SOURCES "${_arg_METADATA}"
        TRANSLATIONS_PATH "${_translations_path}"
    )

    # Translations
    file(GLOB _translations "${_translations_path}/*.ts")
    qt5_add_translation(_qm_FILES ${_translations})

    # Sources
    set(_sources ${_arg_CONTENTS} ${_desktop_files} ${_qm_FILES})

    # Target
    set(target "${name}Settings")
    add_custom_target("${target}" ALL SOURCES ${_sources})

    # Install
    install(
        FILES ${_desktop_files}
        DESTINATION "${INSTALL_DATADIR}/liri-settings/modules/${name_lower}"
    )
    install(
        FILES ${_arg_CONTENTS}
        DESTINATION "${INSTALL_DATADIR}/liri-settings/modules/${name_lower}/contents"
    )
    install(
        FILES ${_qm_FILES}
        DESTINATION "${INSTALL_DATADIR}/liri-settings/translations/modules"
    )
endfunction()
