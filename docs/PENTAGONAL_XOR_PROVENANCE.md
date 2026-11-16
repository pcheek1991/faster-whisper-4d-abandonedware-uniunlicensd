# Pentagonal XOR canonical integration and custody

**Original repository**: https://github.com/Simply-Well-Executed/pentagonal-xor-cpp20

**Pinned immutable source commit**: `fb23b40480476c98e992762ace37761b6fd8ba0e`

**Carrier**: `external/pentagonal-xor-cpp20` is a Git submodule, not a rewrite or renamed fork. Run `git submodule update --init --recursive`.

**Target**: https://github.com/pcheek1991/faster-whisper-4d-abandonedware-uniunlicensd/pull/17

## Provenance and source-of-truth

The target's new root CMakeLists.txt builds the **verbatim upstream** C++20 project and the upstream strict-C11/shared metadata guard, including the upstream test suites. `integration/pentagonal_xor_adapter.cpp` is an I/O adapter. It delegates to the original exported `swe_pxor_xor_parity_arr`, `swe::stability10d::calculate`, and `swe::stability10d::from_measurements` functions. No duplicate algorithm is introduced in the adapter. Every submodule file comes from the exact source revision, and changing that revision requires review.

The full pinned source revision includes the original five-input XOR (16 parity minterms as reference), AND/OR/partial/fifth-root scoring, std-free C11 entry point and OS-target macros, DecaSigma, TriPi, scalar COREAO, idealized RF +9 dBi COREAO gain, counterarccosine second-wave tests, Stability-10D and its six-byte hex witness, reversible stereo COREO, metadata trust guard, CMake installation, offline Android source-study components, Docker definitions, PowerShell validation infrastructure and their documentation and tests. The CI tests the executable C++/C11 operator coverage and invokes existing target PowerShell synthetic contracts. Running the operator suite is not a claim of Android device execution or trained ASR.

**Bidirectional credit**: Upstream `docs/STABILITY10D.md` expressly credits this PR #17 as the source of its experimental Stability-10D and stereo COREO port. Reimporting those headers from upstream does **not** change the historical origin of the protocol. Earlier compatibility scripts in `ci/Stability.ps1` and Android Java remain separate preexisting language ports, not falsely represented as original upstream code. Canonical parity belongs to the pinned C/C++ header and source.

## Validation and rights boundary

Each Shared Guard run must check the Git gitlink and submodule checkout SHA match the pinned commit, then retain hashes, build logs and test results. The native matrix covers Windows, macOS and Linux; the Linux Docker lane may invoke the unchanged pinned upstream container guards. Existing Android SDK CI continues independently. The published SDK-free Docker image cannot be used for NDK cross-compilation merely by setting an environment variable.

Upstream project-owned source is 0BSD. The inherited faster-whisper repository also contains upstream MIT components; neither license overrides third-party Android SDK, OS, compiler, Docker layer or model licenses. Packaging must remain clearly labeled *weight-free numerical analysis and provenance tooling*, **not speech-to-text** or a signed production Android release. Docker Hub publication and external uploads are not authorized by Shared Guard validation alone. Deployment is tag-gated, checks code and tests again, and releases only the explicitly packaged numerical module.

No source history or evidence failure is deleted or reclassified as success.

The release package installs the original upstream executable, the original C11/C++20 headers, the original `swe_guard` binary, the thin adapter, original documentation, and a full version-pinned source snapshot (excluding Git administrative data). Upstream Android SDK, Docker image layers, and third-party binaries are never silently bundled under the project's 0BSD license.
