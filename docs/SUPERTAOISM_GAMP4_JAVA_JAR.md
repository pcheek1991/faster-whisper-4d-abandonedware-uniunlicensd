# SUPERTAOISM-GAMP4 | Native Java 17 JAR | YIN, YAN, YANG

**Status:** experimental supplier-side education and validation. 0BSD
authored software. This is not official GAMP certification,
FDA Part 11 compliance, qualified pharmaceutical software,
formal operational/PQ approval, or an official USAF publication.

## 1. Program concept and exact six-stage control

The difference between writing code, compiling instructions and
running them is observable. A Java file may compile successfully
yet fail only when a particular method is invoked. JVM JIT
optimizes bytecode: it does not automatically decide whether
that bytecode is trustworthy. A garbage collector manages object
memory, not ethical or program-correctness repairs.

The original user-defined outer control order remains exactly:

~~~text
XOR → OR → AND → NOP → COR → FLOP ↺
~~~

FLOP branches to the existing XOR entry on a subsequent tick;
there is no seventh appended XOR. The inner COR audit separately
uses OR → XOR → AND with 96/64/32 logical evaluations.

## 2. SUPERTAOISM-GAMP4 truth and execution paths

| Path | Expected result | How confirmed |
| --- | --- | --- |
| YIN TEST | Source and 32 Boolean states correct | C++20 CTest and Java reference |
| YIN TILT | Injected one-bit difference detected | Actual rupture flag, not a file overwrite |
| YIN VALIDATE | All twelve existing URS tests pass | GAMP 4-style supplier OQ and SHA-256 audit |
| YIN RUN | Original class works at least 60 seconds | Actual System.nanoTime duration, ticks and six-stage loops |
| YAN | Poison class compiles but fails upon first runtime invocation | Expected NONZERO process exit and exact IllegalStateException marker; 60-second run never starts |
| YANG PREFLIGHT | Detect poison and compile reviewed replacement around it | JavaCompiler API, SHA-256 reviewed source, isolated class loader, MutableCallSite relinking, 32 truth states and 30 bit-flip cases |
| YANG RUN | Replacement works at least 60 seconds | Actual loops, monotonic elapsed duration, HotSpot ApprovedRecovery::cycle compilation log |
| AUDIT | No original source changed | Separate JSON report and SHA-256 records; code review and QA limitations reported |

In YAN the nested PoisonedCycle class intentionally throws
IllegalStateException with exact marker
SUPERTAOISM_YAN_RUNTIME_POISON. It is a controlled negative test
that must **not** be marked an application success. CI succeeds
only because it independently proves that YAN failed as designed.
It does not enter a timed RUN or silently accept a default result.

In YANG, the same known failure is encountered and identified.
Only after a precise match does the JVM application use its
standard JavaCompiler interface to compile a separately reviewed
ApprovedRecovery Java source string. The runtime-loaded
class is validated both before and after MutableCallSite is
explicitly re-bound. The recovery performs every stage including
real COR and VISTA checks. It does not suppress the exception
by skipping the path or by returning a fake/constant success
from the original poisoned class.

Approved recovery string SHA-256:

~~~text
dd57ce6e8bbeeaad4af14cb06a08ec83c38d2deab16e814f97e963f5a94b0114
~~~

This embedded digest is not a cryptographic signing root.
An attacker who modifies both the source and digest can fool
a local comparison. In production this would require independently
approved/signed code and protected provenance outside the application.

## 3. JIT terminology: two independent mechanisms

1. **Application-level on-demand compilation:** JavaCompiler
   generates new JVM class bytecode from pinned Java source
   at runtime. A URLClassLoader loads the new class.
   MutableCallSite switches future dispatch to the already
   validated replacement. These are explicit developer
   operations; they are not magical spontaneous error repair.

2. **HotSpot JIT compilation:** the JVM optimizer compiles
   active bytecode to machine code. The workflow requests
   the Java 17 HotSpot JIT compilation log separately from
   application stdout and verifies at least one observed
   ApprovedRecovery::cycle compilation entry. This is real
   evidence that the JVM optimized the recovery method,
   not evidence that it found or corrected the original poison.

No JIT option is equivalent to a security approval and no
optimizer should be trusted to classify malicious instructions.

## 4. Java → JAR construction

All Java source code is standard Java 17, no Gradle, Maven,
Python, custom JS, external dependency download or code
transcoding. The authored class is self-contained and
uses only JDK modules. A **full JDK**, not a JRE-only
installation, is required for on-demand JavaCompiler in YANG.

~~~powershell
New-Item -ItemType Directory -Force build-supertaoism/java-classes | Out-Null
javac --release 17 -encoding UTF-8 -d build-supertaoism/java-classes java/PentagonalControl.java java/SupertaoismGamp4.java
jar --create --file build-supertaoism/pentagonal-supertaoism.jar --main-class SupertaoismGamp4 -C build-supertaoism/java-classes .
java -jar build-supertaoism/pentagonal-supertaoism.jar --yin-test
java -jar build-supertaoism/pentagonal-supertaoism.jar --yin-tilt
java -jar build-supertaoism/pentagonal-supertaoism.jar --yin-validate
java -jar build-supertaoism/pentagonal-supertaoism.jar --yin-run 60
# The next command is deliberately expected to exit with an error.
java -jar build-supertaoism/pentagonal-supertaoism.jar --yan
java -jar build-supertaoism/pentagonal-supertaoism.jar --yang-preflight
java -jar build-supertaoism/pentagonal-supertaoism.jar --yang-run 60
~~~

The GitHub Actions workflow is in the repository at
.github/workflows/supertaoism-gamp4-java-jar.yml.
The PowerShell 7 evidence orchestrator is
ci/Invoke-SupertaoismGamp4.ps1.

YIN and YANG each perform 60 seconds of actual active work;
compilation, checkout and validation occur outside those
timed intervals. YAN never executes a 60-second run.

The official GitHub artifact-upload action stores the validated
executable JAR for 30 days and supplier evidence logs for 90 days
according to the workflow configuration. This is platform
artifact transport, not a Node dependency in the Java software.
The primary executable and tests do not use JavaScript or Node.

## 5. Academic integrity and risk disposition

Requirements, observed traces, faults and source fingerprints
must remain distinct. C++20 stays authoritative for its
canonical Pentagonal scores; the Java JAR is a separately
reviewable reference. No source data or pinned gitlink is
rewritten by this experiment.

A successful runtime recovery is conditional on the source
and the replacement being trustworthy. Deliberately
compiling unknown strings into privileged runtimes can
enable code injection. This demonstration compiles only
a fixed audited source string, checks it, and isolates
the dynamic class in a disposable loader.

Environmental, hardware timing and throughput conclusions
cannot be generalized from one GitHub Actions runner.
GAMP4-style supplier tests do not establish GxP regulatory
compliance. Actual user-intended operational PQ, independent
QA approval, electronic records controls, authenticated
build provenance and production release remain OPEN.

**Failure remains evidence. A recognized error is not
permission to silently rewrite what was published.**

### Downstream source identity
The pinned upstream Pentagonal XOR gitlink remains
fb23b40480476c98e992762ace37761b6fd8ba0e.
No update to the original gitlink or native DIAMOND defaults.


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
