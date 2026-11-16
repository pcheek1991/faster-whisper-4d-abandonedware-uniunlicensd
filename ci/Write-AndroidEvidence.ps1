# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Native NDK C++20 APK evidence, fail-closed and truthful on partial builds.
[CmdletBinding()]
param([string]$EvidenceDir = 'evidence-android')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$evidence=[IO.Path]::GetFullPath((Join-Path $root $EvidenceDir))
[void][IO.Directory]::CreateDirectory($evidence)
$apkDir=Join-Path $root 'android/app/build/outputs/apk/debug'
$apks=@(Get-ChildItem -LiteralPath $apkDir -Filter '*.apk' -File -ErrorAction SilentlyContinue)
$nativeRecordFile=Join-Path $evidence 'native-apk-record.json'
$record=$null
if(Test-Path -LiteralPath $nativeRecordFile -PathType Leaf){
  $record=Get-Content -LiteralPath $nativeRecordFile -Raw | ConvertFrom-Json
}
$files=@(foreach($apk in $apks){
  [ordered]@{
    file=$apk.Name
    bytes=$apk.Length
    sha256=(Get-FileHash -LiteralPath $apk.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
  }
})
$verified=($apks.Count -eq 1 -and $null -ne $record -and
  $record.schema -ceq 'SWE-DIAMOND-Android-native-debug-v1' -and
  $record.sha256 -ceq $files[0].sha256 -and
  $record.production_signed -eq $false -and
  (Test-Path -LiteralPath (Join-Path $evidence 'verify-signature.log') -PathType Leaf) -and
  (Test-Path -LiteralPath (Join-Path $evidence 'verify-manifest.log') -PathType Leaf))
$manifest=[ordered]@{
  schema='SWE-DIAMOND-Android-native-evidence-v2'
  created_utc=(Get-Date).ToUniversalTime().ToString('o')
  repository_commit=$env:GITHUB_SHA
  github_run=$env:GITHUB_RUN_ID
  github_attempt=$env:GITHUB_RUN_ATTEMPT
  os_runner=$env:RUNNER_OS
  source_commit='fb23b40480476c98e992762ace37761b6fd8ba0e'
  toolchain='Android SDK 35, build tools 35.0.0, NDK 27.2.12479018'
  native_abi='arm64-v8a'
  apk_built=($apks.Count -gt 0)
  native_debug_apk_verified=$verified
  debug_signature=if($verified){'verified_ephemeral_debug'}else{'unverified_or_not_built'}
  production_signed=$false
  android_device_tested=$false
  emulator_tested=$false
  full_legacy_ui_parity=$false
  apk_files=$files
}
$manifest | ConvertTo-Json -Depth 6 |
  Set-Content -LiteralPath (Join-Path $evidence 'manifest.json') -Encoding utf8
$sumPath=Join-Path $evidence 'SHA256SUMS'
$lines=[Collections.Generic.List[string]]::new()
Get-ChildItem -LiteralPath $evidence -File -Recurse |
  Where-Object { $_.FullName -ne $sumPath } |
  Sort-Object FullName | ForEach-Object {
    $relative=[IO.Path]::GetRelativePath($evidence,$_.FullName).Replace('\','/')
    $hash=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $lines.Add(('{0}  {1}' -f $hash,$relative))
  }
$lines | Set-Content -LiteralPath $sumPath -Encoding utf8
Write-Host ('Native Android evidence: built={0}, debug verified={1}, members={2}' -f
  ($apks.Count -gt 0),$verified,$lines.Count)
if(!$verified){Write-Warning 'Native debug package is not validated; do not claim a successful APK.'}
exit 0
