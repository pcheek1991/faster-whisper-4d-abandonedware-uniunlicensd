# Android · Fastest-Whisper-10D experimental debug APK

This is an **experimental, offline Android APK**. It computes the same
nine-ligand, three-interlocked-Pentagonal-XOR Stability protocol as
the PowerShell 7 implementation: [Stability specification](STABILITY.md).

## What the APK actually does

The app opens a user-selected local raw stereo IEEE-754 float32 little-endian
file using Android's Storage Access Framework. It does **not** request
network, microphone or broad storage permissions. It streams the input
rather than holding recordings in memory; it computes:

- Nine source-derived acoustic measurements in fixed order;
- The same nine normalization rules as PowerShell;
- Three five-input odd-parity scores using the same cyclic overlap topology;
- Three 16-bit nearest-half-up quantized words, serialized as an
  exact six-byte little-endian **hexabyte**;
- The tenth scalar dimension **Stability**, equal to one minus the
  difference between the maximum and minimum of the three ring scores;
- SHA-256 of the input file bytes.

The outputs are displayed locally. Nothing is transmitted to a server.
This does **not** convert arbitrary MP3, WAV or other container formats
in the Android app. The picker accepts any file for convenience, but the
selected file must contain **raw** stereo float32-le data and will fail
on an invalid frame length or nonfinite float sample.

## What it does not do

The APK has **no trained weights, tokenizer, model loader, remote
request, speech recognition or transcript generation**. Stability is
a deterministic ring-agreement score, not a measure of audio quality
or independently verified speaker/text reliability.

## Reproducible build

The code lives under `android/` and uses Java 17, Android Gradle
Plugin 8.9.2, Gradle 8.11.1, compileSdk 35, targetSdk 35 and minSdk 26.
The CI workflow pins its GitHub Actions setup actions to commit SHAs.
It executes pure Java unit tests for known-answer hexabytes, input
validation, and an independent odd-minterm check before creating the APK.

Example local build if Android SDK, JDK 17 and Gradle 8.11.1 exist:

```powershell
gradle -p android --no-daemon :app:testDebugUnitTest :app:lintDebug :app:assembleDebug
```

Successful output: `android/app/build/outputs/apk/debug/app-debug.apk`.

CI: [Android bleeding APK workflow](../.github/workflows/android-bleeding.yml).

## Evidence and signing

On each run, the pipeline retains Android build/test logs, JUnit results,
SHA-256 of produced APK bytes, and a manifest with checkout/run IDs.
Failure logs are kept even if no APK exists. The GitHub Actions artifact
wrapper is separate from the archived APK SHA-256 fingerprint.

**Debug APK only.** Its automatically generated debug signing key is
not a maintained release-signing identity. Do not represent this as a
production-signed Play Store release. No APK or artifact digest is
claimed until an actual GitHub Actions job produces it.

All *new* original Java application code is marked 0BSD. Upstream
MIT-licensed source and the bundled DUNGU-derived converter retain their
separate provenance and redistribution review; the APK does not bundle
those sources or any pretrained weights.

The checksum establishes binary integrity relative to a recorded
value. It is not an independent certificate of publisher identity.
