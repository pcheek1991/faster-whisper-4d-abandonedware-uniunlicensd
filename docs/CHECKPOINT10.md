# Checkpoint 10 · Coreo 4D audit and CI evidence

**Status:** experimental, read-only verification addition; **not** a
claim of independently validated speech-recognition accuracy or a
four-dimensional physical model. This branch does not change default
Whisper transcription or CTranslate2 inference.

## What is borrowed from the Pentagonal XOR journey

| Transferable lesson | Applied here | Boundary |
| --- | --- | --- |
| CORE source remains authoritative | Source stereo frames are never modified by the independent audit | Derived channels are not independent source evidence |
| Forward, reverse and Z-fold witnesses | Compare all four Coreo lanes with the original synthetic frames | No XOR probability formula is imported into audio |
| One scalar, no averaging away failure | Maximum of all channel discrepancies | Zero is internal consistency, not authenticity |
| Failure remains evidence | Upload pre-flight and converter logs on failures | No retroactive synthetic hashes for older CI |
| Portability is tested rather than assumed | PowerShell 7 checks on Windows, Linux and macOS | GPU transcription remains outside this matrix |
| Entire output is distributable only with rights | Auto-PyPI publishing disabled until legal review | No automatic 0BSD grant over upstream sources or models |
| No paused debug-only code in production | Source pre-flight rejects explicit debugger stops | Normal safety checks, runtime guards and evidence remain |

## Stability and Android experiment (latest extension)

The tenth PowerShell acoustic output is now [Stability](STABILITY.md):
three interlocked Pentagonal XOR rings over nine normalized ligands,
with three quantized `uint16` witnesses constituting a six-byte
little-endian hexabyte. The source's previous tenth Pearson statistic
is retained as diagnostic metadata.

[Android experimental APK](ANDROID.md) implements the same
`Stability-9L3PX5-U16LE-v1` topology in pure Java 17, without
model weights or network permissions. The PowerShell 7 test matrix
also includes macOS Apple Silicon. These are **new** experiments,
not evidence of trained speech-to-text.

## Exact mathematical inspection

A finite source of N stereo float32 frames is
`S[k] = (L[k], R[k])`, 0 ≤ k < N. Let the four-channel Coreo
result for frame k be `Q[k] = (A[k],B[k],C[k],D[k])`.

The observed mapping, transcribed from the bundled PowerShell/C# script:

    A[k] = -L[N-1-k]
    B[k] = -R[N-1-k]
    C[k] = -L[k]
    D[k] = -R[k]

The independent scalar check uses the worst discrepancy:

    delta = max over all k of:
      abs(A[k] + L[N-1-k])
      abs(B[k] + R[N-1-k])
      abs(C[k] + L[k])
      abs(D[k] + R[k])
      abs(A[k] - C[N-1-k])
      abs(B[k] - D[N-1-k])

The last two are Z-fold correspondences. Because the inverse of
negating and reversing twice returns the original frames, this is a
testable *source-path reconstruction*, not a lossy mean score.
A corrupted lane must increase delta; the fixture intentionally
changes one output sample and verifies that it is detected.

A synthetic exact fixture uses source frames (1,10), (2,20), (3,30)
and expects four-channel output:

    (-3,-30,-1,-10)
    (-2,-20,-2,-20)
    (-1,-10,-3,-30)

Other fixtures verify empty input, non-finite input, and incomplete
stereo frames. Invalid cases must fail with no transformed bytes.
The bundled converter's own stream self-tests also run.

**Definedness first:** the scalar is meaningful only for a complete,
finite, correctly shaped stream. The converter determines admissibility;
the audit tests its behavior, not a bypass of its checks.

## Running the new tests (PowerShell 7)

    ./ci/Test-ReleaseReadiness.ps1
    ./ci/Test-CoreoContract.ps1
    ./ci/Write-CheckpointEvidence.ps1 -EvidenceDir evidence
    ./ci/Test-CheckpointEvidence.ps1 -EvidenceDir evidence

No model weights are downloaded. No actual recordings or transcripts are
read, reproduced or uploaded by this pipeline. This deliberately keeps
new automation in PowerShell 7 and uses the existing C# converter.

The original Python transcription source remains untouched. Its
native tests continue in the existing Python-version matrix; the new
PowerShell audit does not pretend to replace those tests.

## Run-specific SHA-256 provenance

The `checkpoint10.yml` workflow runs Windows x64, Linux x64 and macOS ARM64.
Each job creates the `evidence/` directory before validation, then
attempts to collect files even if a preceding step fails.

- `preflight.log` and `coreo-contract.log`: synthetic-only test output,
  including diagnostic failures.
- `manifest.json`: checkout and requested commit SHA, runner OS/arch,
  PowerShell version, tool executable paths and SHA-256 **when located**,
  and SHA-256 of all tracked source files without including their bytes.
- `SHA256SUMS`: digest of each evidence-bundle member except the checksum
  file itself, and a separate self-verification step.
- Artifact retention requested for 90 days, subject to GitHub limits.

Only synthetic fixture checksums, logs and source/tool fingerprints go
into these uploaded evidence bundles. Avoid logging secrets, recordings,
transcripts, private model data or unreviewed assets.

The toolchain fingerprints document bytes observed on the *new*
runner. They do not transfer licenses or reconstruct the original
compiler binary from a prior Windows run. A public digest does not prove
publisher authenticity.

## What is NOT claimed

- Nothing here benchmarks WER, accuracy, latency, GPU/CUDA, VAD model
  performance or multi-speaker diarization.
- No claim that the new checks validate real-world medical, legal, or
  safety-critical transcription.
- No claim that the original fork is 0BSD or that public source URLs
  guarantee redistribution rights. See [RIGHTS_REVIEW.md](RIGHTS_REVIEW.md).
- No claim that passing correlated channel checks authenticates the
  source sample. One input underlies all comparisons.
- No guarantee that GitHub Actions artifacts are immutable or perpetual.

**Failure remains a dated observation. Corrective commits append an
auditable record, not erase or rewrite the earlier attempt.**
