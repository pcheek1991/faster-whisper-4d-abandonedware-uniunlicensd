# SPDX-License-Identifier: 0BSD
# Supplier-side GAMP 4-style evidence runner. No Python, no Node, no mutation.
[CmdletBinding()]
param(
  [string]$BuildDir = 'build',
  [string]$EvidenceDir = 'evidence-gamp4',
  [string]$ExecutableName = 'pentagonal_gamp4_validation_test'
)
$ErrorActionPreference = 'Stop'
$build = [IO.Path]::GetFullPath($BuildDir)
$dir = [IO.Path]::GetFullPath($EvidenceDir)
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$names = if ($IsWindows) { @("$ExecutableName.exe") } else { @($ExecutableName) }
$candidates = foreach ($name in $names) {
  @(Join-Path $build $name)
  @(Join-Path (Join-Path $build 'Release') $name)
  @(Join-Path (Join-Path $build 'Debug') $name)
}
$exe = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $exe) { throw "Validation executable not found under $build : $ExecutableName" }

$sha = if ($env:GITHUB_SHA) { $env:GITHUB_SHA } else {
  $value = (& git rev-parse HEAD 2>$null | Out-String).Trim()
  if ($LASTEXITCODE -eq 0 -and $value) { $value } else { 'unversioned-local' }
}
$run = if ($env:GITHUB_RUN_ID) { $env:GITHUB_RUN_ID } else { 'local' }
$attempt = if ($env:GITHUB_RUN_ATTEMPT) { $env:GITHUB_RUN_ATTEMPT } else { '1' }
$stem = "$($sha.Substring(0,[Math]::Min(12,$sha.Length)))-$run-$attempt"
$logPath = Join-Path $dir "pentagonal-gamp4-$stem.log"
$evidencePath = Join-Path $dir "pentagonal-gamp4-$stem.json"

# Capture real executable stdout/stderr, exit code and all required URS.
$lines = @(& $exe 2>&1 | ForEach-Object { [string]$_ })
$exit = $LASTEXITCODE
$lines | Set-Content -LiteralPath $logPath -Encoding utf8
$expected = @(11..22 | ForEach-Object { 'URS-{0:d2}' -f $_ })
$observed = @($lines | Where-Object { $_ -match '^PASS\|URS-\d{2}\|' } |
  ForEach-Object { ($_ -split '\|')[1] })
$failed = @($lines | Where-Object { $_ -match '^FAIL\|' })
$passed = $exit -eq 0 -and $failed.Count -eq 0 -and $observed.Count -eq 12 -and
  ($lines -contains 'GAMP4_STYLE_SUMMARY|PASS|cases=12|failures=0')
foreach ($id in $expected) { if (@($observed | Where-Object { $_ -ceq $id }).Count -ne 1) { $passed = $false } }
foreach ($id in $observed) { if ($expected -cnotcontains $id) { $passed = $false } }

$testPath = if (Test-Path -LiteralPath 'tests/pentagonal_gamp4_validation_test.cpp') {
  'tests/pentagonal_gamp4_validation_test.cpp'
} else { 'native/tests/pentagonal_gamp4_validation_test.cpp' }
$headerPath = if (Test-Path -LiteralPath 'shared/pentagonal_gates.hpp') {
  'shared/pentagonal_gates.hpp'
} else { 'native/pentagonal_gates.hpp' }
$hashes = @(
  foreach ($path in @($testPath,$headerPath,'docs/PENTAGONAL_GAMP4_VALIDATION.md')) {
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing validation source: $path" }
    $hash = Get-FileHash -LiteralPath $path -Algorithm SHA256
    [ordered]@{ path=$path; sha256=$hash.Hash.ToLowerInvariant() }
  }
)
$report = [ordered]@{
  schema='SWE-PENTAGONAL-GAMP4-SUPPLIER-VALIDATION-v1'
  regulatory_certification=$false
  source_mutated=$false
  commit=$sha
  github_run=$run
  github_attempt=$attempt
  platform=[Environment]::OSVersion.Platform.ToString()
  dotnet_runtime=[Environment]::Version.ToString()
  executable=$ExecutableName
  executable_sha256=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant()
  test_count=12
  observed_pass_ids=$observed
  rejected_ids=@($failed)
  process_exit=$exit
  pass=[bool]$passed
  source_hashes=$hashes
  text_log=(Split-Path -Leaf $logPath)
  log_sha256=(Get-FileHash -LiteralPath $logPath -Algorithm SHA256).Hash.ToLowerInvariant()
  iq_environment_status='build-record-only'
  oq_automated_status=if($passed){'PASS'}else{'FAIL'}
  pq_status='NOT_PERFORMED'
  qa_approval_status='NOT_APPROVED'
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $evidencePath -Encoding utf8
$lines | ForEach-Object { Write-Host $_ }
Write-Host "GAMP4 evidence: $evidencePath"
if ($env:GITHUB_STEP_SUMMARY) {
  @(
    "### Pentagonal GAMP 4-style supplier verification",
    "",
    "- Commit: $sha",
    "- Requirements: $($observed.Count)/12 PASS entries",
    "- Program exit: $exit",
    "- Automated OQ result: $($report.oq_automated_status)",
    "- IQ/PQ/QA: not fully qualified; no GxP release approval",
    "- Evidence file: $(Split-Path -Leaf $evidencePath)"
  ) | Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Encoding utf8
}
if (-not $passed) { throw 'GAMP4 supplier verification failed. Review retained evidence; do not rewrite source.' }
