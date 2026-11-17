# PENTAGONAL-LIGAZE: five scenarios held by native C++20 COR

**Status:** experimental, source preserving, 2026-11-16.
**License:** 0BSD. This is a real compiled C++20 executable on each
target OS. The Java 17 JAR is JVM bytecode, **not** a native executable.
No official GAMP/GxP, DOD or Air Force approval is implied.

## Five named ligands and semantic ownership

LIGAZE means **grabbing five verified scenario outcomes into one
five-ligand software observation**, preserving the original identity
of every scenario and passing the result to the existing
PENTAGONAL-COR 64-bit witness record.

| Bit | Ligand | Intended raw behavior | Validation requirement |
|---:|---|---|---|
| 0 | YIN | Healthy 60-second loop | Completes 60 seconds; CTests, TILT, URS pass |
| 1 | YAN | Controlled runtime exception | Fails with exact known exception; no timed run |
| 2 | ZING | Defined inverse-square transform | Valid I/O, zero/NaN rejection and JIT observation |
| 3 | YING | Controlled exception following hot valid JIT-observed method | Correct method compiled, then *application dispatch* switched to throwing method; nonzero exit |
| 4 | YANG | Reviewed and explicitly compiled recovery, 60 seconds | Exhaustive verification, relink, actual JIT evidence and 60 seconds |

With low bit first (YIN first), intended raw program success
mask is **0b10101 = 0x15** (healthy, fault, healthy, fault, healthy).
When **all five intended behaviors are confirmed by CI**, the
conformance mask is **0b11111 = 0x1f**.

**Raw execution success is not validation success.** A designed YAN
exception is raw 0 but a correctly observed expected failure earns
conformance bit 1 = 1. The same applies to YING. A failing
expected-negative test cannot be silently replaced with an all-pass
raw outcome mask.

## The six-block COR binding

The existing 64-bit PENTAGONAL-COR accepts six five-bit blocks within
its 30-bit ligand payload. The LIGAZE representation deliberately
stores six **named views** of these five subjects, not six
independent experiments.

| Block | Five-bit value on approved fixture | Custody |
|---:|---|---|
| 0 | 0x15 | Observed raw outcomes |
| 1 | 0x15 | Specified intended raw outcomes |
| 2 | 0x1f | Observed conformance to all requirements |
| 3 | 0x1f | Specified expected conformance |
| 4 | 0x15 | Observed outcome after PENTAGONAL-NOP pass-through |
| 5 | 0x15 | Intended outcome after PENTAGONAL-NOP pass-through |

The observed 30-bit vector is compared to a reference vector:
blocks 0/4 = expected outcomes, 1 = expected outcomes,
2 = expected conformance, 3 = expected conformance,
5 = expected NOP outcomes.

The native holder delegates to the existing
\`swe::pentagonal::pentagonal_cor\`, with the original **OR → XOR → AND**
inner truth-table audit. On the expected fixture it reports
\`CYC_CNT=96\` logical checks and \`RUPT_STAT=0\`. Those checks
are software truth-table evaluations, not physical clock cycles.

If **one observed raw-outcome bit** changes, rupture flags 0 and 4
assert together, \`RUPT_STAT=0x0011\`. If a conformance bit flips,
flag 2 asserts, \`RUPT_STAT=0x0004\`. The original source and
expected values are never rewritten.

For raw mask 0x15, PENTAGONAL-XOR=1, PENTAGONAL-OR=1 and
PENTAGONAL-AND=0. For conformance mask 0x1f, AND=1.
Neither raw parity nor OR alone establishes validation; all
five required conformance checks must be present.

## Native C++20 binary, not a mislabeled JAR

The exact native target is \`pentagonal_ligaze\` on Unix-like systems
and \`pentagonal_ligaze.exe\` on Windows. It is compiled from
\`tools/pentagonal_ligaze.cpp\` or \`native/pentagonal_ligaze.cpp\`
and includes the project-owned \`pentagonal_ligaze.hpp\`, which
itself reuses the original, unchanged Pentagonal gate controller.

It emits one machine-readable JSON audit record. Source mutation and
external authentication are both explicitly reported as false.
A local expected mask is **not** a signed, externally protected
trust root.

~~~powershell
cmake -S . -B build-ligaze -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build-ligaze --config Release --target pentagonal_ligaze pentagonal_ligaze_test
ctest --test-dir build-ligaze -C Release -R ligaze --output-on-failure
# On Windows:
./build-ligaze/Release/pentagonal_ligaze.exe 0x15 0x15 0x1f 0x1f
# On Linux:
./build-ligaze/pentagonal_ligaze 0x15 0x15 0x1f 0x1f
~~~

The four ordered arguments are observed raw outcomes, intended
raw outcomes, observed conformance, and intended conformance.
A detected mismatch is **reported in JSON**, not automatically
quarantined or rewritten.

CI binds LIGAZE only after checking actual YIN, YAN, ZING, YING
and YANG evidence from the same Git SHA. It then invokes the
compiled executable, checks the exact 0x15/0x1f result, and
injects a second deliberate raw bit flip as a negative control.

## Engineering and validation limits

- A C++20 executable is genuinely compiled to the runner's native
  instruction set, but the build artifact is platform-specific.
- A Java class/JAR remains bytecode until or unless JVM JIT
  generates machine code for individual hot methods. This is
  distinct from the native LIGAZE executable.
- A deliberately injected YING failure is an **unhandled Java
  process exception**, not an operating-system kernel panic.
  HotSpot itself did not autonomously choose to inject a bug;
  the application deliberately changed a call-site target.
- ZING applies an inverse-square numerical transform only to
  valid positive scalar inputs/outputs. Its control-plane
  metadata, source identity and flags are not physically
  meaningful inputs to an inverse-square law.
- DECOMPILED remains a NOP-preserving **report overlay**, not a
  bytecode disassembler or a way to suppress negative results.
- The 64-bit COR operand is a defined software record. Its
  integrity comparison detects differences relative to supplied
  expected values; it cannot establish cryptographic integrity
  against simultaneous tampering with both sides.
- The full GAMP4-style validation matrix and supplier tests are
  relevant evidence but not an independently signed GxP audit.

**Provenance:** original outputs → expected behavior → conformance
→ Pentagonal-NOP-preserved views → PENTAGONAL-COR → native binary JSON
→ Git SHA and CI evidence → review. A difference must remain
observable and attributable, never silently repaired.

Downstream source authority: the pinned upstream gitlink is unchanged.
