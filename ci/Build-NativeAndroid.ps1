# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Direct pinned Android SDK/NDK debug APK build, without build middleware.
[CmdletBinding()]
param(
    [string]$SdkRoot = $env:ANDROID_HOME,
    [string]$NdkVersion = '27.2.12479018',
    [string]$BuildToolsVersion = '35.0.0',
    [string]$EvidenceDir = 'evidence-android'
)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($SdkRoot)){throw 'ANDROID_HOME is missing.'}
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$ndk=Join-Path $SdkRoot "ndk/$NdkVersion"
$toolsRoot=Join-Path $SdkRoot "build-tools/$BuildToolsVersion"
$platform=Join-Path $SdkRoot 'platforms/android-35/android.jar'
$chain=Join-Path $ndk 'build/cmake/android.toolchain.cmake'
foreach($file in @($chain,$platform,(Join-Path $toolsRoot 'aapt2'),
    (Join-Path $toolsRoot 'aapt'),(Join-Path $toolsRoot 'zipalign'),
    (Join-Path $toolsRoot 'apksigner'))){
    if(!(Test-Path -LiteralPath $file -PathType Leaf)){
        throw "Pinned Android platform tool missing: $file"
    }
}
$evidence=Join-Path $root $EvidenceDir
[void][IO.Directory]::CreateDirectory($evidence)
$build=Join-Path $root 'build-android'
$manifest=Join-Path $root 'android/app/src/main/AndroidManifest.xml'
$apkDir=Join-Path $root 'android/app/build/outputs/apk/debug'
[void][IO.Directory]::CreateDirectory($apkDir)
function Step([string]$name,[string]$cmd,[string[]]$argv){
    & $cmd @argv *>&1 | Tee-Object -FilePath (Join-Path $evidence "$name.log")
    if($LASTEXITCODE -ne 0){throw "$name failed with exit $LASTEXITCODE"}
}
Step 'cmake-configure' 'cmake' @('-S',$root,'-B',$build,
    "-DCMAKE_TOOLCHAIN_FILE=$chain",'-DANDROID_ABI=arm64-v8a',
    '-DANDROID_PLATFORM=android-26','-DANDROID_STL=c++_static',
    '-DBUILD_TESTING=OFF','-DCMAKE_BUILD_TYPE=Release')
Step 'cmake-ndk' 'cmake' @('--build',$build,'--target','diamond_android','--config','Release','--parallel','2')
$library=Join-Path $build 'libdiamond_android.so'
if(!(Test-Path -LiteralPath $library -PathType Leaf)){
    throw 'NDK did not produce the native activity library.'
}
$aapt2=Join-Path $toolsRoot 'aapt2'
$aapt=Join-Path $toolsRoot 'aapt'
$zipalign=Join-Path $toolsRoot 'zipalign'
$apksigner=Join-Path $toolsRoot 'apksigner'
$staging=Join-Path $build 'apk-stage'
$libFolder=Join-Path $staging 'lib/arm64-v8a'
[void][IO.Directory]::CreateDirectory($libFolder)
Copy-Item -LiteralPath $library -Destination (Join-Path $libFolder 'libdiamond_android.so') -Force
$unsigned=Join-Path $build 'diamond-unsigned.apk'
$aligned=Join-Path $build 'diamond-aligned.apk'
$final=Join-Path $apkDir 'diamond-native-arm64-debug.apk'
Step 'aapt2-manifest' $aapt2 @('link','-o',$unsigned,'-I',$platform,
    '--manifest',$manifest,'--min-sdk-version','26','--target-sdk-version','35')
Push-Location $staging
try{
    Step 'aapt-library' $aapt @('add',$unsigned,'lib/arm64-v8a/libdiamond_android.so')
}finally{Pop-Location}
Step 'zipalign' $zipalign @('-f','-p','4',$unsigned,$aligned)
# A fresh non-exported one-day debug key. Never reuse this for a release.
$key=Join-Path $build 'diamond-ci-debug.keystore'
$keytoolArgs=@('-genkeypair','-alias','androiddebugkey','-keyalg','RSA',
    '-keysize','2048','-validity','1','-keystore',$key,
    '-storepass','android','-keypass','android',
    '-dname','CN=Diamond CI Debug,O=Simply Well Executed,C=US','-noprompt')
& keytool @keytoolArgs *>&1 | Tee-Object -FilePath (Join-Path $evidence 'debug-signing.log')
if($LASTEXITCODE -ne 0){throw 'Ephemeral signing-key creation failed.'}
Step 'sign-debug' $apksigner @('sign','--ks',$key,'--ks-key-alias','androiddebugkey',
    '--ks-pass','pass:android','--key-pass','pass:android','--out',$final,$aligned)
Step 'verify-signature' $apksigner @('verify','--verbose',$final)
Step 'verify-manifest' $aapt @('dump','badging',$final)
$hash=(Get-FileHash -LiteralPath $final -Algorithm SHA256).Hash.ToLowerInvariant()
$record=[ordered]@{
    schema='SWE-DIAMOND-Android-native-debug-v1'
    source_commit='fb23b40480476c98e992762ace37761b6fd8ba0e'
    abi='arm64-v8a'; ndk=$NdkVersion; build_tools=$BuildToolsVersion
    apk_file=$final; sha256=$hash
    signature='ephemeral-debug-only'; production_signed=$false
    cxx_runtime='NDK c++_static'
    validation='host CTest and debug APK signature/manifest; no device claim'
}
$record | ConvertTo-Json -Depth 5 |
    Set-Content -LiteralPath (Join-Path $evidence 'native-apk-record.json') -Encoding utf8
Write-Host "Native Android debug APK succeeded, SHA256 $hash"
exit 0
