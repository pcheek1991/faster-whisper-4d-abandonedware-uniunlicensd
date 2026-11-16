# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Run canonical upstream test suites without modifying upstream algorithms.
[CmdletBinding()]
param(
  [ValidateSet('Test','Package')][string]$Mode = 'Test',
  [string]$VsArch = '',
  [string]$BuildDir = 'build-pxor',
  [string]$EvidenceDir = 'evidence-pxor'
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$upstreamPath = 'external/pentagonal-xor-cpp20'
$upstream = Join-Path $root $upstreamPath
$expectedSha = 'fb23b40480476c98e992762ace37761b6fd8ba0e'
$build = Join-Path $root $BuildDir
$evidence = Join-Path $root $EvidenceDir
[void][IO.Directory]::CreateDirectory($evidence)
$events = [Collections.Generic.List[object]]::new()
$record = [ordered]@{
  schema = 'FastestWhisper10D-Canonical-PXOR-SharedGuard-v1'
  utc = (Get-Date).ToUniversalTime().ToString('o')
  target_commit = $env:GITHUB_SHA
  upstream_repository = 'https://github.com/Simply-Well-Executed/pentagonal-xor-cpp20'
  source_commit_expected = $expectedSha
  source_commit_observed = $null
  original_algorithms_modified = $false
  build_mode = $Mode
  stages = @()
  passed = $false
  error = $null
}
function Invoke-Gate {
  param([string]$Name,[string]$Executable,[string[]]$Arguments)
  Write-Host "Shared Guard stage: $Name"
  $log = Join-Path $evidence ($Name + '.log')
  & $Executable @Arguments *>&1 | Tee-Object -FilePath $log
  $code = [int]$LASTEXITCODE
  $events.Add([ordered]@{stage=$Name;exit_code=$code;passed=($code -eq 0);log=([IO.Path]::GetFileName($log))})
  if ($code -ne 0) { throw "Shared Guard $Name failed (exit $code); inspect $log." }
}
try {
  $item = ((& git -C $root ls-tree HEAD -- $upstreamPath) | Out-String).Trim()
  if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect upstream gitlink.' }
  $match = [regex]::Match($item, '^160000 commit ([a-f0-9]{40})\s+external/pentagonal-xor-cpp20$')
  if (!$match.Success -or $match.Groups[1].Value -cne $expectedSha) {
    throw "Unreviewed upstream gitlink revision: $item"
  }
  if (!(Test-Path -LiteralPath (Join-Path $upstream 'shared/pentagonal_xor_std_free.h') -PathType Leaf)) {
    throw 'Canonical source is not checked out. Run git submodule update --init --recursive.'
  }
  $actual = ((& git -C $upstream rev-parse HEAD) | Out-String).Trim()
  if ($LASTEXITCODE -ne 0 -or $actual -cne $expectedSha) {
    throw "Canonical source commit mismatch: expected $expectedSha, observed $actual"
  }
  $record.source_commit_observed = $actual
  $url = ((& git -C $root config -f .gitmodules --get submodule.external/pentagonal-xor-cpp20.url) | Out-String).Trim()
  if ($LASTEXITCODE -ne 0 -or $url -cne 'https://github.com/Simply-Well-Executed/pentagonal-xor-cpp20.git') {
    throw "Unexpected upstream source remote: $url"
  }
  $dirty = @(& git -C $upstream status --porcelain --untracked-files=no)
  if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) { throw 'Upstream tracked files are modified; no verbatim provenance.' }

  # Hash all original tracked files, not only the selected headers.
  $paths = @(& git -C $upstream ls-files)
  if ($LASTEXITCODE -ne 0 -or $paths.Count -lt 20) { throw 'Upstream tracked source inventory unavailable.' }
  $hashes = foreach ($path in ($paths | Sort-Object)) {
    $file = Join-Path $upstream $path
    if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing upstream tracked file: $path" }
    '{0}  {1}' -f (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant(),$path
  }
  $hashes | Set-Content -LiteralPath (Join-Path $evidence 'upstream-source-sha256.txt') -Encoding utf8
  $record.upstream_tracked_files = @($paths).Count
  Write-Host "Canonical source verified: $actual ($($record.upstream_tracked_files) tracked files)"

  $configure = @('-S',$root,'-B',$build,'-DBUILD_TESTING=ON')
  if ($IsWindows) {
    if ([string]::IsNullOrWhiteSpace($VsArch)) { $VsArch = 'x64' }
    if ($VsArch -notin @('x64','Win32','ARM64')) { throw "Unsupported Windows CMake architecture $VsArch" }
    $configure += @('-A',$VsArch)
  } else {
    $configure += '-DCMAKE_BUILD_TYPE=Release'
  }
  Invoke-Gate 'cmake-configure' 'cmake' $configure
  Invoke-Gate 'cmake-build' 'cmake' @('--build',$build,'--config','Release','--parallel','2')
  Invoke-Gate 'canonical-full-and-shared-ctest' 'ctest' @('--test-dir',$build,'-C','Release','--output-on-failure','--output-junit',(Join-Path $evidence 'ctest-results.xml'))
  Invoke-Gate 'canonical-bridge-vs-powershell' 'pwsh' @('-NoLogo','-NoProfile','-File',(Join-Path $PSScriptRoot 'Test-CanonicalPentagonalBridge.ps1'),'-BuildDir',$BuildDir)
  Invoke-Gate 'original-coreo-contract' 'pwsh' @('-NoLogo','-NoProfile','-File',(Join-Path $PSScriptRoot 'Test-CoreoContract.ps1'))
  Invoke-Gate 'original-stability-contract' 'pwsh' @('-NoLogo','-NoProfile','-File',(Join-Path $PSScriptRoot 'Test-Stability.ps1'))
  Invoke-Gate 'original-ten-dimensional-contract' 'pwsh' @('-NoLogo','-NoProfile','-File',(Join-Path $PSScriptRoot 'Test-10D.ps1'))
  Invoke-Gate 'source-release-safety' 'pwsh' @('-NoLogo','-NoProfile','-File',(Join-Path $upstream 'ci/Test-ReleaseSafety.ps1'))

  if ($Mode -eq 'Package') {
    $stage = Join-Path $root 'dist-pxor/stage'
    [void][IO.Directory]::CreateDirectory($stage)
    Invoke-Gate 'cmake-install' 'cmake' @('--install',$build,'--config','Release','--prefix',$stage)
    $dist = Join-Path $root 'dist-pxor'
    $asset = Join-Path $dist 'fastest-whisper-10d-pentagonal-xor-linux-x64.zip'
    if (!$IsLinux -or $env:RUNNER_ARCH -ne 'X64') {
      throw 'Validated release packaging is currently restricted to Linux x64.'
    }
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $asset -CompressionLevel Optimal -Force
    $assetSha = (Get-FileHash -LiteralPath $asset -Algorithm SHA256).Hash.ToLowerInvariant()
    ('{0}  {1}' -f $assetSha, [IO.Path]::GetFileName($asset)) |
      Set-Content -LiteralPath (Join-Path $dist 'SHA256SUMS') -Encoding utf8
    $record.release_package = [IO.Path]::GetFileName($asset)
    $record.release_sha256 = $assetSha
  }
  $record.passed = $true
} catch {
  $record.error = $_.Exception.Message
  Write-Host "::error title=SharedGuard::$($record.error)"
  throw
} finally {
  $record.stages = @($events.ToArray())
  $record.finished_utc = (Get-Date).ToUniversalTime().ToString('o')
  $record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $evidence 'shared-guard-record.json') -Encoding utf8
  $files = @(Get-ChildItem -LiteralPath $evidence -File | Where-Object Name -ne 'SHA256SUMS' | Sort-Object Name)
  @($files | ForEach-Object {
    '{0}  {1}' -f (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant(),$_.Name
  }) | Set-Content -LiteralPath (Join-Path $evidence 'SHA256SUMS') -Encoding utf8
  Write-Host "Shared Guard evidence: $($files.Count) SHA256 records, PASS=$($record.passed)"
  if ($env:GITHUB_STEP_SUMMARY) {
    Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value (
      "Canonical source SHA: $expectedSha; checked $($record.upstream_tracked_files) files; PASS=$($record.passed); evidence=$EvidenceDir."
    )
  }
}
$global:LASTEXITCODE = 0
exit 0
