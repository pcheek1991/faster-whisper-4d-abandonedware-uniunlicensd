# COR witness: security threat model and parallel native-versus-Java benchmark

**Status:** experimental supplier assurance, not regulatory or cryptographic certification. Date: 2026-11-16.

## Claims, assets, and trust boundaries

PENTAGONAL-COR's 64-bit software word contains a two-bit entry
selector, 30-bit ligand vector, 16-bit *logical-evaluation* count, and
16-bit rupture flags. COR compares an observed vector to an expected
vector supplied by the caller. A zero rupture flag means those *locally
supplied values* agree; it does not establish independent provenance,
freshness, authorization or resistance to adversarial tampering.

Assets: original datum, expected reference, scenario exit outcomes,
COR witness, NOP-derived views, Git commit, trusted build/runtime,
CI evidence and human release decision.

Threat actors: accidental errors; a malicious or compromised author,
build runner, expected-reference maintainer, artifact store, clock
source or operator. These are threat scenarios, not allegations.

Trust boundaries are source to reference, reference to COR, COR to
derived VISTA, CI runner to artifact, compiler to executable, and
artifact to independent reviewer. A single principal controlling
both compared values cannot independently authenticate either.

## STRIDE-style register

| ID | Risk and mechanism | Severity for claimed authenticity | Mitigation |
|---|---|---|---|
| T01 | Spoof observed **and** expected values with identical changes | Critical | Independent signed digest over complete canonical record; externally protected verifying key |
| T02 | Replay an old intact COR record; same operand recurs | High | Externally signed monotonic sequence, nonce and bounded freshness window |
| T03 | Falsify the caller-provided clock or replay boolean | High | Trusted monotonic counter and independent time source; record clock discontinuities |
| T04 | Tamper with the CI job or stored PASS report | High | Protected branches, least privilege, artifact verification, signed attestations, separate approval |
| T05 | Mask away bits above the 30-bit ligand field | High | Reject oversized canonical data *before* packing; preserve full original bytes |
| T06 | Collapse many bit differences into one block rupture flag | Medium | Preserve full bytes and exact bitwise diff; do not infer individual changed bits from one flag |
| T07 | Count six dependent COR views as six independent measurements | High | Record derivation and correlation; no probabilistic multiplication of copies |
| T08 | Compromise the compiler, JVM, dependencies or binary | High | Toolchain pinning, code review, reproducible builds and independent test runners |
| T09 | Trigger excessive runtime work or malformed input | Medium | Validate bounds and run under isolated resource quotas |
| T10 | Misinterpret intentional YAN/YING runtime faults as conformance failures | Medium | Preserve raw outcome 0x15 separately from expected-behavior conformance 0x1f |
| T11 | Overclaim a speedup due to optimizer, JIT warm-up or runner noise | Medium | Exact deterministic workload, repeated medians, checksums and environment metadata |
| T12 | Use a detected mismatch to justify silent source rewriting | High | Fail visibly and retain history; changes require a new reviewed identity |

Unresolved T01, T02, T03 and T04 remain critical or high residual
risks without an independent trust anchor. SHA-256 calculated beside
the source is a digest, **not** an authenticated signature. There is
no MAC, signer identity, hardware timestamp or certificate inside
the proposed 64-bit operand. CYC_CNT=96/64/32 represents truth-table
evaluations, **not physical microcontroller clock cycles**.

## Explicit test counterexamples

Native C++20 and Java 17 each check before benchmarking:

- Clean expected raw mask 0x15: COR rupture 0.
- One changed observed raw bit 0x14 against expected 0x15:
  rupture 0x0011, affecting observed and NOP-preserved views.
- Both expected and observed changed to 0x14: rupture **0**
  despite changed underlying data. This is a deliberate,
  reproduced *counterexample* to a claim of authentication.
- Conformance bit changed from 0x1f to 0x1e: rupture 0x0004.
- Exact replay of an intact record: COR word unchanged.
- Missing-witness, replay, and backward-clock signals set flags
  only when the *caller supplies* their booleans. They are
  indicators, not secure measurements or signed attestations.

COR retaining these negative cases and preserving the original
datum is essential to the audit. A local success does not establish
a population-wide false-negative probability against attackers.

## Comparable native versus Java workload

Implementations:
- Upstream native: benchmarks/pentagonal_ligaze_benchmark.cpp
- Downstream native: native/benchmarks/pentagonal_ligaze_benchmark.cpp
- Both Java: java/LigazeJavaBenchmark.java

Both use an identical 32-bit LCG seeded with 0x0badf00d,
multiplier 1664525, increment 1013904223, wrapping modulo 2^32.
Each step chooses raw=(state >>> 8)&31 and
conformance=(state >>> 16)&31, with expected raw=0x15 and
required conformance=0x1f. Both construct the same six-block
30-bit COR input, perform the 96-evaluation OR-entry audit,
validate the exact expected rupture flags, and sum the same
checksum (flags*131 + raw + conformance).

Warm-up is 50,000 calls; each of five measured repetitions runs
500,000 calls. Timing sections exclude build, file I/O, startup,
Docker image creation and package installation. The reported
metric is median nanoseconds per COR API evaluation plus the
per-repetition samples. In each runner the pipeline requires
native and Java *identical checksums* and successful negative tests.

Java allocates records/collections while the native path uses
C++ value objects. This measures the real **end-to-end COR API
workload** with implementation-specific memory/JIT costs, not
pure gate instruction latency. Runtime, compiler flags, JVM
GC/JIT and CPU architecture differ; medians are **not** universal
speed rankings. Lower time on one runner is not evidence of
security superiority. No speed threshold forces an arbitrary
winner.

## Platform execution and reproducibility

| Requested platform | CI environment | Caveat |
|---|---|---|
| Windows | windows-2025, Windows Server x64, MSVC Release, Temurin Java 17 | Hosted VM and its specific CPU |
| macOS | macos-15, Apple Silicon, Clang Release, Temurin Java 17 | Different architecture/CPU from Windows |
| openSUSE | Ubuntu 24.04 host, openSUSE Tumbleweed container with GCC, CMake and OpenJDK 17 | Real openSUSE userspace, **Ubuntu-host Linux kernel**; not a separate openSUSE VM |

The workflow runs these as three parallel jobs, with fail-fast
disabled and separate per-platform results. The openSUSE image
is installed before the timing interval, and benchmark containers
run without network access. Image tags may drift; for rigorous
longitudinal comparisons, pin digest/JDK/compiler and runner
class, retain full Git commit, and start a new study identifier
on any change. Hardware and image versions must not be assumed
identical just because an OS label is identical.

No Python, Node, npm, Gradle, Maven or custom JavaScript build
code is included. PowerShell 7 coordinates the jobs, while
CMake/C++20 and standard JDK17 compile the tested software.
The workflow may use standard GitHub Actions maintained by the
platform for JDK setup and artifact upload; those Actions are
external automation, not runtime dependencies of this project.

## Evidence and acceptance

Workflow: .github/workflows/ligaze-cor-threat-benchmark.yml

Each job writes one JSON report containing the platform, actual
runner/kernel environment label, Git SHA, native and Java timings,
source/binary SHA-256, identical checksum, local threat fixtures,
and risk limitations. It also records its raw build/CTest logs
in GitHub Actions. All three jobs must pass before the matrix
is accepted, and a failed platform is not treated as a success
merely because other platforms passed.

GAMP4-style supplier testing remains distinct from regulated
IQ/OQ/PQ or independent QA release. External attestation and
adversarial provenance guarantees remain OPEN.
