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
        COMMAND echo "// clazy:skip" >> "${_header_filename}"
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
function(liri_extend_target target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "Trying to extend non-existing target \"${target}\".")
    endif()
    _liri_parse_all_arguments(
        _arg "liri_extend_target"
        ""
        "EXPORT_IMPORT_CONDITION"
	"CONDITION;${__default_public_args};${__default_private_args};COMPILE_FLAGS;OUTPUT_NAME"
        ${ARGN}
    )

    if("x${_arg_CONDITION}" STREQUAL "x")
        set(_arg_CONDITION ON)
    endif()

    if(${_arg_CONDITION})
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
        if(DEFINED _arg_EXPORT_IMPORT_CONDITION)
            set_target_properties("${target}" PROPERTIES DEFINE_SYMBOL "${_arg_EXPORT_IMPORT_CONDITION}")
        endif()
        target_include_directories("${target}" PUBLIC ${_arg_PUBLIC_INCLUDE_DIRECTORIES} PRIVATE ${_arg_INCLUDE_DIRECTORIES})
        target_compile_definitions("${target}" PUBLIC ${_arg_PUBLIC_DEFINES} PRIVATE ${_arg_DEFINES})
        if(DEFINED _arg_COMPILE_FLAGS)
            target_compile_options("${target}" PUBLIC "${_arg_COMPILE_FLAGS}")
        endif()
        target_link_libraries("${target}" PUBLIC ${_arg_PUBLIC_LIBRARIES} PRIVATE ${_arg_LIBRARIES})
    endif()
endfunction()

# Include public functions
include(LiriAddModule)
include(LiriAddExecutable)
include(LiriAddTest)
include(LiriAddPlugin)
include(LiriAddQmlPlugin)
include(LiriAddQmlModule)
include(LiriAddStatusAreaExtension)
include(LiriAddSettingsModule)
