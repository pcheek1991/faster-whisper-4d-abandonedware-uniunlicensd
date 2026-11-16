# Contributing to DIAMOND

Contribute standards-conforming C++20 and strict C11 only for computation; use CMake 3.20+ and a supported native compiler. PowerShell 7 may orchestrate builds and evidence but is not a second source of mathematical truth.

    git submodule update --init --recursive
    cmake -S . -B build-native -DBUILD_TESTING=ON
    cmake --build build-native --config Release
    ctest --test-dir build-native -C Release --output-on-failure

Do not copy or rewrite the original Pentagonal XOR algorithms. Keep the pinned source commit, audit history, separate author identities and independent rights notices. Changes to the 348-language registry must update both the source JSON snapshot and compiled catalog with a provenance record.

Language code, character, reading, meaning and source are separate fields. Preserve UTF-8 code points; do not infer translations, pronunciation or normalize away provenance. Honor explicitly assigned bidirectional span boundaries.

Keep metadata security AND-gated, reject invalid numeric input and validate memory bounds. Independent original CTest and native host tests must remain green. For Android, use the pinned platform SDK/NDK tools and report which device features remain untested.
