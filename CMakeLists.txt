# SPDX-FileCopyrightText: 2022 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
#
# SPDX-License-Identifier: BSD-3-Clause

cmake_minimum_required(VERSION 3.17.0)

project("CMakeShared"
    VERSION "2.0.0"
    DESCRIPTION "Common CMake rules"
)

set(INSTALL_DATADIR "share" CACHE PATH  "Arch-independent data [PREFIX/share]")

## Package:

set(CMAKECONFIG_INSTALL_DIR "${INSTALL_DATADIR}/LiriCMakeShared/cmake/")
set(MODULES_INSTALL_DIR "${INSTALL_DATADIR}/LiriCMakeShared/modules/")

include(CMakePackageConfigHelpers)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/LiriCMakeSharedConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/LiriCMakeSharedConfig.cmake"
    INSTALL_DESTINATION
        "${CMAKECONFIG_INSTALL_DIR}"
    PATH_VARS
        MODULES_INSTALL_DIR
)

write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/LiriCMakeSharedConfigVersion.cmake"
    VERSION
        "${PROJECT_VERSION}"
    COMPATIBILITY
        AnyNewerVersion
)

install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/LiriCMakeSharedConfig.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/LiriCMakeSharedConfigVersion.cmake"
    DESTINATION
        "${CMAKECONFIG_INSTALL_DIR}"
)

## Install:

file(GLOB modules_FILES "${CMAKE_SOURCE_DIR}/modules/*[^~]")
install(FILES ${modules_FILES} DESTINATION "${MODULES_INSTALL_DIR}")
