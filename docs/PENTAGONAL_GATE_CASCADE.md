# PENTAGONAL: XOR, OR, AND, NOP, COR, VISTA and FLOP

**Status:** Exploratory native C++20 software controller. **License:** 0BSD.
**Dated:** 2026-11-16. This is not an official USAF, DoD or vendor
microcontroller instruction set. AFMAN 17-210 and its PENTAGONAL-COR
narrative are fictional training concepts, not actual published policy.

## Architecture and source invariants

These are six distinct additions to the existing Pentagonal XOR work:

| Name | Meaning |
|---|---|
| PENTAGONAL-XOR | Existing canonical five-way odd parity, unchanged |
| PENTAGONAL-OR | Any true Boolean ligand or canonical probabilistic OR score |
| PENTAGONAL-AND | All five true Boolean ligands or canonical product score |
| PENTAGONAL-NOP | Preserve the prior Boolean state without changing the datum |
| PENTAGONAL-COR | Inspect up to six groups of five ligands; report a 64-bit register, comparison and audit |
| PENTAGONAL-VISTA | Read-only snapshot of reported COR evidence |
| PENTAGONAL-FLOP | Return the next program step to its existing starting gate |

**The requested outer six-stage software sequence is exactly:**

~~~text
XOR → OR → AND → NOP → COR → FLOP ↺
~~~

FLOP returns control to the *existing* XOR entry on the **next** tick.
It does not execute a seventh gate, append XOR at the tail, or start
a hidden busy loop. The calling application schedules each tick.

The original XOR calculation is the mathematical authority for five
continuous inputs in [0,1]. The new Boolean function is a five-bit
specialization. No original scorer was modified, and any independent
extension must be labeled as such.

## Boolean algebra and five-ligand truth table

With bits b0 through b4 in {0,1}, XOR is true for an odd number of
true inputs; OR is true for any nonzero count; AND is true for exactly five.

| True bit count | XOR | OR | AND |
|---|---:|---:|---:|
| 0 | 0 | 0 | 0 |
| 1 | 1 | 1 | 0 |
| 2 | 0 | 1 | 0 |
| 3 | 1 | 1 | 0 |
| 4 | 0 | 1 | 0 |
| 5 | 1 | 1 | 1 |

The 32 Boolean states are exhaustively tested. For *independent*
Bernoulli input parameters p0..p4, the original score expressions are:

~~~text
P(XOR odd) = [1 - product(1 - 2*pi)] / 2
P(OR)      = 1 - product(1 - pi)
P(AND)     = product(pi)
~~~

If ligands are dependent, these remain defined algebraic scores but
are not automatically calibrated probabilities of actual events.
XOR is not authorization: three true inputs satisfy odd parity
while failing the all-five-required AND policy.

## The proposed 64-bit COR operand

COR inspects an observed 30-bit ligand vector against a **separately
provided** expected 30-bit vector, retaining all six blocks of five.
It never changes the source vector or attempts an automatic repair.

| Bits | Field | Meaning |
|---|---|---|
| 63:62 | G_ENTRY | OR=00, XOR=01, AND=10, fault=11 |
| 61:32 | LIG_VEC | Six 5-bit blocks, low block first |
| 31:16 | CYC_CNT | Logical truth-table evaluations |
| 15:0 | RUPT_STAT | Non-destructive anomaly flags |

The COR **inner** sweep follows the older experimental OR → XOR → AND
order. This inner audit order is intentionally different from the
outer application loop and does not change the latter.

| Selector | Inner audit | Logical evaluations |
|---|---|---:|
| OR | OR → XOR → AND | 96 |
| XOR | XOR → AND | 64 |
| AND | AND only | 32 |
| Fault | No sweep | 0 |

The number 32 is the count of Boolean patterns with five bits, not
a number of CPU clocks or verified microcontroller cycles. The other
numbers similarly count logical evaluations, not processor instructions.

RUPT_STAT bits 0..5 identify changed five-bit blocks. Bit 8 means
missing witness, bit 9 means replay/nonfresh sequence, bit 10 means
backward clock observation, and bit 15 indicates an invalid entry.
Other bits are reserved for later explicit review. A mismatch of
11111 versus 10111 yields OR=1, XOR=0, AND=0, and a rupture flag.
The observed datum is still returned intact.

These flags do **not** prove the datum was tampered with by an attacker.
An expected vector stored beside the source can be changed along with it;
for adversarial tamper evidence, an independently authenticated witness
and a protected monotonic record are necessary. A syntactically valid
SHA-256 string is not an authenticated digest. Clock rollback can defeat
some freshness designs but does not automatically confer root privilege.
NIST SP 800-193 describes firmware roots of trust, integrity detection
and recovery, not this custom COR register.

## What real microcontrollers do

Microcontrollers comprise a processor, program/data storage, a clock
system and peripherals. A programmed processor generally fetches,
decodes and executes instructions, with architecture-specific
pipelining and memory behavior. XOR, OR, AND, NOP and branching
are not a universal, mandatory progression through every hardware
instruction. The application deliberately selects the proposed
simplex forward-only state-machine policy.

A real MCU can be idle or use low-power and sleep states. For example,
the ratified RISC-V privileged architecture describes WFI
(Wait for Interrupt), which may stall a hart while waiting for an
interrupt and in some implementations may behave as a NOP.
A running program loop is not proof that current consumption never
changes or that processor clocks cannot be gated. Bidirectional links
are physically possible. PENTAGONAL uses simplex as a *software
control-flow requirement*, not a general law of physics.

## Optimization investigation through depth three

For Boolean parity we compare:

1. **Depth 1:** direct five-way XOR of one five-bit input.
2. **Depth 2:** five circularly rotated copies of that same input,
   each XORed, then XOR their five outputs.
3. **Depth 3:** repeat the rotated-five construction again.

Rotating five bits does not change their parity; the XOR of five
identical parity outputs also has the same parity since five is odd.
The exhaustive 32-case test proves Boolean equivalence, not improved
throughput or independent corroboration. Duplicate inputs are
correlated, so these stacks must not be treated as independent
Bernoulli probabilistic experiments.

The benchmark source measures wall-clock nanoseconds per Boolean
evaluation on its actual compiler, CPU and optimization settings.
The original probability scorer remains the direct path for
continuous input. No theoretical universal speed claim is justified
without specifying hardware, compiler, instruction width, memory,
power envelope, error budget and workload. A trusted HPC system
may prefer minimal parity logic for pure parity tasks, but does
not dispense with required provenance or security controls.

Use cases can be tailored: a resource-constrained MCU may choose
a small static state machine; a performance-oriented service may
choose a direct parity fast path; a data-integrity workflow may
need a protected external witness and strict AND requirements;
an accessibility-oriented monitoring system may choose complete
plain-text VISTA telemetry with retained dissent and uncertainty.

## Reproducibility and academic reference notes

Run native CMake and CTest; the added test covers all 32 Boolean
states, parity agreement with original canonical scores, validation
of invalid inputs, 6 block ruptures, all COR entry positions, NOP,
VISTA, clock/sequence warnings, and the six-stage FLOP reset.
The performance benchmark is a separate executable, not a CTest
pass/fail speed threshold.

Windows PowerShell 7:

~~~powershell
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build --config Release
ctest --test-dir build -C Release --output-on-failure
~~~

Sources informing engineering terms and scope:

- Claude Shannon, A Symbolic Analysis of Relay and Switching Circuits,
  MIT master's thesis (1937; published 1938), switching algebra.
- Harris and Harris, Digital Design and Computer Architecture,
  gates, sequential circuits and physical clocking.
- Hennessy and Patterson, Computer Architecture: A Quantitative
  Approach, quantitative, workload-specific performance assessment.
- RISC-V Privileged ISA, Wait-for-Interrupt:
  https://docs.riscv.org/reference/isa/priv/machine.html
- NIST SP 800-193, Platform Firmware Resiliency Guidelines:
  https://doi.org/10.6028/NIST.SP.800-193

These references do not endorse the project, constitute a security
certification or validate an Air Force manual. Operational efficacy
requires measured timing, independently reviewed threat models and
architecture-specific verification.

**Provenance:** source → operator/route → witness → VISTA → audit.
Corrections or new observations must not silently rewrite old source
records. Failure evidence does not become policy.

### This repository: downstream integration and pinned origin

The Simply-Well-Executed/pentagonal-xor-cpp20 gitlink stays at
fb23b40480476c98e992762ace37761b6fd8ba0e. It is unmodified by
this PR. The independent native/pentagonal_gates.hpp includes
the canonical pinned parity header, and tests its own orchestration.
No alternate probability scorer or automatic submodule update is
introduced. Native DIAMOND behavior is unchanged by default.
Targets: pentagonal_gates_integration_test and
pentagonal_gates_integration_benchmark.
