option(LIRI_ENABLE_COVERAGE "Enable code coverage support (GCC or Clang only)" OFF)
add_feature_info("Coverage" LIRI_ENABLE_COVERAGE "Code coverage (GCC or Clang only)")
if(LIRI_ENABLE_COVERAGE)
    if(GCC OR CLANG)
        set(CMAKE_COVERAGE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/.ccov")
        if(NOT TARGET "ccov-preprocessing")
            add_custom_target(ccov-preprocessing
                              COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_COVERAGE_OUTPUT_DIRECTORY})
        endif()
    endif()

    if(GCC)
        message("Building with GCov")

        find_program(LCOV_PATH lcov)
        if(NOT LCOV_PATH)
          message(FATAL_ERROR "lcov not found! Aborting...")
        endif()

        find_program(GENHTML_PATH genhtml)
        if(NOT GENHTML_PATH)
          message(FATAL_ERROR "genhtml not found! Aborting...")
        endif()

        if(CMAKE_BUILD_TYPE MATCHES "[Rr]elease")
            message(WARNING "Code coverage results with a release build may be misleading")
        endif()

        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fprofile-arcs -ftest-coverage")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-arcs -ftest-coverage")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lgcov")

        add_custom_target("ccov-clean"
                          COMMAND ${LCOV_PATH} --directory ${CMAKE_BINARY_DIR} --zerocounters)
    elseif(CLANG)
        message("Building with llvm Code Coverage Tools")

        find_program(LLVM_COV_PATH llvm-cov)
        if(NOT LLVM_COV_PATH)
            message(FATAL_ERROR "llvm-cov not found! Aborting.")
        endif()

        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fprofile-instr-generate -fcoverage-mapping")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-instr-generate -fcoverage-mapping")

        if(NOT TARGET "ccov-clean")
            add_custom_target("ccov-clean"
                              COMMAND rm -f ${CMAKE_COVERAGE_OUTPUT_DIRECTORY}/binaries.list
                              COMMAND rm -f ${CMAKE_COVERAGE_OUTPUT_DIRECTORY}/profraw.list)
        endif()

        if(NOT TARGET "ccov-all-processing")
            add_custom_target(
                "ccov-all-processing"
                COMMAND llvm-profdata merge -o ${CMAKE_COVERAGE_OUTPUT_DIRECTORY}/all-merged.profdata -sparse `cat ${CMAKE_COVERAGE_OUTPUT_DIRECTORY}/profraw.list`)
        endif()

        if(NOT TARGET "ccov-all-report")
            add_custom_target(
                "ccov-all-report"
                COMMAND llvm-cov report `cat ${CMAKE_COVERAGE_OUTPUT_DIRECTORY}/binaries.list` -instr-profile=${CMAKE_COVERAGE_OUTPUT_DIRECTORY}/all-merged.profdata
                DEPENDS "ccov-all-processing")
        endif()

        if(NOT TARGET "ccov-all")
            add_custom_target(
                "ccov-all"
                COMMAND llvm-cov show `cat ${CMAKE_COVERAGE_OUTPUT_DIRECTORY}/binaries.list` -instr-profile=${CMAKE_COVERAGE_OUTPUT_DIRECTORY}/all-merged.profdata -show-line-counts-or-regions -output-dir=${CMAKE_COVERAGE_OUTPUT_DIRECTORY}/all-merged -format="html"
                DEPENDS "ccov-all-processing")
        endif()
    else()
        message(FATAL_ERROR "Code coverage requires GCC or Clang. Aborting.")
    endif()
endif()
