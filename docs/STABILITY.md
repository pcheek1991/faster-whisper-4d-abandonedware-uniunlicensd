# Stability: nine ligands, three interlocked Pentagonal XOR rings, six bytes

**Status:** experimental mathematical protocol `Stability-9L3PX5-U16LE-v1`
for the weight-free Fastest-Whisper-10D PowerShell 7 interface.
Original waveform bytes are not modified. This document is a design
specification and verification record, **not** a cryptographic, clinical,
speaker-identification, or speech-to-text certification.

## Ten-dimensional source and derived output

The streaming acoustic reader measures these *original* nine quantities:

| Index | Original measurement | Normalized ligand |
| --- | --- | --- |
| 0 | `frame_count = N` | `N / (N + 1024)` |
| 1 | `mean_left = mL` | `(1 + mL/(1+abs(mL))) / 2` |
| 2 | `mean_right = mR` | `(1 + mR/(1+abs(mR))) / 2` |
| 3 | `rms_left = rL` | `rL/(1+rL)` |
| 4 | `rms_right = rR` | `rR/(1+rR)` |
| 5 | `peak_left = pL` | `pL/(1+pL)` |
| 6 | `peak_right = pR` | `pR/(1+pR)` |
| 7 | `zero_crossings_left = cL` | `cL/max(1,N-1)` |
| 8 | `zero_crossings_right = cR` | `cR/max(1,N-1)` |
| **9** | **Stability** (derived) | **single scalar below** |

The first nine output values remain the unnormalized physical statistics
recorded from the source, in this original order. The normalizations
produce nine finite ligands `h[0..8]` within `[0,1]`, requiring
`N>=1`; nonnegative RMS/peak values; and integer zero-crossing counts
between `0` and `N-1`. Empty, truncated, or nonfinite source streams
fail instead of producing a success-shaped record.

The earlier Pearson left/right statistic has **not** been erased:
it is now diagnostic metadata `diagnostics.legacy_pearson_lr` rather
than the tenth output dimension.

## Topology: three interlocked pentagons

The implementation selects a symmetric, auditable cyclic overlap.
This precise graph is an **experimental mapping**, not a mathematical
consequence uniquely implied by the phrase "interlocked pentagons."

    Ring I   : 0,1,2,3,4
    Ring II  : 3,4,5,6,7
    Ring III : 6,7,8,0,1

Each ring has five ordered positions. Every pair shares exactly two
ligands, no ligand is common to all three, and together they cover
all nine distinct ligands. This avoids a hidden tenth input.

Each ring uses the original five-input fuzzy odd-parity identity from
Pentagonal XOR:

    P_j = (1 - product_over_indices_in_ring_j(1 - 2*h[index])) / 2

The input is a normalized value, not a Boolean unless it equals 0 or 1.
As with fuzzy parity, interpretation as an actual probability requires
appropriate assumptions about the underlying inputs, particularly
independence. Here the input ligands are generally correlated acoustic
statistics, so these are **algebraic scores**, not calibrated
probabilities of independent physical events.

## A hexabyte is six bytes, not nine bytes

For each of the three ring scores `P_j`:

    U_j = floor(65535 * clamp(P_j, 0, 1) + 0.5)

Each `U_j` is an unsigned 16-bit number. The tie-breaking rule is
**nearest integer, half upward**. Emit exactly six bytes as:

    [ U0 low, U0 high, U1 low, U1 high, U2 low, U2 high ]

The twelve hexadecimal digits in `Stability.hexabyte` encode
those exact six bytes, **little-endian independently of host byte order**.
`Stability.ring_u16`, `Stability.ring_probabilities` and
`Stability.normalized_ligands` retain the uncompressed witnesses.
Quantization is lossy; decoding the hexabyte does **not** reconstruct
the nine inputs or source waveform.

## The tenth scalar: Stability

    Stability = 1 - (max(P0,P1,P2) - min(P0,P1,P2))

This yields `0 <= Stability <= 1` and expresses agreement among the
three algebraic ring scores. A high value is **not automatically**
desirable audio quality, stability through time, or soundness of a
transcription system. In particular all-zero ligands produce three
equal zeros, yielding Stability 1.0.

A separate COREAO-style **maximum discrepancy** could later be used to
check whether an observed hexabyte agrees with the original numeric
witnesses. The current scalar is explicitly ring *agreement*, not a
cryptographic integrity check.

## Exact known-answer tests

| Nine normalized ligands | Ring scores | Six-byte hex | Stability |
| --- | --- | --- | --- |
| Nine zeros | `0,0,0` | `000000000000` | `1` |
| Nine ones | `1,1,1` | `ffffffffffff` | `1` |
| Nine 0.5 values | `0.5,0.5,0.5` | `008000800080` | `1` |
| Only ligand 3 = 1 | `1,1,0` | `ffffffff0000` | `0` |

The independent reference test calculates all 16 odd-parity minterms
per pentagon instead of repeating the production closed form. It
also validates exact byte order, 9-input cardinality, rejection of
nonfinite/out-of-range input, no mutation of the ligand array, and
normalization from a source-vector fixture.

## Interface (PowerShell 7, StrictMode 2.0)

```powershell
pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Fastest-Whisper-10D.ps1 -Analyze10D -RawStereoFloat32Path .\stereo-float32le.raw
```

The JSON has ten dimension names. The tenth is **Stability**.
Additional `Stability` metadata contains the protocol ID, nine
ligands, three ring scores, three 16-bit words, six bytes and twelve
hex digits. Source SHA-256 is independently recorded.

Run the tests without model weights or Python:

```powershell
./ci/Test-Stability.ps1
./ci/Test-10D.ps1
```

GitHub Actions runs these on Windows, Linux and macOS, preserving their
logs and toolchain fingerprints. Passing synthetic tests is evidence
for this deterministic transformation, not evidence that it decodes
spoken words or constitutes independently validated ASR.

## Provenance and versioning

- CORE: original finite stereo float32 samples and nine measured statistics
- Derived: nine normalized ligands, the three five-ligand rings,
  quantized six-byte hex witness and final Stability scalar
- Implementation: `ci/Stability.ps1` (one source definition)
- Readout: `ci/Measure-10D.ps1`
- Verification: `ci/Test-Stability.ps1`, `ci/Test-10D.ps1`
- Licenses: original marked 0BSD additions, inherited MIT sources remain
  separately identified; no pretrained weights included
- Status: **EXPLORATORY**, pending cross-platform CI verification
