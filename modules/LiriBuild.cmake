# Save the location of some templates while CMAKE_CURRENT_LIST_DIR has the value we want:
set(_LIRI_VERSION_HEADER_TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/LiriModuleVersion.h.in")
set(_LIRI_MODULE_CONFIG_TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/LiriModuleConfig.cmake.in")

include(CMakeParseArguments)
include(GNUInstallDirs)

# Install locations:
set(INSTALL_BINDIR "${CMAKE_INSTALL_BINDIR}" CACHE PATH "Executables [PREFIX/bin]")
set(INSTALL_INCLUDEDIR "${CMAKE_INSTALL_INCLUDEDIR}" CACHE PATH "Header files [PREFIX/include]")
set(INSTALL_LIBDIR "${CMAKE_INSTALL_LIBDIR}" CACHE PATH "Libraries [PREFIX/lib]")
set(INSTALL_PLUGINSDIR "${INSTALL_LIBDIR}/plugins" CACHE PATH
    "Plugins [LIBDIR/plugins]")
set(INSTALL_LIBEXECDIR "${CMAKE_INSTALL_LIBEXECDIR}" CACHE PATH "Helper programs [PREFIX/libexec]")
set(INSTALL_QMLDIR "${INSTALL_LIBDIR}/qml" CACHE PATH "QML2 imports [LIBDIR/qml]")
set(INSTALL_DATADIR "${CMAKE_INSTALL_DATADIR}" CACHE PATH  "Arch-independent data [PREFIX/share]")
set(INSTALL_APPLICATIONSDIR "${INSTALL_DATADIR}/applications" CACHE PATH
    "Desktop entries [PREFIX/share/applications]")
set(INSTALL_METAINFODIR "${INSTALL_DATADIR}/metainfo" CACHE PATH
    "AppStream metadata [PREFIX/share/metainfo]")
set(INSTALL_DOCDIR "${INSTALL_DATADIR}/doc" CACHE PATH "Documentation [DATADIR/doc]")
set(INSTALL_SYSCONFDIR "${CMAKE_INSTALL_SYSCONFDIR}" CACHE PATH "Settings used by Liri programs [PREFIX/etc]")

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


function(_qdbusxml2cpp_command target infile)
    cmake_parse_arguments(
        _arg
        "ADAPTOR;INTERFACE"
        ""
        "FLAGS"
        ${ARGN}
    )
    if(DEFINED _arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments were passed to _qdbusxml2cpp_command (${_arg_UNPARSED_ARGUMENTS}).")
    endif()

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
        COMMAND echo "// clazy:skip" >> "${_header_filename}"
        DEPENDS "${infile}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        VERBATIM
    )

    qt5_wrap_cpp(_moc_sources TARGET "${target}" "${_header_filename}")
    set_source_files_properties("${_moc_sources}" PROPERTIES HEADER_FILE_ONLY OFF)
    target_sources("${target}" PRIVATE "${_header_filename}" "${_source_filename}" "${_moc_sources}")
endfunction()

function(_liri_internal_process_qdbusxml2cpp target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "Trying to extend non-existing target \"${target}\".")
    endif()

    cmake_parse_arguments(_arg "" "" "DBUS_ADAPTOR_FLAGS;DBUS_ADAPTOR_SOURCES;DBUS_INTERFACE_FLAGS;DBUS_INTERFACE_SOURCES" ${ARGN})
    if(DEFINED _arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments were passed to _liri_internal_process_qdbusxml2cpp (${_arg_UNPARSED_ARGUMENTS}).")
    endif()

   # Add D-Bus adaptor sources
   foreach(adaptor IN LISTS _arg_DBUS_ADAPTOR_SOURCES)
       _qdbusxml2cpp_command("${target}" "${adaptor}" ADAPTOR FLAGS "${_arg_DBUS_ADAPTOR_FLAGS}")
   endforeach()

   # Add D-Bus interface sources
   foreach(interface IN LISTS _arg_DBUS_INTERFACE_SOURCES)
       _qdbusxml2cpp_command("${target}" "${interface}" INTERFACE FLAGS "${_arg_DBUS_INTERFACE_FLAGS}")
   endforeach()

   # This implicitely requires Qt5::DBus
   list(FIND _libraries "Qt5::DBus" _qt5_dbus_index)
   if(${_qt5_dbus_index} EQUAL -1)
       find_package(Qt5 "5.0" CONFIG REQUIRED COMPONENTS DBus)
       message(STATUS "Adding Qt5::DBus target to ${target}")
       target_link_libraries("${target}" PRIVATE "Qt5::DBus")
   endif()
endfunction()


set(__default_private_args "SOURCES;LIBRARIES;INCLUDE_DIRECTORIES;DEFINES;RESOURCES;DBUS_ADAPTOR_FLAGS;DBUS_ADAPTOR_SOURCES;DBUS_INTERFACE_FLAGS;DBUS_INTERFACE_SOURCES")
set(__default_public_args "PUBLIC_LIBRARIES;PUBLIC_INCLUDE_DIRECTORIES;PUBLIC_DEFINES")
set(__default_module_args "PRIVATE_HEADERS;CLASS_HEADERS;INSTALL_HEADERS;PKGCONFIG_DEPENDENCIES")


# This function can be used to add sources/libraries/etc. to the specified CMake target
# if the provided CONDITION evaluates to true.
function(liri_extend_target target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "Trying to extend non-existing target \"${target}\".")
    endif()

    cmake_parse_arguments(
        _arg
        ""
        "EXPORT_IMPORT_CONDITION;GLOBAL_HEADER_CONTENT"
        "CONDITION;${__default_public_args};${__default_private_args};${__default_module_args};COMPILE_FLAGS;OUTPUT_NAME"
        ${ARGN}
    )
    if(DEFINED _arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown arguments were passed to liri_extend_target (${_arg_UNPARSED_ARGUMENTS}).")
    endif()

    # If CONDITION is not specified, we apply all properties requested by the user
    if(DEFINED _arg_CONDITION)
        if(_arg_CONDITION)
            set(_condition ON)
        else()
            set(_condition OFF)
        endif()
    else()
        set(_condition ON)
    endif()

    if(_condition)
        get_target_property(_target_type "${target}" LIRI_TARGET_TYPE)

        if(_arg_SOURCES)
            target_sources("${target}" PRIVATE ${_arg_SOURCES})
        endif()

        if(_arg_EXPORT_IMPORT_CONDITION)
            set_target_properties("${target}" PROPERTIES DEFINE_SYMBOL "${_arg_EXPORT_IMPORT_CONDITION}")
        endif()

        if(_arg_COMPILE_FLAGS)
            target_compile_options("${target}" PUBLIC "${_arg_COMPILE_FLAGS}")
        endif()

        if(_arg_OUTPUT_NAME)
            set_target_properties("${target}" PROPERTIES OUTPUT_NAME "${_arg_OUTPUT_NAME}")
        endif()

        if(_arg_PUBLIC_LIBRARIES)
            target_link_libraries("${target}" PUBLIC ${_arg_PUBLIC_LIBRARIES})
        endif()
        if(_arg_LIBRARIES)
            target_link_libraries("${target}" PRIVATE ${_arg_LIBRARIES})
        endif()

        if(_arg_PUBLIC_INCLUDE_DIRECTORIES)
            target_include_directories("${target}" PUBLIC ${_arg_PUBLIC_INCLUDE_DIRECTORIES})
        endif()
        if(_arg_INCLUDE_DIRECTORIES)
            target_include_directories("${target}" PRIVATE ${_arg_INCLUDE_DIRECTORIES})
        endif()

        if(_arg_PUBLIC_DEFINES)
            target_compile_definitions("${target}" PUBLIC ${_arg_PUBLIC_DEFINES})
        endif()
        if(_arg_DEFINES)
            target_compile_definitions("${target}" PRIVATE ${_arg_DEFINES})
        endif()

        # Custom properties for all kinds of targets
        set_property(TARGET "${target}" APPEND PROPERTY LIRI_DBUS_ADAPTOR_SOURCES "${_arg_DBUS_ADAPTOR_SOURCES}")
        set_property(TARGET "${target}" APPEND PROPERTY LIRI_DBUS_ADAPTOR_FLAGS "${_arg_DBUS_ADAPTOR_FLAGS}")
        set_property(TARGET "${target}" APPEND PROPERTY LIRI_DBUS_INTERFACE_SOURCES "${_arg_DBUS_INTERFACE_SOURCES}")
        set_property(TARGET "${target}" APPEND PROPERTY LIRI_DBUS_INTERFACE_FLAGS "${_arg_DBUS_INTERFACE_FLAGS}")
        set_property(TARGET "${target}" APPEND PROPERTY LIRI_RESOURCES "${_arg_RESOURCES}")

        # Custom properties only for Liri modules
        if(_target_type STREQUAL "module")
            set_property(TARGET "${target}" APPEND PROPERTY LIRI_MODULE_GLOBAL_HEADER_CONTENT "${_arg_GLOBAL_HEADER_CONTENT}")
            set_property(TARGET "${target}" APPEND PROPERTY LIRI_MODULE_PKGCONFIG_DEPENDENCIES "${_arg_PKGCONFIG_DEPENDENCIES}")
            set_property(TARGET "${target}" APPEND PROPERTY LIRI_MODULE_PRIVATE_HEADERS "${_arg_PRIVATE_HEADERS}")
            set_property(TARGET "${target}" APPEND PROPERTY LIRI_MODULE_CLASS_HEADERS "${_arg_CLASS_HEADERS}")
            set_property(TARGET "${target}" APPEND PROPERTY LIRI_MODULE_INSTALL_HEADERS "${_arg_INSTALL_HEADERS}")
        endif()
    endif()
endfunction()

# Perform common setup actions on targets.
function(liri_finalize_target target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "Trying to extend non-existing target \"${target}\".")
    endif()

    get_target_property(_dbus_adaptor_sources "${target}" LIRI_DBUS_ADAPTOR_SOURCES)
    if(_dbus_adaptor_sources MATCHES "NOTFOUND")
        set(_dbus_adaptor_sources "")
    endif()
    get_target_property(_dbus_interface_sources "${target}" LIRI_DBUS_INTERFACE_SOURCES)
    if(_dbus_interface_sources MATCHES "NOTFOUND")
        set(_dbus_interface_sources "")
    endif()
    get_target_property(_resource_files "${target}" LIRI_RESOURCES)
    if(_resource_files MATCHES "NOTFOUND")
        set(_resource_files "")
    endif()
    get_target_property(_qtquick_compiler "${target}" LIRI_ENABLE_QTQUICK_COMPILER)
    if(_qtquick_compiler MATCHES "NOTFOUND")
        set(_qtquick_compiler OFF)
    endif()

    # D-Bus sources
    if(_dbus_adaptor_sources OR _dbus_interface_sources)
        get_target_property(_dbus_adaptor_flags "${target}" LIRI_DBUS_ADAPTOR_FLAGS)
        if(_dbus_adaptor_flags MATCHES "NOTFOUND")
            set(_dbus_adaptor_flags "")
        endif()
        get_target_property(_dbus_interface_flags "${target}" LIRI_DBUS_INTERFACE_FLAGS)
        if(_dbus_interface_flags MATCHES "NOTFOUND")
            set(_dbus_interface_flags "")
        endif()

        _liri_internal_process_qdbusxml2cpp("${target}"
           DBUS_ADAPTOR_SOURCES "${_dbus_adaptor_sources}"
            DBUS_ADAPTOR_FLAGS "${_dbus_adaptor_flags}"
            DBUS_INTERFACE_SOURCES "${_dbus_interface_sources}"
            DBUS_INTERFACE_FLAGS "${_dbus_interface_flags}"
        )
    endif()

    # Resources
    if(_resource_files)
        if(_qtquick_compiler)
            find_package(Qt5QuickCompiler)
            if(Qt5QuickCompiler_FOUND)
                qtquick_compiler_add_resources(_resource_bins ${_resource_files})
                target_sources("${target}" PRIVATE ${_resource_files})
            else()
                message(WARNING "Qt5QuickCompiler not found, fall back to standard resources")
                qt5_add_resources(_resource_bins ${_resource_files})
            endif()
        else()
            qt5_add_resources(_resource_bins ${_resource_files})
        endif()
        target_sources("${target}" PRIVATE ${_resource_bins})
    endif()
endfunction()

# Include public functions
include(LiriFeatures)
include(LiriProperties)
include(LiriAddModule)
include(LiriAddExecutable)
include(LiriAddTest)
include(LiriAddPlugin)
include(LiriAddQmlPlugin)
include(LiriAddQmlModule)
include(LiriAddStatusAreaExtension)
include(LiriAddSettingsModule)
