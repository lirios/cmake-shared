CMake Shared
============

[![License](https://img.shields.io/badge/license-GPLv3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
[![GitHub release](https://img.shields.io/github/release/lirios/cmake-shared.svg)](https://github.com/lirios/cmake-shared)
[![GitHub issues](https://img.shields.io/github/issues/lirios/cmake-shared.svg)](https://github.com/lirios/cmake-shared/issues)
[![CI](https://github.com/lirios/cmake-shared/workflows/CI/badge.svg?branch=develop)](https://github.com/lirios/cmake-shared/actions?query=workflow%3ACI)

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

Licensed under the terms of the GNU General Public License version 3.
