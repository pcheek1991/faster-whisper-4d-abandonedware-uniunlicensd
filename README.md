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
