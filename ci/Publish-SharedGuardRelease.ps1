# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Trusted-tag-only deployment: a numerical C11/C++20 module, NOT ASR or APK.
[CmdletBinding()]
param()
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$repo = 'pcheek1991/faster-whisper-4d-abandonedware-uniunlicensd'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ($env:GITHUB_REPOSITORY -cne $repo -or $env:GITHUB_EVENT_NAME -cne 'push' -or
    $env:GITHUB_REF -cnotmatch '^refs/tags/v[0-9][A-Za-z0-9._-]*$') {
  throw 'Fail closed: publication permitted only for a trusted v* tag push on the exact repository.'
}
if ([string]::IsNullOrWhiteSpace($env:GH_TOKEN)) { throw 'GH_TOKEN absent: publication disabled.' }
$head = ((& git -C $root rev-parse HEAD) | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $head -cne $env:GITHUB_SHA) {
  throw 'Tagged checkout commit does not match GITHUB_SHA.'
}
& git -C $root fetch --no-tags --depth 1000 origin master
if ($LASTEXITCODE -ne 0) { throw 'Cannot verify master ancestry.' }
& git -C $root merge-base --is-ancestor $head FETCH_HEAD
if ($LASTEXITCODE -ne 0) { throw 'Release tag commit is not an ancestor of master.' }
$tag = $env:GITHUB_REF.Substring('refs/tags/'.Length)
& gh release view $tag --repo $repo *> $null
if ($LASTEXITCODE -eq 0) { throw "Release $tag exists: never overwrite automatically." }

# Repeat ALL gates in this isolated publication job, not just assume another
# matrix runner's results. The corresponding workflow also needs all jobs green.
& (Join-Path $PSScriptRoot 'Invoke-SharedGuard.ps1') -Mode Package
if (!$?) { throw 'Canonical source guard rejected release package.' }
$dist = Join-Path $root 'dist-pxor'
$evidence = Join-Path $root 'evidence-pxor'
$files = @(
  (Join-Path $dist 'diamond-native-linux-x64.zip'),
  (Join-Path $dist 'SHA256SUMS'),
  (Join-Path $evidence 'shared-guard-record.json'),
  (Join-Path $evidence 'upstream-source-sha256.txt')
)
foreach ($file in $files) {
  if (!(Test-Path -LiteralPath $file -PathType Leaf)) {
    throw "Required release evidence missing: $file"
  }
}
$notes = "Weight-free numerical Pentagonal XOR compatibility module, not speech-to-text or a production-signed Android APK. Original C11/C++20 algorithms are an exact Git submodule at fb23b40480476c98e992762ace37761b6fd8ba0e. Source provenance, SHA256 and test records are attached. Linux x64 binary package only; Windows/macOS are CI-qualified separately. Target commit: $head."
& gh release create $tag @files --repo $repo --target $head --title "DIAMOND native C++20 numerical module $tag" --notes $notes --prerelease --latest=false
if ($LASTEXITCODE -ne 0) { throw 'GitHub release API rejected deployment; no success assumed.' }
Write-Host "Published only audited numerical assets for tag $tag."
exit 0
