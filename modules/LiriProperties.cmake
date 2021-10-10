#
# Copyright (C) 2021 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
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
