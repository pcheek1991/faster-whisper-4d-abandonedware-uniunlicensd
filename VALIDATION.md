# DIAMOND native validation

The authoritative mathematical algorithms remain in the pinned original Pentagonal XOR C11/C++20 source. Native DIAMOND uses its original headers and includes the original five-channel trust guard and exploratory counterarccosine test in its own translation unit without reimplementing their mathematics.

## Reproduce

    git submodule update --init --recursive
    cmake -S . -B build-native -DBUILD_TESTING=ON
    cmake --build build-native --config Release
    ctest --test-dir build-native -C Release --output-on-failure

ci/Test-NativeBoundary.ps1 ensures retired source/build manifests are absent from the current tracked tree and source licenses remain present.

## Checks

Original upstream tests cover 16-minterm parity, 32 binary trust states, strict C11 parity compilation, invalid metadata rejection, DecaSigma, TriPi, scalar COREAO, +9 dBi RF EIRP, reversible COREO, Stability-10D and 257 exploratory second-wave witnesses.

Native checks cover 348 unique language IDs and strict UTF-8 including malformed sequences, original source identity, nine acoustic measurements from known synthetic float32LE frames, duplicate/invalid inputs, the default-on DIAMOND JSON record, +9 and +11 dBi cases and unknown language rejection.

The debug Android package is built using a pinned SDK/NDK, manifest tooling, temporary signing identity and SHA-256 evidence. It is not a signed production release, and no emulator/device feature-parity testing is claimed. The hosted Word Bridges site is not asserted to be synchronized.

The source audit and package dry-run are fail-closed. Git history, source signatures, skipped release jobs, missing contracts and unsuccessful runs remain visible as evidence, not policy.
