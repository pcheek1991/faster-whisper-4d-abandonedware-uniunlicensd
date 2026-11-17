# DIAMOND: native C++20 acoustic, parity and language laboratory

DIAMOND is an offline, weight-free numerical laboratory. It does **not** contain a trained speech model, generate transcripts, translate languages or measure actual antenna radiation. The default execution path is a compiled C++20 binary invoking the unchanged original Pentagonal XOR mathematical source.

## Build and test

    git submodule update --init --recursive
    cmake -S . -B build-native -DBUILD_TESTING=ON
    cmake --build build-native --config Release
    ctest --test-dir build-native -C Release --output-on-failure

Executable: build-native/diamond on Unix-like hosts, or build-native/Release/diamond.exe on a multi-configuration Windows build.

## Every applicable facet is enabled

    ./build-native/diamond
    ./build-native/diamond --watts 1 --gain-dbi 11
    '11' | ./build-native/diamond --watts 1
    ./build-native/diamond --language fa --text 'سلام' --reading 'salâm' --meaning 'hello' --source 'caller'
    ./build-native/diamond --raw-stereo ./stereo-float32le.raw
    ./build-native/diamond --languages

The native executable runs five principal facets: (1) original parity, AND, OR, partial and fifth-root scoring; (2) native acoustic measurements and original Stability-10D nine-ligand/hexabyte calculations; (3) original DecaSigma, TriPi, COREAO and reversible stereo COREO; (4) canonical +9 dBi RF/EIRP gain plus separately labeled alternative-gain offsets; (5) Word Bridges Unicode language metadata, the original five-channel trust guard and research second-wave test.

**Default numerical values are explicitly synthetic references, not inferred measurements.** No mode switches are necessary. Invalid input or failed metadata checks returns a nonzero process exit, not success-shaped JSON. A piped scalar overrides the dBi gain. A piped record of semicolon-separated key=value fields can override additional inputs.

For 1 W of specified conducted RF power the original +9 dBi model produces approximately 7.943282 W *idealized directional EIRP*; a requested +11 dBi offset produces about 12.589254 W. Neither value is audio volume gain, physical total radiated wattage or a measurement.

## Word Bridges

The offline registry preserves codes, English names and autonyms for 348 active Wikipedia language editions, along with independently supplied text, reading, meaning and source. It preserves Unicode bytes without automatic normalization or translation. The independent ISC data license is included. See [Word Bridges provenance](docs/WORD_BRIDGES.md). The separately hosted profile site named Word Bridges has not been independently verified or imported.

## Distribution and limitations

[Native Android](docs/ANDROID.md) uses a direct NDK NativeActivity and platform packaging tools. Its user-facing file-picker workflow is not yet fully replaced. An Android build is not equivalent to device validation. Release artifacts are subject to original-source SHA verification, native CI tests, checksums and an opt-in tag gate. No production-signed Android package is claimed.

[Native validation](VALIDATION.md) | [Source provenance](docs/PENTAGONAL_XOR_PROVENANCE.md) | [Rights](docs/RIGHTS_REVIEW.md)

Previous application sources and packaging manifests remain discoverable in Git history, but are retired from the current tree. Retirement is not erasure, transfer of authorship or authorization to modify the pinned upstream algorithm.


## PENTAGONAL control family (experimental)

The native C++20 extension implements PENTAGONAL-OR, -AND, -NOP,
-COR, -VISTA and the six-stage FLOP return around the unchanged XOR.
The application sequence is **XOR → OR → AND → NOP → COR → FLOP ↺**
No extra XOR executes at the return point. The COR audit's separate
OR → XOR → AND entry-gate bypass is retained for compatibility.

Read [the full operator, provenance, MCU and optimization study](docs/PENTAGONAL_GATE_CASCADE.md).
Build and run the separate `pentagonal_control` executable for a
structured VISTA JSON report; the pre-existing command remains unchanged.
Missing independently authenticated witnesses are identified, never
silently presumed valid.


### GAMP 4-style Pentagonal operator verification

The new [12-requirement GAMP4-style validation plan](docs/PENTAGONAL_GAMP4_VALIDATION.md),
`native/tests/pentagonal_gamp4_validation_test.cpp` and
`ci/Invoke-PentagonalGamp4.ps1` provide source-preserving,
test-to-requirement evidence for COR/VISTA/FLOP. The pinned
Pentagonal XOR submodule stays unchanged. Automated supplier OQ is
not a regulated-user PQ or QA release approval.


## SUPERTAOISM-GAMP4 Java 17 JAR: YIN, YAN and YANG

A self-contained Java JAR demonstrates three separately audited outcomes:
**YIN** runs TEST → TILT(expected error) → VALIDATE → active RUN for 60 seconds;
**YAN** deliberately fails at runtime with an expected exception and never
enters the 60-second run; **YANG** detects that known failure, compiles a pinned
reviewed replacement on demand, checks all 32 parity states and 30 bit-flip
cases, relinks the validated implementation, and runs actively for 60 seconds.
HotSpot JIT compilation of the replacement is recorded separately from
the application-level JavaCompiler operation.

See [the SUPERTAOISM-GAMP4 technical guide](docs/SUPERTAOISM_GAMP4_JAVA_JAR.md)
and [the dedicated Java → JAR workflow](.github/workflows/supertaoism-gamp4-java-jar.yml).
Original Pentagonal XOR source and source-history identity are preserved.
GAMP4-style supplier tests do not constitute regulated-use validation.


## Five-ligand native LIGAZE binding

The native C++20 `pentagonal_ligaze` executable binds the observed
outcomes of **YIN, YAN, ZING, YING, YANG** through the original 64-bit
PENTAGONAL-COR holder. Its raw program-result mask is `0x15` because
YAN and YING intentionally throw; its all-correct behavioral
conformance mask is `0x1f`. Six named COR five-bit blocks preserve
the original and NOP-pass-through views without manufacturing six
independent observations.

The workflow explicitly verifies the YING expected unhandled **Java**
exception and associated hot-method JIT record. No operating-system
kernel panic is produced. ZING separately tests inverse-square numeric
input and output transformation, zero/NaN rejection, and the actual JIT
trace. DECOMPILED preserves the existing four original scenario
statuses with PENTAGONAL-NOP, rather than suppressing errors.

The native source, CMake test and exact evidence rules are in
[PENTAGONAL_LIGAZE_NATIVE.md](PENTAGONAL_LIGAZE_NATIVE.md).
The Java JAR and native binary are separate compiled artifacts:
the JAR is portable JVM bytecode and LIGAZE is target-specific
machine code. Both are retained by GitHub Actions when all
upstream evidence gates pass. Failed runs and mismatch reports
remain retained as evidence and do not rewrite canonical source.


### COR witness threat model and three-platform benchmark

The [COR STRIDE-style threat model and benchmark protocol](docs/COR_WITNESS_THREAT_MODEL_BENCHMARK.md)
documents the attacker-controlled expected-reference counterexample,
unprotected replay/clock signals, duplicated ligand views, and external
attestation requirements. A clean COR comparison **does not** prove
authenticated provenance.

The [parallel LIGAZE benchmark workflow](.github/workflows/ligaze-cor-threat-benchmark.yml)
compares native C++20 against Java 17 on Windows Server, macOS and
an openSUSE Tumbleweed userspace container. It verifies an identical
COR input stream, output checksum and local negative fixtures
before reporting per-platform median nanoseconds per call. The
openSUSE container uses the Linux host kernel and is not an
openSUSE-kernel performance measurement. No cross-OS absolute
speed ranking or GxP certification is asserted.


### Measured Windows LIGAZE optimization

The [Windows header A/B and MSVC LTCG report](docs/LIGAZE_WINDOWS_OPTIMIZER_AB.md)
preserves the requested full Windows API-shadow experiment as an
isolated, non-shipping header. It documents three paired same-runner
trials in each repository: plain Windows header switches did not
produce a repeatable speedup, whereas MSVC Release /GL + /LTCG
reduced the tested native COR workload latency by about 6% upstream
and 7-11% downstream. Both repositories now enable Release-only
IPO on the native LIGAZE executable and default native benchmark;
the opt-in baseline remains available for future comparisons.
The no-op Win32 overloads are never enabled in normal builds.
