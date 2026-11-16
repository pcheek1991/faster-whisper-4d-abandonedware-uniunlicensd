# Native Android delivery

The Android component is a direct C++20 NDK NativeActivity, built without an intermediary application-build system. It imports unchanged source for the original numerical operators and the pinned 348-edition Word Bridges language registry. It checks known synthetic inputs at application start and renders a local native diamond canvas. No network, microphone or storage permission is requested.

The executable C++ standard library can be statically linked via ANDROID_STL=c++_static. The Android operating-system ABI libraries are indispensable; a completely unlinked Android application is not technically feasible.

The build script ci/Build-NativeAndroid.ps1 calls the Android SDK/NDK platform tools directly, pinning API 35, build tools 35.0.0, NDK 27.2.12479018 and arm64-v8a. It produces a temporary CI debug-signed APK, verifies the APK signature and manifest, and records a SHA-256 evidence manifest. This is not a production-signed release. Android SDK/NDK packages remain vendor-maintained even though the intermediary build orchestration is removed.

**Important scope:** The earlier local audio-file picker is not yet replaced in the NativeActivity status view. Therefore the APK does not claim complete user-interface parity, transcription, trained speech recognition, device-test coverage, or release deployment. The native desktop DIAMOND executable performs the full weight-free acoustic, math and language-registry operations.
