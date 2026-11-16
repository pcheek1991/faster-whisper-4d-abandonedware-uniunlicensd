# Canonical source and native DIAMOND operator provenance

Original implementation: Simply-Well-Executed/pentagonal-xor-cpp20, unmodified Git submodule commit fb23b40480476c98e992762ace37761b6fd8ba0e. This pinned source is authoritative over any target-side wrapper or ledger. Its original tests and licenses are preserved.

| Computation | Original source | Native use |
| --- | --- | --- |
| Five-input XOR, AND, OR, partial, fifth-root | shared/pentagonal_xor_std_free.h | Native DIAMOND directly calls original routines |
| DecaSigma, ten named operations | shared/deca_sigma.hpp | Original trace and return witness |
| TriPi forward/reverse/Z-fold | shared/tri_pi.hpp | Original route inspection |
| Scalar COREAO | shared/coreao.hpp | Original audit |
| Fixed RF +9 dBi | shared/coreao_gain.hpp | Original idealized directional EIRP |
| Stability nine ligands and three rings | shared/stability10d.hpp | Original normalization, parity, quantization, hexabyte |
| Stereo COREO | shared/coreo_stereo.hpp | Original forward/inverse/Z-fold |
| Five-channel AND trust guard | shared/swe_guard.cpp | Original 32-state test and metadata validation |
| Exploratory counterarccosine | tests/counterarccosine_secondwave_test.cpp | Original 257-point research witness |

The C++20 DIAMOND translation unit compiles the two original executable sources by renaming entry symbols only within that unit, without altering the upstream source bytes. Native acoustic.cpp independently parses/measures raw float32LE stereo and then calls the original Stability header; it is not a duplicate XOR implementation. Original metadata trust requires AND across all channels; XOR is diagnostic, not authorization. SHA-256 string syntax is not actual artifact authentication.

One conducted watt at the original fixed +9 dBi model yields 7.943282347242816 W idealized EIRP. An explicitly requested +11 dBi uses a separately identified downstream RF offset and yields approximately 12.589254 W. Neither is an audio gain, a hardware measurement or a change to the original operator.

Upstream Stability and stereo COREO files credit the merged PR #17 experimental protocol as their source. New integration preserves that two-way history, not an invented claim of independent origin.

Language metadata consists of 348 Wikimedia Wikipedia edition codes/names/autonyms and source URLs from entitizer/wikipedia-data blob 5f97e44d943f1a5e4c89acce23c5a43afb3fc92d, source generated 2026-09-08. It retains its own ISC license and does not translate. Hosted Word Bridges profile content has not been independently verified.

Shared Guard checks pinned original SHA and recorded file hashes; it runs original and native CTest, verifies release binary and language registry, and restricts publication to trusted tags. Prior application files removed from the active tree remain in Git history. No real ASR, translated speech, device-certified package or production signing is claimed.
