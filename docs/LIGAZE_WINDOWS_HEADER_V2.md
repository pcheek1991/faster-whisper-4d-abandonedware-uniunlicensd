# Windows LIGAZE platform header v2: architecture, API integrity and benchmarks

Status: exploratory, not a regulatory, cryptographic or security certification.
LTCG remains the previously validated native Windows Release optimization.

## Source custody

The user's new v2 header is preserved as a separate, opt-in experiment at
benchmarks/windows_ligaze_user_header_v2_experiment.hpp (upstream)
and native/benchmarks/windows_ligaze_user_header_v2_experiment.hpp
(downstream). It retains Windows/Cygwin detection, the nine prioritized
Windows architecture families (ARM64EC precedes ARM64), 37 proposed
NO* header exclusions, the requested macro undefinitions, and all
118 groups of variadic no-op Win32 API replacements. Those experimental
stubs are enclosed in a Windows-only guard to avoid polluting Linux/macOS.
This file is NEVER a shipping dependency.

Microsoft describes WIN32_LEAN_AND_MEAN and NOapi switches as reducing
Windows header declarations/compilation size. They are not guaranteed
native runtime optimizers:
https://learn.microsoft.com/en-us/windows/win32/winprog/using-the-windows-headers

The variadic functions may accept otherwise invalid API calls and can
silently substitute an empty function for a real Windows operation.
See Microsoft's C++ overload rules:
https://learn.microsoft.com/en-us/cpp/cpp/function-overloading

## Safe evolved platform header

The separately authored safe C++20 architecture header lives at
shared/pentagonal_platform_windows_v2.hpp upstream and
native/pentagonal_platform_windows_v2.hpp downstream. It detects
Windows and Cygwin separately, encodes build-target architecture as
a namespaced enum, and confines STRICT, WIN32_LEAN_AND_MEAN and
NOMINMAX to Windows. It does not undefine Windows macros after
the include, enable broad NOapi exclusions or replace OS functions.
Architecture metadata is compile-time evidence, not a processor
feature test or clock-speed tuning algorithm.

## Fail-closed API contract

tests/pentagonal_platform_v2_contract.cpp upstream and
native/tests/pentagonal_platform_v2_contract.cpp downstream are
compiled and checked on all supported host environments.

The Windows compile contract requires the true typed CreateFileW
signature. Two-argument Sleep and one-argument CreateFileW must be
rejected: such calls cannot be allowed to resolve to dummy void(...)
functions. The new full_header_v2 variant is an expected-negative
test: a compiler rejection is retained as evidence, and its binary
is never eligible for production even if it could benchmark faster.

## Incremental A/B design

Windows A/B now includes platform_v2, platform_v2_ltcg and
full_header_v2 in addition to the previous five candidate variants.

- platform_v2: compare against pre-LTCG baseline.
- platform_v2_ltcg: compare against the already promoted LTCG
  configuration, so a speed change is attributable to the header
  rather than to the existing compiler optimization.
- full_header_v2: expected to fail the real Win32 API contract
  and never eligible for promotion.

Each viable candidate must compile, pass native COR tests,
preserve the Java 17 semantic checksum and pass three same-runner
paired trials with five measured repetition medians per trial.
A candidate must reduce latency by at least 5% in each pair
against the correct reference, and retain valid API behavior.

Windows, macOS and openSUSE baseline jobs now compile the safe
platform contract test as part of their CMake/C++20 checks.
The openSUSE container uses a Linux host kernel and does not
represent a separate booted openSUSE kernel.

## Integrity limits

The canonical Pentagonal XOR source, pinned submodule, 64-bit COR
semantics and GAMP4 results are not rewritten by these experiments.
Performance results cannot justify API semantics changes. Neither
a compile-time architecture marker nor a local COR comparison is
an independent cryptographic witness. Failed experiments remain
reviewable as evidence, not new policy. Only safe, independently
validated improvements may be enabled by default.


## Observed v2 experiment acceptance (measured commit 02c6a1f641a614a26a5e188293e3ab11826dac5e)

The full [parallel CI run](https://github.com/pcheek1991/faster-whisper-4d-abandonedware-uniunlicensd/actions/runs/43994724622) completed successfully: three independent Windows/macOS/openSUSE baseline jobs, and one Windows multi-variant A/B job. All original COR and Java/native checksums matched.

Every safe v2 build and COR test passed. The full_header_v2 benchmark source compiled but the **mandatory Win32 API contract target intentionally failed**, with MSVC C2338 static assertions proving that the extra no-op overloads incorrectly accept two-argument Sleep and one-argument CreateFileW calls. This was a correctly observed expected-negative result, not a successful full-header binary.

### Measured latency (nanoseconds/COR, matched control → candidate)

| v2 variant | Pair 1 | Pair 2 | Pair 3 | Accepted as runtime optimization? |
|---|---:|---:|---:|---|
| Safe platform v2 vs original baseline | 111.4508 → 111.3738 | 111.6272 → 111.7926 | 111.0534 → 111.0266 | No |
| Safe platform v2 + LTCG vs **LTCG alone** | 105.4726 → 105.2974 | 105.2492 → 106.6748 | 105.2276 → 105.2872 | No |
| Expanded v2 header with WinAPI no-ops | Compiler contract rejected | Not timed | Not timed | **Prohibited** |

The existing native LTCG-only comparison recorded 4.5%, 4.7%, and 5.6% lower latency, which failed the strict all-three 5% threshold in this repeat. This is a single-runner result and does not replace earlier positive trials; preserve both. No Windows safe-platform-v2 default was promoted, and no Win32 API stub was added to production. All v2 source files remain available for review, follow-up experiments and auditing.

The tested Windows runner was x64; architectures ARM64EC, ARM64, ARM32, IA64, MIPS, ALPHA and PPC are defined in metadata but were **not** directly hardware-tested in this run. This work does not demonstrate universal CPU performance or cross-hardware predictability.
