#!/bin/bash

set -e

source /usr/local/share/liri-travis/functions

# Configure
travis_start "configure"
msg "Setup CMake..."
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
travis_end "configure"

# Build
travis_start "build"
msg "Build..."
make -j $(nproc)
travis_end "build"

# Install
travis_start "install"
msg "Install..."
make install
travis_end "install"

# Package
travis_start "package"
msg "Package..."
mkdir -p artifacts
tar czf artifacts/cmakeshared-artifacts.tar.gz -T install_manifest.txt
travis_end "package"
