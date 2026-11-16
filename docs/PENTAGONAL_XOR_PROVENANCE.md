# Pentagonal XOR canonical integration and custody

**Original repository**: https://github.com/Simply-Well-Executed/pentagonal-xor-cpp20

**Pinned immutable source commit**: `fb23b40480476c98e992762ace37761b6fd8ba0e`

**Carrier**: `external/pentagonal-xor-cpp20` is a Git submodule, not a rewrite or renamed fork. Run `git submodule update --init --recursive`.

**Target**: https://github.com/pcheek1991/faster-whisper-4d-abandonedware-uniunlicensd/pull/17

## Provenance and source-of-truth

The target's new root CMakeLists.txt builds the **verbatim upstream** C++20 project and the upstream strict-C11/shared metadata guard, including the upstream test suites. `integration/pentagonal_xor_adapter.cpp` is an I/O adapter. It delegates to the original exported `swe_pxor_xor_parity_arr`, `swe::stability10d::calculate`, and `swe::stability10d::from_measurements` functions. No duplicate algorithm is introduced in the adapter. Every submodule file comes from the exact source revision, and changing that revision requires review.

The full pinned source revision includes the original five-input XOR (16 parity minterms as reference), AND/OR/partial/fifth-root scoring, std-free C11 entry point and OS-target macros, DecaSigma, TriPi, scalar COREAO, idealized RF +9 dBi COREAO gain, counterarccosine second-wave tests, Stability-10D and its six-byte hex witness, reversible stereo COREO, metadata trust guard, CMake installation, offline Android source-study components, Docker definitions, PowerShell validation infrastructure and their documentation and tests. The CI tests the executable C++/C11 operator coverage and invokes existing target PowerShell synthetic contracts. Running the operator suite is not a claim of Android device execution or trained ASR.

**Bidirectional credit**: Upstream `docs/STABILITY10D.md` expressly credits this PR #17 as the source of its experimental Stability-10D and stereo COREO port. Reimporting those headers from upstream does **not** change the historical origin of the protocol. Earlier compatibility scripts in `ci/Stability.ps1` and Android Java remain separate preexisting language ports, not falsely represented as original upstream code. Canonical parity belongs to the pinned C/C++ header and source.

## Validation and rights boundary

Each Shared Guard run must check the Git gitlink and submodule checkout SHA match the pinned commit, then retain hashes, build logs and test results. The native matrix covers Windows, macOS and Linux; the Linux Docker lane may invoke the unchanged pinned upstream container guards. Existing Android SDK CI continues independently. The published SDK-free Docker image cannot be used for NDK cross-compilation merely by setting an environment variable.

Upstream project-owned source is 0BSD. The inherited faster-whisper repository also contains upstream MIT components; neither license overrides third-party Android SDK, OS, compiler, Docker layer or model licenses. Packaging must remain clearly labeled *weight-free numerical analysis and provenance tooling*, **not speech-to-text** or a signed production Android release. Docker Hub publication and external uploads are not authorized by Shared Guard validation alone. Deployment is tag-gated, checks code and tests again, and releases only the explicitly packaged numerical module.

No source history or evidence failure is deleted or reclassified as success.

The release package installs the original upstream executable, the original C11/C++20 headers, the original `swe_guard` binary, the thin adapter, original documentation, and a full version-pinned source snapshot (excluding Git administrative data). Upstream Android SDK, Docker image layers, and third-party binaries are never silently bundled under the project's 0BSD license.


## Executable original features, not just copied source

PR #17's `integration/pentagonal_xor_adapter.cpp` now exposes the original upstream APIs directly as JSON-producing CLI modes. No gain, XOR, stereo, route, normalization, or root algorithms are redefined in this target code.

| CLI mode | Verbatim original source function | Scope |
| --- | --- | --- |
| `parity h0 h1 h2 h3 h4` | `swe_pxor_xor_parity_arr` | Five-input closed-form odd parity |
| `scores h0 h1 h2 h3 h4` | `swe_pxor_scores5` | AND, OR, XOR, partial and legacy fifth-root |
| `fifth-root value` | `swe_pxor_fifth_root` | Signed finite-input mathematical fifth root |
| `ligands h0 ... h8` | `swe::stability10d::calculate` | Three rings, Stability, six-byte witness |
| `measurements N meanL meanR rmsL rmsR peakL peakR crossingsL crossingsR` | `swe::stability10d::from_measurements` | Original normalization + Stability |
| `deca-sigma x` | `swe::deca_sigma::run`, `witnesses_return` | Ten chronological operations, 11 retained states |
| `tri-pi x` | `swe::tri_pi::inspect` | Forward, reverse, Z-fold witnesses |
| `coreao x` | `swe::coreao::inspect` | Read-only scalar residual |
| **`gain9dbi watts`** | **`swe::coreao::rf_gain::apply`** | **Idealized directional RF EIRP from conducted watts at +9 dBi** |
| `coreo-stereo L0 R0 [L1 R1 ...]` | `swe::coreo_stereo::forward_at`, `reverse_at`, `inspect` | Immutable source, reversible quad, read-only Z-fold audit |
| `platform` | `SWE_PXOR_TARGET_*` and legacy compile-target macros | Build target flags, not host OS detection |

The *original* five-channel metadata trust guard remains executable separately as the upstream `swe_guard` installed binary with original CTest coverage of 32 parity states, trusted/untrusted origin and traversal. The research counterarccosine second wave remains in original source/test artifacts, rather than invented as a new public runtime API. Source and tests for the original Android/containers/workflows remain in the pinned submodule and packaged snapshot, with separate Android CI. This interface makes every existing **public computation family** callable while preserving domain-specific separation.

### +9 dBi RF/EIRP golden witness

```powershell
./build-pxor/fastest_whisper_pxor_adapter gain9dbi 1
```

The originating `shared/coreao_gain.hpp` returns `gain_dbi=9`, `gain_linear=7.943282347242816`, `output_eirp_watts=7.943282347242816` for `input_watts=1` and a recovered input of 1. The result is an idealized **equivalent isotropic radiated power in a reference direction** under explicit no-loss assumptions. It is not actual total radiated power or an antenna measurement. **It does not amplify audio, change Whisper inference, imply a +9 dB digital signal multiplier, or produce a transcript.** Negative, nonfinite and overflow power inputs fail closed.

Shared Guard invokes `ci/Test-CanonicalFeatureSurface.ps1` across its Windows/Linux/macOS native matrix and executes all upstream CTest tests. The PowerShell test compares the +9 dBi gain, power factor, field factor, recovered input, zero, negative and overflow guard with the original API. It also tests every other bridge mode and COREO inverse. The package dry-run exercises the same gates before release and checks the installed original binaries.


## Default-on PowerShell pipeline and adjustable dBi gain

The simpler CLI is `Invoke-PentagonalPipeline.ps1`. It **runs every applicable public upstream operator automatically**. With no supplied source measurements, it executes original algorithms on *explicitly marked synthetic reference fixtures* rather than inventing microphone readings, RF wattage, or security authorization. It always runs the upstream metadata guard self-test; **actual metadata approval still requires an explicit record**.

```powershell
# No switches: all operator families execute; reference fixture markers are mandatory.
./Invoke-PentagonalPipeline.ps1

# RF gain is +9 dBi by default. Override to +11 dBi without selecting a mode.
./Invoke-PentagonalPipeline.ps1 -Watts 1 -GainDbi 11

# PowerShell object piping, with record-level gain winning over CLI default:
@{ watts = 1; gain_dbi = 11; deca_input = 2;
   features = @(0.8,0.7,0.9,0.6,0.95);
   stereo = @(1,-2,3,-4) } | ./Invoke-PentagonalPipeline.ps1

# A one-number pipe also means "override gain_dbi".
11 | ./Invoke-PentagonalPipeline.ps1 -Watts 1

# Native C++ CLI accepts a piped dBi scalar after '-' (dash marks stdin).
'11' | ./build-pxor/fastest_whisper_pxor_adapter gain 1 '-'
```

For multiline JSONL, pipe a line-per-record input into the PowerShell script; each JSON object produces one JSON output record. Input schema supports `watts`, `gain_dbi`, `features` (five), `ligands` (nine), `measurements` (nine original CORE values), `deca_input`, `fifth_root_input`, `stereo` (ordered L/R float32 frame pairs), `raw_stereo_float32_path`, and `metadata` with `url,path,sha256,artifact`. Explicit numeric inputs must be finite and within the original domain; contradictory input sources fail rather than silently picking one. Per-record `gain_dbi` overrides explicit `-GainDbi` which overrides the **+9 dBi default**.

**Provenance boundary**: +9 dBi runs the **verbatim** `swe::coreao::rf_gain::apply` function at pinned SHA `fb23b40480476c98e992762ace37761b6fd8ba0e`. A request for +11 dBi applies the separately labeled `downstream-rf-dbi-offset-v1` extension to its original output: `P(+11)=P(+9)*10^((11-9)/10)`. One conducted watt therefore yields approximately `12.589254 W` idealized EIRP. This extension is **not claimed as part of the original fixed +9 dBi header** and does not amplify audio or modify Whisper inference. It respects the upstream fail-closed watts domain and adds finite gain/output/roundtrip checks. Valid gain range: `[-100,+100] dBi`.

The original counterarccosine second wave remains a documented, executable **upstream CTest research witness**, not an invented production runtime API. The original five-channel trust guard remains the authoritative security decision, not a parity proxy. The entire pinned original source tree is installed alongside the standalone CLI. CI runs both upstream tests and `ci/Test-DefaultOnPipeline.ps1` across all native targets and executes the **installed CLI inside the unsigned numerical ZIP dry-run**.


### Exploratory second-wave execution (verbatim)

The default-on pipeline also **executes the original upstream** `counterarccosine_secondwave_test` binary on each record, including its 257 phase-complement witnesses and source +9 dBi synthetic RF reference checks. It is now installed inside the numerical release ZIP and identified as `results.counterarccosine_second_wave.status=passed_original_experimental_test`. This does **not** invent a public parameterized second-wave waveform API, claim an RF measurement, or reinterpret the original experiment as speech recognition.
