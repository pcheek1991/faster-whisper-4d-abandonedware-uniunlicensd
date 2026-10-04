# Software validation baseline

This document records a GAMP 4-oriented software validation approach for this repository. Release
2.0.0 sets Python 3.12 as the minimum so the project can use maintained interpreters and current
runtime dependencies. This is a breaking compatibility change. This document is not a completed
system validation or a claim of GxP, regulatory, or product certification.

<span style="color:#b00020;"><u>RED-UNDERLINED TEXT</u></span> marks claims or compatibility paths
without direct test evidence. Keep these markers until repeatable tests or approved external
qualification provide the missing evidence.

## Scope and intended use

The repository provides a Python speech-to-text library using CTranslate2, PyAV, Hugging Face Hub
model downloads, optional Silero VAD, and a separate raw-stream Coreo converter invoked through
PowerShell. This baseline covers source changes, package behavior, and the repository's CI checks.
It does not validate a particular deployment, hardware configuration, transcript's suitability for
a regulated decision, or any downstream system.
The intended use and acceptance criteria for a deployed system must be established by its owner.
Transcript rendering is outside this library's scope; consuming interfaces must preserve Unicode
logical order and handle bidirectional isolation at the rendering boundary.
<span style="color:#b00020;"><u>UNVALIDATED RENDERING:</u></span> This repository has no browser or
native UI test for visual bidi layout and does not implement UTS #39 identifier checks or bidi
sanitization.

## Risk-based traceability

The identifiers below are repository-level verification assertions, not approved user requirements.

| ID | Risk / behavior | Verification evidence |
| --- | --- | --- |
| SV-01 | Model alias resolution and download failures must be explicit. | `tests/test_utils.py`; `tests/test_failure_modes.py::test_hub_download_failure_is_propagated` |
| SV-02 | Invalid or unavailable audio must not produce success-shaped output. | `tests/test_transcribe.py::test_stereo_diarization`; `tests/test_failure_modes.py::test_audio_open_failure_is_propagated` |
| SV-03 | Batched VAD options must respect the encoder chunk limit without changing caller input. | `tests/test_failure_modes.py::test_batched_vad_options_are_bounded_without_mutating_input` |
| SV-04 | In-memory model file mappings must remain reusable by the caller. | `tests/test_failure_modes.py::test_model_files_argument_is_not_mutated` |
| SV-05 | Missing VAD runtime and invalid VAD input must fail explicitly before inference. | `tests/test_failure_modes.py::test_missing_vad_runtime_is_explicit`; `tests/test_failure_modes.py::test_vad_rejects_invalid_audio_before_inference` |
| SV-06 | Transcription content, timestamps, VAD, batching, and clipping retain their tested behavior. | `tests/test_transcribe.py` integration tests |
| SV-07 | Tokenizer decoding preserves bidi controls and joiners returned by its decoder. | `tests/test_failure_modes.py::test_tokenizer_decode_preserves_bidi_controls` |
| SV-08 | Markdown documentation is UTF-8 without a BOM. | `tests/test_failure_modes.py::test_markdown_docs_are_utf8_without_bom` |
| SV-09 | PyAV decodes sample audio without an `ffmpeg` executable on `PATH`. | `tests/test_failure_modes.py::test_audio_decode_does_not_require_ffmpeg_cli` |
| SV-10 | The documented default VAD minimum silence duration is 2000 ms. | `tests/test_failure_modes.py::test_vad_default_minimum_silence_duration` |
| SV-11 | The optional Transformers-to-CTranslate2 conversion entrypoint can convert a small checkpoint. | Manual CPU smoke conversion of `openai/whisper-tiny` with Transformers 5.18.0, Torch 2.14.1, and CTranslate2 4.8.2 |
| SV-12 | Coreo raw-stream conversion preserves its sample mapping and rejects malformed input. | `tests/test_coreo.py` on PowerShell 7.6.6 |

## Verification procedure

Install the development extra and run the checks used by CI:

```bash
python -m pip install -e ".[dev]"
python -m black --check .
python -m isort --check-only .
python -m flake8 .
python -m pytest -q -m "not integration"
python -m pytest -v -m integration
python -m pip install -e ".[security]"
python -m pip_audit -r requirements.txt
python -m pip_audit -r requirements.conversion.txt
python setup.py sdist bdist_wheel
```

Fault-injection tests are deterministic and local: they replace Hub, media-open, or optional-runtime
boundaries with controlled failures. They do not call production services with injected faults,
consume credentials, or perform destructive load testing. Tests marked `integration` exercise
model/audio inference or download weights from Hugging Face; they require outbound access on the
first run.

## Evidence limits and release controls

- <span style="color:#b00020;"><u>NOT RUN REMOTELY:</u></span> GitHub Actions is configured for
  Python 3.12, 3.13, and 3.14 on Ubuntu, but this branch has not completed those remote jobs. Local
  tests used Windows with Python 3.14.5 and CUDA disabled.
- <span style="color:#b00020;"><u>DOCKER BUILD UNVALIDATED:</u></span> The optional Docker example pins
  an NVIDIA CUDA 12.9.1/cuDNN runtime image for Ubuntu 24.04, applies current Ubuntu package updates
  at build time, and uses distro Python 3.12. The tag was checked in the registry, but the image was
  not built because the local Docker daemon is unavailable. CUDA 13 is excluded until CTranslate2
  supports it.
- <span style="color:#b00020;"><u>OS PACKAGES NOT AUDITED:</u></span> `pip-audit` scans Python
  requirements, not the Docker base image's OpenSSL or other operating-system packages.
- <span style="color:#b00020;"><u>COREO CI RUNTIME NOT QUALIFIED:</u></span> Coreo tests skip if
  `pwsh` is unavailable. They passed locally on PowerShell 7.6.6; the GitHub runner's PowerShell
  availability has not been verified.
- CI action references are pinned to immutable commit IDs and use a read-only repository token.
  Dependabot is configured for weekly action, Python dependency, and Docker base-image update PRs;
  each update requires review and the normal verification checks.
- <span style="color:#b00020;"><u>NOT RUN REMOTELY:</u></span> The release build is configured to
  require `pip-audit` scans of runtime and conversion requirements. Local scans found no known
  advisories in either resolved set; scans do not prove dependencies are vulnerability free.
- <span style="color:#b00020;"><u>EXTERNAL BEHAVIOR NOT TESTED:</u></span> Hub aliases can point to
  changed artifacts over time. For reproducible deployments, record the model repository and pass
  a fixed Hub commit hash through the `revision` argument; record the runtime, dependency versions,
  and test outcomes with the release evidence.
- Runtime dependency lower bounds track the current stable release baseline and major-version upper
  bounds limit unreviewed API breaks. CI and Dependabot updates are the controlled path for moving
  that baseline forward. Hugging Face Hub remains below 2 while the latest Tokenizers release
  requires that compatibility range.
- Integration tests use downloaded models and example audio. They do not establish accuracy or
  suitability for a particular population, recording environment, or regulated intended use.
- <span style="color:#b00020;"><u>PARTIALLY VALIDATED:</u></span> The Transformers/Torch conversion
  extra passed a manual `openai/whisper-tiny` CPU smoke test on Python 3.14.5, but is not covered by
  CI or a model/architecture matrix. Benchmark figures, Distil-Whisper compatibility, and the
  community integration list remain unverified.
- The base commit deletes `LICENSE`, while `setup.py` still advertises MIT metadata. A maintainer
  must resolve that inconsistency before distribution; this change does not restore or alter license
  terms.
- A system owner must define intended use, approved requirements, operating environment, acceptance
  criteria, change approval, and any applicable quality-system controls before treating this package
  as part of a regulated computerized system.

For each release, retain the source commit, build artifacts, CI results, resolved dependencies,
model repository/revision, environment details, deviations, and approval records in the applicable
project quality system.
