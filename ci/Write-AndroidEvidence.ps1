# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Android Checkpoint 10: preserve compiler/test/APK SHA256 evidence on failures.
[CmdletBinding()]
param([string]$EvidenceDir = 'evidence-android')

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$evidence = [IO.Path]::GetFullPath((Join-Path $root $EvidenceDir))
[void][IO.Directory]::CreateDirectory($evidence)

$apkDir = Join-Path $root 'android/app/build/outputs/apk/debug'
$apks = @(Get-ChildItem -LiteralPath $apkDir -Filter '*.apk' -File -ErrorAction SilentlyContinue)
$manifest = [ordered]@{
    schema = 'Fastest-Whisper-10D-Android-evidence-v1'
    generated_utc = (Get-Date).ToUniversalTime().ToString('o')
    github_sha = $env:GITHUB_SHA
    github_run = $env:GITHUB_RUN_ID
    github_attempt = $env:GITHUB_RUN_ATTEMPT
    runner = $env:RUNNER_OS
    protocol = 'Stability-9L3PX5-U16LE-v1'
    offline_and_weight_free = $true
    debug_signing = $true
    release_signing = $false
    apk_built = ($apks.Count -gt 0)
    apk_sha256 = @(
        foreach ($apk in $apks) {
            [ordered]@{
                file = $apk.Name
                size = $apk.Length
                sha256 = (Get-FileHash -LiteralPath $apk.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            }
        }
    )
}
$manifest | ConvertTo-Json -Depth 6 |
    Set-Content -LiteralPath (Join-Path $evidence 'manifest.json') -Encoding utf8

$testRoot = Join-Path $root 'android/app/build/test-results/testDebugUnitTest'
if (Test-Path -LiteralPath $testRoot -PathType Container) {
    $destination = Join-Path $evidence 'junit'
    [void][IO.Directory]::CreateDirectory($destination)
    Get-ChildItem -LiteralPath $testRoot -File -Filter '*.xml' |
        Copy-Item -Destination $destination
}
$sumPath = Join-Path $evidence 'SHA256SUMS'
$lines = [Collections.Generic.List[string]]::new()
Get-ChildItem -LiteralPath $evidence -File -Recurse |
    Where-Object { $_.FullName -ne $sumPath } |
    Sort-Object FullName | ForEach-Object {
        $relative = [IO.Path]::GetRelativePath($evidence, $_.FullName).Replace('\', '/')
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $lines.Add(('{0}  {1}' -f $hash, $relative))
    }
$lines | Set-Content -LiteralPath $sumPath -Encoding utf8
Write-Output ('Android evidence: {0} APK(s), {1} SHA256 members.' -f $apks.Count,$lines.Count)
if ($apks.Count -eq 0) {
    Write-Warning 'No APK produced. Preserve build failure logs without claiming success.'
}
