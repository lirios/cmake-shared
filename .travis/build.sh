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
make install
make package
travis_end "build"
