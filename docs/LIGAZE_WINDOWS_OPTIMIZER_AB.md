# LIGAZE Windows MSVC optimizer A/B: source, measurements, and promotion

Date: November 16, 2026 Pacific / November 17 UTC.
Status: experimental supplier-side benchmark evidence, not security certification.

## 1. Original input and guardrails

The user's complete requested Windows header is preserved as
benchmarks/windows_ligaze_user_header_experiment.hpp upstream,
and native/benchmarks/windows_ligaze_user_header_experiment.hpp downstream.
It defines STRICT, WIN32_LEAN_AND_MEAN, NOMINMAX, includes windows.h,
undefines the requested macros, and declares do-nothing
inline void Win32ApiName(...) overloads for the named Win32 functions.

This is an isolated opt-in test fixture, not a runtime optimizer.
The do-nothing overloads can shadow, confuse or intercept real
Windows API calls such as CreateFile and Sleep. Compile success
and microbenchmark speed do NOT make such replacements safe.
Do not promote the full header into shipping source code.

The separate safe_header experiment defines only STRICT,
WIN32_LEAN_AND_MEAN, NOMINMAX, and includes windows.h. These
affect type safety/header processing and naming, not CPU
instruction scheduling. Microsoft's /O2 is already the
default MSVC Release optimization. The actual new optimizer
candidate is whole-program link-time compilation /GL + /LTCG.

## 2. Controlled experiment

Workflow:
.github/workflows/ligaze-windows-header-optimizer-ab.yml

PowerShell 7 controller:
ci/Invoke-LigazeWindowsAB.ps1

The four parallel jobs in each repository:
- Windows baseline native versus Java repeat.
- macOS baseline native versus Java repeat.
- openSUSE Tumbleweed container baseline repeat on Ubuntu host.
- Windows-only same-runner paired A/B trial.

Five Windows candidate variants are independently compiled:
baseline, safe_header, full_header, ltcg,
and safe_header_ltcg.

Every candidate must compile, pass CTest native COR checks,
and retain the exact semantic checksum 1348047471 before
timing results are considered valid.

Each A/B pair alternates native baseline/candidate execution
order over three rounds. Each sample contains 50000 warm-ups,
then five repetitions of 500000 measured COR API calls.
Java 17 runs the same input stream as a control.
To qualify for promotion, the candidate must outperform
the same-runner baseline by at least 5 percent in EVERY
one of the three paired trials. Known-unsafe API-shadow
variants cannot qualify even when apparently faster.

## 3. Measured upstream Pentagonal XOR results

CI: https://github.com/Simply-Well-Executed/pentagonal-xor-cpp20/actions/runs/43992940760

Numbers are median nanoseconds per COR API operation.
Each cell lists matched baseline / candidate.

| Variant | Trial 1 | Trial 2 | Trial 3 | Promotion |
| --- | --- | --- | --- | --- |
| safe_header | 111.9536 / 111.7874 | 111.8888 / 112.7230 | 111.8126 / 111.9828 | No |
| full_header | 111.9580 / 112.2472 | 111.4396 / 111.9862 | 111.7650 / 111.6140 | No, unsafe |
| ltcg | 112.2834 / 105.6638 | 112.6932 / 105.6134 | 112.1692 / 105.2926 | YES |
| safe_header_ltcg | 113.0972 / 105.2612 | 112.5240 / 105.5844 | 112.2040 / 105.1592 | Better than baseline, no material added header gain |

Pure LTCG achieved approximately 5.9 to 6.3 percent lower latency
in every trial on this runner.

## 4. Measured downstream Faster Whisper results

CI: https://github.com/pcheek1991/faster-whisper-4d-abandonedware-uniunlicensd/actions/runs/43992947429

| Variant | Trial 1 | Trial 2 | Trial 3 | Promotion |
| --- | --- | --- | --- | --- |
| safe_header | 70.9732 / 70.6578 | 71.1004 / 70.3858 | 70.7190 / 70.4026 | No |
| full_header | 71.1800 / 70.2076 | 72.0958 / 72.4848 | 70.6716 / 70.8436 | No, unsafe |
| ltcg | 73.2754 / 65.2824 | 70.4296 / 65.3772 | 72.2542 / 67.2338 | YES |
| safe_header_ltcg | 70.7436 / 65.4082 | 71.0986 / 65.2818 | 71.1112 / 66.8914 | Better than baseline, no material added header gain |

Pure LTCG achieved approximately 7 to 11 percent lower latency
in every trial on this runner.

## 5. Promoted Windows native Release behavior

Both CMake projects now enable INTERPROCEDURAL_OPTIMIZATION_RELEASE
for the native pentagonal_ligaze executable, producing MSVC /GL
object compilation and /LTCG link optimization in Release builds.

The native pentagonal_ligaze_benchmark target defaults to the
Windows variant named promoted, which also enables the same IPO
in Release. The baseline variant explicitly stays unoptimized
with respect to IPO so future A/B trials have a genuine baseline.

The safe_header and full_header variants remain opt-in experiments.
The requested WinAPI shadows are never enabled by default.
The exact Java 17 benchmark remains untouched and operates as
an independent behavior reference. On non-MSVC platforms the
promoted label does not alter Clang/GCC optimization flags.

Scope: the improvement is proven for the tested COR workload,
not every module in either repository or every Windows CPU.
No silent changes to the original canonical XOR source,
submodule gitlink, 64-bit COR semantics or GAMP requirements.

## 6. Reproduction and future audit

From a Windows developer terminal with PowerShell 7, CMake,
MSVC and JDK 17:

    pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File ci/Invoke-LigazeWindowsAB.ps1 -Iterations 500000 -Warmup 50000 -Repeats 5 -Trials 3

Standard native Release compilation:

    cmake -S . -B build-windows-release -DBUILD_TESTING=ON
    cmake --build build-windows-release --config Release --target pentagonal_ligaze pentagonal_ligaze_benchmark
    ctest --test-dir build-windows-release -C Release -R ligaze --output-on-failure

Evidence retains per-variant build logs, trial medians,
sample order, native/Java checksum parity and the source SHA.
Earlier CI command-construction failure is retained as a
historical failed run; no raw data is overwritten.
Do not extrapolate timing across differing GitHub runner CPUs.

## 7. Primary technical references

Microsoft MSVC Release /O2 defaults:
https://learn.microsoft.com/en-us/cpp/build/reference/o1-o2-minimize-size-maximize-speed

Microsoft whole-program /GL /LTCG guidance:
https://learn.microsoft.com/en-us/cpp/build/optimization-best-practices

Microsoft Windows header settings:
https://learn.microsoft.com/en-us/windows/win32/winprog/using-the-windows-headers

Microsoft STRICT:
https://learn.microsoft.com/en-us/windows/win32/winprog/enabling-strict

Conclusion: preserve the user's proposed full header as
frozen experimental evidence, reject no-op Win32 stubs
from production, and apply only the independently
measured and semantics-preserving native LTCG improvement.
