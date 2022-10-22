# SPDX-FileCopyrightText: 2021 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
#
# SPDX-License-Identifier: BSD-3-Clause

define_property(TARGET
    PROPERTY
        LIRI_TARGET_TYPE
    BRIEF_DOCS
        "Specifies the target type."
    FULL_DOCS
        "This is a property on special Liri targets.
         Possible values: module, executable, plugin, qmlmodule, qmlplugin, settings, statusarea."
)

define_property(TARGET
    PROPERTY
        LIRI_PRIVATE_HEADER
    BRIEF_DOCS
        "This flag indicates that the source file is a private header."
    FULL_DOCS
        "This property is set on generated private headers."
)

define_property(TARGET
    PROPERTY
        LIRI_MODULE_NAME
    BRIEF_DOCS
        "Specifies the name of a Liri module."
    FULL_DOCS
        "This is a property on modules."
)

define_property(TARGET
    PROPERTY
        LIRI_MODULE_VERSIONED_NAME
    BRIEF_DOCS
        "Specifies the name with version of a Liri module."
    FULL_DOCS
        "This is a property on modules."
)

define_property(TARGET
    PROPERTY
        LIRI_MODULE_DESCRIPTION
    BRIEF_DOCS
        "Specifies the description of a Liri module."
    FULL_DOCS
        "This is a property on modules."
)

define_property(TARGET
    PROPERTY
        LIRI_MODULE_GLOBAL_HEADER_CONTENT
    BRIEF_DOCS
        "Specifies additional content for the global header of a Liri module."
    FULL_DOCS
        "This is a property on modules."
)

define_property(TARGET
    PROPERTY
        LIRI_MODULE_HAS_CMAKE
    BRIEF_DOCS
        "Specifies whether CMake files will be generated for the Liri module."
    FULL_DOCS
        "When this option is set, CMake files will be generated for the Liri module."
)

define_property(TARGET
    PROPERTY
        LIRI_MODULE_HAS_PKGCONFIG
    BRIEF_DOCS
        "Specifies whether a pkg-config file will be generated for the Liri module."
    FULL_DOCS
        "When this option is set, a pkg-config file will be generated for the Liri module."
)

define_property(TARGET
    PROPERTY
        LIRI_MODULE_PRIVATE_HEADERS
    BRIEF_DOCS
        "List of private headers of the Liri module."
    FULL_DOCS
        "This is a property on modules."
)

define_property(TARGET
    PROPERTY
        LIRI_MODULE_CLASS_HEADERS
    BRIEF_DOCS
        "List of association between a header and one or more class name headers of the Liri module."
    FULL_DOCS
        "This is a property on modules."
)

define_property(TARGET
    PROPERTY
        LIRI_MODULE_INSTALL_HEADERS
    BRIEF_DOCS
        "List of additional headers to install with the Liri module."
    FULL_DOCS
        "This is a property on modules."
)

define_property(TARGET
    PROPERTY
        LIRI_MODULE_PARENT_INCLUDE_DIR
    BRIEF_DOCS
        "Path to the directory that contains the include directory of the Liri module."
    FULL_DOCS
        "This is a property on modules."
)

define_property(TARGET
    PROPERTY
        LIRI_MODULE_INCLUDE_DIR
    BRIEF_DOCS
        "Path to the include directory of the Liri module."
    FULL_DOCS
        "This is a property on modules."
)

define_property(TARGET
    PROPERTY
        LIRI_MODULE_PRIVATE_INCLUDE_DIR
    BRIEF_DOCS
        "Path to the include directory of the Liri module with private headers."
    FULL_DOCS
        "This is a property on modules."
)

define_property(TARGET
    PROPERTY
        LIRI_RESOURCES
    BRIEF_DOCS
        "Specifies the Qt resource files to use."
    FULL_DOCS
        "The target will be built using these resources."
)

define_property(TARGET
    PROPERTY
        LIRI_ENABLE_QTQUICK_COMPILER
    BRIEF_DOCS
        "Enable QtQuick compiler for the target."
    FULL_DOCS
        "The target will be built using QtQuick compiler."
)

define_property(TARGET
    PROPERTY
        LIRI_DBUS_ADAPTOR_SOURCES
    BRIEF_DOCS
        "List of source files for a D-Bus adaptor."
    FULL_DOCS
        "This is a property for D-Bus adaptors."
)

define_property(TARGET
    PROPERTY
        LIRI_DBUS_ADAPTOR_FLAGS
    BRIEF_DOCS
        "Flags to pass to qdbusxml2cpp for a D-Bus adaptor."
    FULL_DOCS
        "This is a property for D-Bus adaptors."
)

define_property(TARGET
    PROPERTY
        LIRI_DBUS_INTERFACE_SOURCES
    BRIEF_DOCS
        "List of source files for a D-Bus interface."
    FULL_DOCS
        "This is a property for D-Bus interfaces."
)

define_property(TARGET
    PROPERTY
        LIRI_DBUS_INTERFACE_FLAGS
    BRIEF_DOCS
        "Flags to pass to qdbusxml2cpp for a D-Bus interface."
    FULL_DOCS
        "This is a property for D-Bus interfacess."
)
