if(LIRI_LOCAL_ECM)
    ## Add some paths to check for CMake modules:
    list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../3rdparty/extra-cmake-modules/modules")
    list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../3rdparty/extra-cmake-modules/find-modules")

    set(ECM_MODULE_DIR "${CMAKE_CURRENT_LIST_DIR}/../3rdparty/extra-cmake-modules/modules/")
    set(ECM_FIND_MODULE_DIR "${CMAKE_CURRENT_LIST_DIR}/../3rdparty/extra-cmake-modules/find-modules/")
else()
    ## Find ECM:
    find_package(ECM "5.48.0" REQUIRED NO_MODULE)

    ## Add some paths to check for CMake modules:
    list(APPEND CMAKE_MODULE_PATH "${ECM_MODULE_PATH};${ECM_KDE_MODULE_DIR}")
endif()

## Force C++ standard, do not fall back, use compiler extensions:
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)

## Position independent code:
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Do not relink dependent libraries when no header has changed:
set(CMAKE_LINK_DEPENDS_NO_SHARED ON)

# Default to hidden visibility for symbols:
set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN 1)

## Define some constants to check for certain platforms, etc:
include(LiriPlatformSupport)

## Enable feature summary at the end of the configure run:
include(FeatureSummary)

## Enable uninstall target:
include(ECMUninstallTarget)

## Enable support for sanitizers:
include(ECMEnableSanitizers)

## Always include srcdir and builddir in include path:
set(CMAKE_INCLUDE_CURRENT_DIR ON)

## Instruct CMake to run moc automatically when needed:
set(CMAKE_AUTOMOC ON)

## Create code from a list of Qt designer ui files:
set(CMAKE_AUTOUIC ON)

## Enable Clazy warnings:
if(CLANG)
    option(LIRI_ENABLE_CLAZY "Enable Clazy warnings" OFF)
    add_feature_info("Clazy" LIRI_ENABLE_CLAZY "Clazy warnings")

    if(LIRI_ENABLE_CLAZY)
        set(CMAKE_CXX_COMPILE_OBJECT "${CMAKE_CXX_COMPILE_OBJECT} -Xclang -load -Xclang ClazyPlugin${CMAKE_SHARED_LIBRARY_SUFFIX} -Xclang -add-plugin -Xclang clazy")
    endif()
endif()

## Enable coverage:
include(LiriCoverage)

## Add Liri functions:
include(LiriBuild)

## Enable testing:
include(CTest)
if(BUILD_TESTING)
    enable_testing()
endif()

## Print a feature summary:
feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
