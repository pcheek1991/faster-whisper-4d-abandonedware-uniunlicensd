cmake_minimum_required(VERSION 3.20)
project(FastestWhisper10DCanonicalPentagonalXOR LANGUAGES C CXX)
# The only implementation authority is the pinned, unmodified upstream gitlink.
include(CTest)
set(SWE_UPSTREAM_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/external/pentagonal-xor-cpp20")
if(NOT EXISTS "${SWE_UPSTREAM_ROOT}/shared/pentagonal_xor_std_free.h")
  message(FATAL_ERROR "Missing canonical upstream: git submodule update --init --recursive")
endif()
add_subdirectory("${SWE_UPSTREAM_ROOT}" "${CMAKE_CURRENT_BINARY_DIR}/canonical-pxor")
add_subdirectory("${SWE_UPSTREAM_ROOT}/shared" "${CMAKE_CURRENT_BINARY_DIR}/canonical-guard")
add_executable(fastest_whisper_pxor_adapter integration/pentagonal_xor_adapter.cpp)
target_compile_features(fastest_whisper_pxor_adapter PRIVATE cxx_std_20)
set_target_properties(fastest_whisper_pxor_adapter PROPERTIES CXX_STANDARD 20 CXX_STANDARD_REQUIRED YES CXX_EXTENSIONS NO)
target_include_directories(fastest_whisper_pxor_adapter PRIVATE "${SWE_UPSTREAM_ROOT}/shared")
if(MSVC)
  target_compile_options(fastest_whisper_pxor_adapter PRIVATE /W4 /permissive-)
else()
  target_compile_options(fastest_whisper_pxor_adapter PRIVATE -Wall -Wextra -Wpedantic)
endif()
if(BUILD_TESTING)
  add_test(NAME canonical_bridge_parity_zero COMMAND fastest_whisper_pxor_adapter parity 0 0 0 0 0)
  set_tests_properties(canonical_bridge_parity_zero PROPERTIES PASS_REGULAR_EXPRESSION "score")
  add_test(NAME canonical_bridge_parity_one COMMAND fastest_whisper_pxor_adapter parity 1 1 1 1 1)
  set_tests_properties(canonical_bridge_parity_one PROPERTIES PASS_REGULAR_EXPRESSION "score")
  add_test(NAME canonical_bridge_hexabyte_half COMMAND fastest_whisper_pxor_adapter ligands 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5)
  set_tests_properties(canonical_bridge_hexabyte_half PROPERTIES PASS_REGULAR_EXPRESSION "008000800080")
  add_test(NAME canonical_bridge_measurements COMMAND fastest_whisper_pxor_adapter measurements 1024 0 0 0.5 0.5 1 1 64 64)
  set_tests_properties(canonical_bridge_measurements PROPERTIES PASS_REGULAR_EXPRESSION "hexabyte")
  add_test(NAME canonical_bridge_invalid_nan COMMAND fastest_whisper_pxor_adapter parity nan 0 0 0 0)
  set_tests_properties(canonical_bridge_invalid_nan PROPERTIES WILL_FAIL TRUE)
  # Each bridge command calls the ORIGINAL pinned header; no local algorithm.
  add_test(NAME canonical_bridge_scores COMMAND fastest_whisper_pxor_adapter scores 1 1 1 0 0)
  set_tests_properties(canonical_bridge_scores PROPERTIES PASS_REGULAR_EXPRESSION "legacy_fifth_root")
  add_test(NAME canonical_bridge_fifth_root COMMAND fastest_whisper_pxor_adapter fifth-root -32)
  set_tests_properties(canonical_bridge_fifth_root PROPERTIES PASS_REGULAR_EXPRESSION "value")
  add_test(NAME canonical_bridge_deca_sigma COMMAND fastest_whisper_pxor_adapter deca-sigma 2)
  set_tests_properties(canonical_bridge_deca_sigma PROPERTIES PASS_REGULAR_EXPRESSION "returned")
  add_test(NAME canonical_bridge_tri_pi COMMAND fastest_whisper_pxor_adapter tri-pi 2)
  set_tests_properties(canonical_bridge_tri_pi PROPERTIES PASS_REGULAR_EXPRESSION "zfold")
  add_test(NAME canonical_bridge_coreao_scalar COMMAND fastest_whisper_pxor_adapter coreao 2)
  set_tests_properties(canonical_bridge_coreao_scalar PROPERTIES PASS_REGULAR_EXPRESSION "scalar")
  add_test(NAME canonical_bridge_coreao_gain9dbi COMMAND fastest_whisper_pxor_adapter gain9dbi 1)
  set_tests_properties(canonical_bridge_coreao_gain9dbi PROPERTIES PASS_REGULAR_EXPRESSION "output_eirp_watts")
  add_test(NAME canonical_bridge_coreao_gain9dbi_zero COMMAND fastest_whisper_pxor_adapter gain9dbi 0)
  set_tests_properties(canonical_bridge_coreao_gain9dbi_zero PROPERTIES PASS_REGULAR_EXPRESSION "gain_dbi")
  add_test(NAME canonical_bridge_coreao_gain9dbi_negative COMMAND fastest_whisper_pxor_adapter gain9dbi -1)
  set_tests_properties(canonical_bridge_coreao_gain9dbi_negative PROPERTIES WILL_FAIL TRUE)
  add_test(NAME canonical_bridge_coreao_gain9dbi_overflow COMMAND fastest_whisper_pxor_adapter gain9dbi 1e308)
  set_tests_properties(canonical_bridge_coreao_gain9dbi_overflow PROPERTIES WILL_FAIL TRUE)
  add_test(NAME canonical_bridge_coreo_stereo COMMAND fastest_whisper_pxor_adapter coreo-stereo 1 -2 3 -4)
  set_tests_properties(canonical_bridge_coreo_stereo PROPERTIES PASS_REGULAR_EXPRESSION "largest_disagreement")
  add_test(NAME canonical_gain_default9 COMMAND fastest_whisper_pxor_adapter gain 1)
  set_tests_properties(canonical_gain_default9 PROPERTIES PASS_REGULAR_EXPRESSION "original-fixed-9dbi")
  add_test(NAME canonical_gain_explicit11 COMMAND fastest_whisper_pxor_adapter gain 1 11)
  set_tests_properties(canonical_gain_explicit11 PROPERTIES PASS_REGULAR_EXPRESSION "downstream-rf-dbi-offset-v1")
  add_test(NAME canonical_gain_reject101 COMMAND fastest_whisper_pxor_adapter gain 1 101)
  set_tests_properties(canonical_gain_reject101 PROPERTIES WILL_FAIL TRUE)
  add_test(NAME canonical_gain_reject_nonfinite COMMAND fastest_whisper_pxor_adapter gain 1 nan)
  set_tests_properties(canonical_gain_reject_nonfinite PROPERTIES WILL_FAIL TRUE)
  add_test(NAME canonical_bridge_platform_macros COMMAND fastest_whisper_pxor_adapter platform)
  set_tests_properties(canonical_bridge_platform_macros PROPERTIES PASS_REGULAR_EXPRESSION "std_free_backend")
endif()
install(TARGETS fastest_whisper_pxor_adapter RUNTIME DESTINATION bin)
# Install the original metadata guard and a complete source snapshot.
# These files are unchanged upstream bytes, not generated algorithm clones.
install(TARGETS swe_guard RUNTIME DESTINATION bin)
install(DIRECTORY "${SWE_UPSTREAM_ROOT}/"
  DESTINATION share/source/pentagonal-xor-cpp20
  PATTERN ".git" EXCLUDE)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/docs/PENTAGONAL_XOR_PROVENANCE.md"
  DESTINATION share/doc/fastest-whisper-10d)

# The native diamond binary is the only installed default entry point.

# The second-wave white-paper operator is research-only in the pinned source.
# Ship and run its VERBATIM executable test, never a reimplementation.
if(BUILD_TESTING)
  install(TARGETS counterarccosine_secondwave_test RUNTIME DESTINATION bin)
endif()

# DIAMOND native C++20 using only the standard library and pinned 0BSD headers.
add_executable(diamond native/diamond.cpp native/acoustic.cpp)
target_compile_features(diamond PRIVATE cxx_std_20)
target_include_directories(diamond PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/native" "${SWE_UPSTREAM_ROOT}/shared")
set_target_properties(diamond PROPERTIES
  CXX_STANDARD 20 CXX_STANDARD_REQUIRED YES CXX_EXTENSIONS NO)
if(MSVC)
  target_compile_options(diamond PRIVATE /W4 /permissive- /utf-8)
else()
  target_compile_options(diamond PRIVATE -Wall -Wextra -Wpedantic)
endif()
install(TARGETS diamond RUNTIME DESTINATION bin)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/data/wikimedia-languages.json"
  "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE-ISC-WIKIPEDIA-DATA"
  DESTINATION share/data/diamond)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/docs/WORD_BRIDGES.md"
  DESTINATION share/doc/diamond)

if(BUILD_TESTING)
  add_executable(diamond_languages_test native/tests/word_bridges_test.cpp)
  target_include_directories(diamond_languages_test PRIVATE native)
  target_compile_features(diamond_languages_test PRIVATE cxx_std_20)
  if(MSVC)
    target_compile_options(diamond_languages_test PRIVATE /utf-8)
  endif()
  add_test(NAME diamond_348_languages_unicode COMMAND diamond_languages_test)

  add_executable(diamond_acoustic_test native/tests/acoustic_test.cpp native/acoustic.cpp)
  target_include_directories(diamond_acoustic_test PRIVATE native "${SWE_UPSTREAM_ROOT}/shared")
  target_compile_features(diamond_acoustic_test PRIVATE cxx_std_20)
  add_test(NAME diamond_stereo_acoustic_10d COMMAND diamond_acoustic_test)

  add_test(NAME diamond_allon_reference COMMAND diamond)
  set_tests_properties(diamond_allon_reference PROPERTIES PASS_REGULAR_EXPRESSION
    "SWE-DIAMOND-CXX20-v1")
  add_test(NAME diamond_rf_9dbi COMMAND diamond --watts 1)
  set_tests_properties(diamond_rf_9dbi PROPERTIES PASS_REGULAR_EXPRESSION
    "original-fixed-9dbi")
  add_test(NAME diamond_rf_11dbi COMMAND diamond --watts 1 --gain-dbi 11)
  set_tests_properties(diamond_rf_11dbi PROPERTIES PASS_REGULAR_EXPRESSION
    "separate-rf-offset-v1")
  add_test(NAME diamond_wordbridges_farsi_unicode COMMAND diamond --language fa
    --text "سلام" --reading "salâm" --meaning "hello" --source "caller")
  set_tests_properties(diamond_wordbridges_farsi_unicode PROPERTIES PASS_REGULAR_EXPRESSION
    "translation_generated")
  add_test(NAME diamond_invalid_unknown_language COMMAND diamond --language xx-not-real)
  set_tests_properties(diamond_invalid_unknown_language PROPERTIES WILL_FAIL TRUE)
  add_test(NAME diamond_invalid_domain COMMAND diamond --gain-dbi 101)
  set_tests_properties(diamond_invalid_domain PROPERTIES WILL_FAIL TRUE)
  add_test(NAME diamond_languages_dump COMMAND diamond --languages)
  set_tests_properties(diamond_languages_dump PROPERTIES PASS_REGULAR_EXPRESSION
    "Abkhazian")
endif()

# Android ABI uses the original headers and standard NDK entry point.
# SDK/NDK platform tools are unavoidable; no external application runtime.
if(ANDROID)
  add_library(diamond_android SHARED native/android_native_activity.cpp)
  target_include_directories(diamond_android PRIVATE "${SWE_UPSTREAM_ROOT}/shared")
  target_compile_features(diamond_android PRIVATE cxx_std_20)
  target_link_libraries(diamond_android PRIVATE android log)
endif()


# Experimental controller complements, but does not replace, the pinned
# upstream submodule or the default DIAMOND executable.
if(BUILD_TESTING)
  add_executable(pentagonal_gates_integration_test native/tests/pentagonal_gates_test.cpp)
  target_include_directories(pentagonal_gates_integration_test PRIVATE
    native external/pentagonal-xor-cpp20/shared)
  target_compile_features(pentagonal_gates_integration_test PRIVATE cxx_std_20)
  add_test(NAME diamond_pentagonal_gates_cor_vista_flop
           COMMAND pentagonal_gates_integration_test)
  add_executable(pentagonal_gates_integration_benchmark
                 native/tests/pentagonal_gates_benchmark.cpp)
  target_include_directories(pentagonal_gates_integration_benchmark PRIVATE
    native external/pentagonal-xor-cpp20/shared)
  target_compile_features(pentagonal_gates_integration_benchmark PRIVATE cxx_std_20)
endif()
install(FILES native/pentagonal_gates.hpp DESTINATION include/swe)
install(FILES docs/PENTAGONAL_GATE_CASCADE.md DESTINATION share/doc/diamond)


# Separate research CLI. Native DIAMOND default path is untouched.
add_executable(pentagonal_control native/pentagonal_control.cpp)
target_include_directories(pentagonal_control PRIVATE
  native external/pentagonal-xor-cpp20/shared)
target_compile_features(pentagonal_control PRIVATE cxx_std_20)
install(TARGETS pentagonal_control RUNTIME DESTINATION bin)
if(BUILD_TESTING)
  add_test(NAME diamond_pentagonal_control_json COMMAND pentagonal_control 0x3fffffff 0x3fffffff or)
  set_tests_properties(diamond_pentagonal_control_json PROPERTIES
    PASS_REGULAR_EXPRESSION "logical_evaluations")
  add_test(NAME diamond_depth_three_benchmark COMMAND pentagonal_gates_integration_benchmark)
  set_tests_properties(diamond_depth_three_benchmark PROPERTIES
    PASS_REGULAR_EXPRESSION "Interpretation")
endif()


# Supplier-side GAMP 4-style verification, preserving the pinned gitlink.
if(BUILD_TESTING)
  add_executable(pentagonal_gamp4_integration_test
                 native/tests/pentagonal_gamp4_validation_test.cpp)
  target_include_directories(pentagonal_gamp4_integration_test PRIVATE
    native external/pentagonal-xor-cpp20/shared)
  target_compile_features(pentagonal_gamp4_integration_test PRIVATE cxx_std_20)
  add_test(NAME diamond_gamp4_pentagonal_urs_11_to_22
           COMMAND pentagonal_gamp4_integration_test)
endif()
install(FILES docs/PENTAGONAL_GAMP4_VALIDATION.md
        DESTINATION share/doc/diamond)


# LIGAZE: real native C++20 executable distinct from the Java JAR.
add_executable(pentagonal_ligaze native/pentagonal_ligaze.cpp)
target_include_directories(pentagonal_ligaze PRIVATE
  native external/pentagonal-xor-cpp20/shared)
target_compile_features(pentagonal_ligaze PRIVATE cxx_std_20)
install(TARGETS pentagonal_ligaze RUNTIME DESTINATION bin)
install(FILES native/pentagonal_ligaze.hpp DESTINATION include/swe)
if(BUILD_TESTING)
  add_executable(pentagonal_ligaze_test native/tests/pentagonal_ligaze_test.cpp)
  target_include_directories(pentagonal_ligaze_test PRIVATE
    native external/pentagonal-xor-cpp20/shared)
  target_compile_features(pentagonal_ligaze_test PRIVATE cxx_std_20)
  add_test(NAME diamond_pentagonal_ligaze_exhaustive_cor_witness COMMAND pentagonal_ligaze_test)
  add_test(NAME diamond_pentagonal_ligaze_native_cli COMMAND pentagonal_ligaze 0x15 0x15 0x1f 0x1f)
  set_tests_properties(diamond_pentagonal_ligaze_native_cli PROPERTIES
    PASS_REGULAR_EXPRESSION "native-cxx20")
endif()
install(FILES docs/PENTAGONAL_LIGAZE_NATIVE.md DESTINATION share/doc/diamond)


# Platform-matrix LIGAZE COR workload: independent native C++20 benchmark.
add_executable(pentagonal_ligaze_benchmark native/benchmarks/pentagonal_ligaze_benchmark.cpp)
target_include_directories(pentagonal_ligaze_benchmark PRIVATE
  native external/pentagonal-xor-cpp20/shared)
target_compile_features(pentagonal_ligaze_benchmark PRIVATE cxx_std_20)
if(BUILD_TESTING)
  add_test(NAME diamond_pentagonal_ligaze_benchmark_smoke
    COMMAND pentagonal_ligaze_benchmark 1000 100 1)
  set_tests_properties(diamond_pentagonal_ligaze_benchmark_smoke PROPERTIES
    PASS_REGULAR_EXPRESSION "SWE-LIGAZE-BENCH-v1")
endif()


# Explicit, opt-in Windows LIGAZE benchmark AB variants.
# Isolated to benchmark target; no default shipping or Win32 API replacement.
set(SWE_LIGAZE_WINDOWS_AB_VARIANT "promoted" CACHE STRING
    "Windows LIGAZE benchmark experiment: promoted|baseline|safe_header|full_header|ltcg|safe_header_ltcg")
set_property(CACHE SWE_LIGAZE_WINDOWS_AB_VARIANT PROPERTY STRINGS
    promoted baseline safe_header full_header ltcg safe_header_ltcg)
if(MSVC)
  # Actual measured optimization: /GL + /LTCG, enabled in Release only.
  # The default benchmark is promoted; explicit baseline stays unoptimized
  # so later AB runs remain comparable against a real pre-promotion control.
  set_property(TARGET pentagonal_ligaze PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)
  if(SWE_LIGAZE_WINDOWS_AB_VARIANT STREQUAL "safe_header" OR
     SWE_LIGAZE_WINDOWS_AB_VARIANT STREQUAL "safe_header_ltcg")
    target_compile_definitions(pentagonal_ligaze_benchmark PRIVATE
      SWE_LIGAZE_WINDOWS_SAFE_HEADER_EXPERIMENT=1)
  elseif(SWE_LIGAZE_WINDOWS_AB_VARIANT STREQUAL "full_header")
    target_compile_definitions(pentagonal_ligaze_benchmark PRIVATE
      SWE_LIGAZE_WINDOWS_FULL_HEADER_EXPERIMENT=1)
  elseif(NOT SWE_LIGAZE_WINDOWS_AB_VARIANT STREQUAL "baseline" AND
         NOT SWE_LIGAZE_WINDOWS_AB_VARIANT STREQUAL "promoted" AND
         NOT SWE_LIGAZE_WINDOWS_AB_VARIANT STREQUAL "ltcg")
    message(FATAL_ERROR "Unknown Windows AB experiment variant: ${SWE_LIGAZE_WINDOWS_AB_VARIANT}")
  endif()
  if(SWE_LIGAZE_WINDOWS_AB_VARIANT STREQUAL "promoted" OR
     SWE_LIGAZE_WINDOWS_AB_VARIANT STREQUAL "ltcg" OR
     SWE_LIGAZE_WINDOWS_AB_VARIANT STREQUAL "safe_header_ltcg")
    # MSVC Release already enables /O2; test additional /GL and /LTCG.
    set_property(TARGET pentagonal_ligaze_benchmark PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
  endif()
else()
  if(NOT SWE_LIGAZE_WINDOWS_AB_VARIANT STREQUAL "baseline")
    message(FATAL_ERROR "Windows-specific AB variant selected on non-MSVC compiler")
  endif()
endif()
