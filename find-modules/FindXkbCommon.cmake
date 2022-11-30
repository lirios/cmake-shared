# SPDX-FileCopyrightText: 2022 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
# SPDX-FileCopyrightText: 2014 Alex Merry <alex.merry@kde.org>
# SPDX-FileCopyrightText: 2014 Martin Gräßlin <mgraesslin@kde.org>
#
# SPDX-License-Identifier: BSD-3-Clause
#
# FindXkbCommon
# -------------
#
# Try to find xkbcommon on Unix system.
#
# ``XkbCommon_FOUND``
#     True if (the requested version of) xkbcommon is available
# ``XkbCommon_VERSION``
#     The version of xkbcommon
# ``Xkbcommon_LIBRARIES``
#     This can be passed to target_link_libraries() instead of the ``XkbCommon::XkbCommon``
#     target
# ``XkbCommon_INCLUDE_DIRS``
#     This should be passed to target_include_directories() if the target is not
#     used for linking
# ``XkbCommon_DEFINITIONS``
#     This should be passed to target_compile_options() if the target is not
#     used for linking
#
# If ``XkbCommon_FOUND`` is TRUE, it will also define the following imported target:
#
# ``XkbCommon::XkbCommon``
#     The xkbcommon library
#
# In general we recommend using the imported target, as it is easier to use.
# Bear in mind, however, that if the target is in the link interface of an
# exported library, it must be made available by the package config file.

if(CMAKE_VERSION VERSION_LESS 2.8.12)
    message(FATAL_ERROR "CMake 2.8.12 is required by FindXkbCommon.cmake")
endif()
if(CMAKE_MINIMUM_REQUIRED_VERSION VERSION_LESS 2.8.12)
    message(AUTHOR_WARNING "Your project should require at least CMake 2.8.12 to use FindXkbCommon.cmake")
endif()

if(NOT WIN32)
    # Use pkg-config to get the directories and then use these values
    # in the FIND_PATH() and FIND_LIBRARY() calls
    find_package(PkgConfig)
    pkg_check_modules(PKG_XkbCommon QUIET xkbcommon)

    set(XkbCommon_DEFINITIONS ${PKG_XkbCommon_CFLAGS_OTHER})
    set(XkbCommon_VERSION ${PKG_XkbCommon_VERSION})

    find_path(XkbCommon_INCLUDE_DIR
        NAMES
            xkbcommon/xkbcommon.h
        HINTS
            ${PKG_XkbCommon_INCLUDE_DIRS}
    )
    find_library(XkbCommon_LIBRARY
        NAMES
            xkbcommon
        HINTS
            ${PKG_XkbCommon_LIBRARY_DIRS}
    )

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(XkbCommon
        FOUND_VAR
            XkbCommon_FOUND
        REQUIRED_VARS
            XkbCommon_LIBRARY
            XkbCommon_INCLUDE_DIR
        VERSION_VAR
            XkbCommon_VERSION
    )

    if(XkbCommon_FOUND AND NOT TARGET XkbCommon::XkbCommon)
        add_library(XkbCommon::XkbCommon UNKNOWN IMPORTED)
        set_target_properties(XkbCommon::XkbCommon PROPERTIES
            IMPORTED_LOCATION "${XkbCommon_LIBRARY}"
            INTERFACE_COMPILE_OPTIONS "${XkbCommon_DEFINITIONS}"
            INTERFACE_INCLUDE_DIRECTORIES "${XkbCommon_INCLUDE_DIR}"
            INTERFACE_INCLUDE_DIRECTORIES "${XkbCommon_INCLUDE_DIR}/xkbcommon"
        )
    endif()

    mark_as_advanced(XkbCommon_LIBRARY XkbCommon_INCLUDE_DIR)

    # compatibility variables
    set(XkbCommon_LIBRARIES ${XkbCommon_LIBRARY})
    set(XkbCommon_INCLUDE_DIRS ${XkbCommon_INCLUDE_DIR} "${XkbCommon_INCLUDE_DIR}/xkbcommon")
    set(XkbCommon_VERSION_STRING ${XkbCommon_VERSION})

else()
    message(STATUS "FindXkbCommon.cmake cannot find xkbcommon on Windows systems.")
    set(XkbCommon_FOUND FALSE)
endif()

include(FeatureSummary)
set_package_properties(XkbCommon PROPERTIES
    URL "https://xkbcommon.org/"
    DESCRIPTION "Library for handling of keyboard descriptions"
)
