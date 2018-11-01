CMake Shared
============

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![GitHub release](https://img.shields.io/github/release/lirios/cmake-shared.svg)](https://github.com/lirios/cmake-shared)
[![Build Status](https://travis-ci.org/lirios/cmake-shared.svg?branch=develop)](https://travis-ci.org/lirios/cmake-shared)
[![GitHub issues](https://img.shields.io/github/issues/lirios/cmake-shared.svg)](https://github.com/lirios/cmake-shared/issues)
[![Maintained](https://img.shields.io/maintenance/yes/2018.svg)](https://github.com/lirios/cmake-shared/commits/develop)

Shared functions and macros for projects using the CMake build system.

## Dependencies

You need [cmake](https://cmake.org/) >= 3.10.0 to build this project.

## Installation

From the root of the repository, run:

```sh
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/path/to/prefix ..
make
make install # prepend sudo if you need it
```

Replace `/path/to/prefix` to the installation prefix (default: `/usr/local`).

## Licensing

Licensed under the terms of the BSD 3 Clause license.
