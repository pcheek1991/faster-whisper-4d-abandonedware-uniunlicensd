# Pentagonal TEST → TILT → VALIDATE → RUN, Java 17 and C++20

**Status:** experimental supplier-side qualification, not GMP/Part 11
certification, hardware certification, or a claim of authenticated integrity.

## The corrected TILT sequence

The four workflow steps, in order, are:

1. **TEST:** build all original C/C++20 targets, run all CTests,
   compile the single self-contained Java class using javac, and run
   exhaustive Java reference checks. Original source remains unchanged.
2. **TILT (with error):** inject one deliberate bit difference only in a
   *test operand*, with a separately supplied reference of 0x3fffffff.
   Observed 0x3ffffffb flips bit 2 of the first 5-ligand block.
   The original source is never edited. Expected reports: XOR 0, OR 1,
   AND 0, RUPT_STAT bit 0 = 1. Both native C++ and Java must recognize
   this as the expected negative test. An *undetected* change fails CI.
3. **VALIDATE:** execute all URS-11..URS-22 tests using the existing
   PowerShell GAMP 4-style evidence runner. Confirm all 12 requirements
   passed, verify the source commit, evidence and hashes, and retain
   open IQ/PQ/QA controls as explicitly not approved.
4. **RUN:** only after prior stages passed, perform **60 seconds of
   active Pentagonal software loop execution** in Java. Measure
   elapsed time with System.nanoTime, report count of evaluated ticks
   and completed cycles, and assert elapsed >= 60. No sleep, busy
   spinning under a false claim of hardware security, clock freeze,
   or automatic background scheduling is performed.

## Six-stage control, with no appended seventh XOR

~~~text
XOR → OR → AND → NOP → COR → FLOP ↺
~~~

FLOP updates the next state to the existing XOR entry. The switch
executes a single stage per tick. The nested COR audit still uses
OR → XOR → AND and interprets 96/64/32 as *logical evaluations*,
not physical CPU clock cycles.

## Standalone Java reference

File: java/PentagonalControl.java

All operations are Java 17 standard library only. No Gradle, Maven,
Node, Python, transcompiler, network calls or binary package download
is part of the source.

~~~powershell
javac -encoding UTF-8 java/PentagonalControl.java
java -cp java PentagonalControl --self-test
java -cp java PentagonalControl --tilt
java -cp java PentagonalControl --vista 0x3ffffffb 0x3fffffff or
java -cp java PentagonalControl --stress 60
~~~

The Java class implements Boolean PENTAGONAL-XOR, -OR, -AND,
PENTAGONAL-NOP, 64-bit PENTAGONAL-COR, read-only PENTAGONAL-VISTA
and PENTAGONAL-FLOP, plus the five-feature continuous
odd-parity/OR/AND score formulas. The continuous formulas agree
with the original source's documented mathematical identities;
this is an explicitly labeled *Java language reference*, not a
claim that canonical C++ source is now a different language.

## Audit controls and limitations

- The 30-bit ligand vector contains six groups of five bits. The
  64-bit COR record has 2-bit entry, 30-bit observed data, 16-bit
  logical count, and 16-bit rupture/status field.
- This is differential detection against a supplied reference, not a
  secure digital signature. A malicious actor who can modify both
  observed and expected values can defeat a local comparison.
- Clock regression and replay are modeled as caller-supplied
  flags, not autonomously authenticated hardware measurements.
- Continuous scores have probability interpretations only when
  the respective Bernoulli-independence assumptions hold.
- GitHub Actions logs and step summaries contain execution evidence
  linked to the exact Git commit. SHA-256 reporting is not an
  independently signed attestation, nor proof of operational PQ.
- The 60-second active runtime evaluates software behavior and
  timeboxing. It does not benchmark an aerospace microcontroller,
  prove uptime, or guarantee that a CPU cannot sleep.
- All failures remain linked to their actual run and original data;
  an expected fault test is a PASS only if the fault is detected.
- The root project remains source-of-truth for the original C++20/C11
  scorer, and downstream's pinned gitlink must remain unchanged.

## CI

Workflow: .github/workflows/test-tilt-validate-run.yml

The workflow is enabled for pushes to the existing feature branch
and can also run when the file reaches the default branch. Its
successive steps are gated by prior step success. The run step's
time budget is exactly **60 seconds of active execution**, not
60 seconds of waiting for external work. GitHub Actions startup
and compilation time are additional.
