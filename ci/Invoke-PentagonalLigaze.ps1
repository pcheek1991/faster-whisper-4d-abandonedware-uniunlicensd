# SPDX-License-Identifier: 0BSD
# Native C++20 LIGAZE: preserve five actual CI results in 64-bit COR.
[CmdletBinding()]
param(
  [string]$BuildDir='build-supertaoism',
  [string]$EvidenceDir='evidence-supertaoism'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
function Check([bool]$ok,[string]$description) {
  if (-not $ok) {throw "LIGAZE native evidence failed: $description"}
}
function ReadEvidence([string]$file) {
  $path=Join-Path $EvidenceDir $file
  Check (Test-Path -LiteralPath $path -PathType Leaf) "Missing $file"
  return (Get-Content -LiteralPath $path -Raw|ConvertFrom-Json)
}
function HashFile([string]$file) {
  Check (Test-Path -LiteralPath $file -PathType Leaf) "Missing $file"
  return (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
}
$commit=((& git rev-parse HEAD)|Out-String).Trim()
Check ($LASTEXITCODE -eq 0 -and $commit -match '^[0-9a-f]{40}$') 'No recorded exact commit'
if($env:GITHUB_SHA){Check ($commit -ceq $env:GITHUB_SHA) 'Checked-out commit differs from workflow'}
$yin=ReadEvidence 'yin-run.json'
$yan=ReadEvidence 'yan.json'
$zing=ReadEvidence 'zing.json'
$ying=ReadEvidence 'ying.json'
$yang=ReadEvidence 'yang-run.json'
$decompiled=ReadEvidence 'decompiled.json'
$built=ReadEvidence 'build.json'
foreach($item in @($yin,$yan,$zing,$ying,$yang,$decompiled,$built)) {
  Check ($item.commit -ceq $commit) 'One outcome belongs to another source revision'
}
$yinPass=($yin.passed -eq $true -and $yin.elapsed_seconds -ge 60 -and $yin.six_stage_loops -gt 0)
$yanPass=($yan.passed -eq $true -and $yan.error_observed -eq $true -and
  $yan.runtime_exit_code -ne 0 -and $yan.timed_run_started -eq $false)
$zingPass=($zing.passed -eq $true -and $zing.numeric_input_count -eq 5 -and
  $zing.numeric_output_count -eq 3 -and $zing.observed_jit_events -gt 0)
$yingPass=($ying.passed -eq $true -and $ying.unhandled_application_exception -eq $true -and
  $ying.runtime_exit_code -ne 0 -and $ying.jit_compilation_observed -eq $true -and
  $ying.os_kernel_panicked -eq $false -and $ying.timed_run_started -eq $false)
$yangPass=($yang.passed -eq $true -and $yang.elapsed_seconds -ge 60 -and
  $yang.six_stage_loops -gt 0 -and $yang.hotspot_jit_method_compilation_observed -eq $true)
Check ($decompiled.passed -eq $true -and $decompiled.pentagonal_nop_is_identity -eq $true -and
  $decompiled.failed_scenarios_remain_failed -eq $true) 'DECOMPILED NOP custody invalid'
Check ((@($decompiled.observed_outcomes) -join ',') -ceq 'PASS,FAIL,PASS,FAIL') 'DECOMPILED history unexpectedly changed'
# Build the observed masks independently from real stage records.
$raw=0
$conformed=0
if($yinPass){$raw=$raw -bor 1;$conformed=$conformed -bor 1}
if($yan.error_observed -ne $true){$raw=$raw -bor 2}
if($yanPass){$conformed=$conformed -bor 2}
if($zingPass){$raw=$raw -bor 4;$conformed=$conformed -bor 4}
if($ying.unhandled_application_exception -ne $true){$raw=$raw -bor 8}
if($yingPass){$conformed=$conformed -bor 8}
if($yangPass){$raw=$raw -bor 16;$conformed=$conformed -bor 16}
$expectedRaw=0x15
$required=0x1f
$extensionHeader = if(Test-Path -LiteralPath 'shared/pentagonal_ligaze.hpp'){
    'shared/pentagonal_ligaze.hpp'
  }else{'native/pentagonal_ligaze.hpp'}
$ext=if($IsWindows){'.exe'}else{''}
$program=Join-Path $BuildDir ('pentagonal_ligaze'+$ext)
if(!(Test-Path -LiteralPath $program)){
  $program=Join-Path (Join-Path $BuildDir 'Release') ('pentagonal_ligaze'+$ext)
}
Check (Test-Path -LiteralPath $program -PathType Leaf) 'Native binary not built by CMake'
function InvokeHolder([int]$rawMask,[int]$checkMask) {
  $operands=@(
    ('0x{0:x2}' -f $rawMask),('0x{0:x2}' -f $expectedRaw),
    ('0x{0:x2}' -f $checkMask),('0x{0:x2}' -f $required)
  )
  $out=@(& $program @operands 2>&1)
  Check ($LASTEXITCODE -eq 0 -and $out.Count -eq 1) 'Native holder did not return one JSON report'
  return ([string]$out[0] | ConvertFrom-Json)
}
$pass=InvokeHolder $raw $conformed
Check ($raw -eq $expectedRaw -and $conformed -eq $required) 'Actual stage outcomes diverge from required fixture'
Check ($pass.schema -ceq 'SWE-LIGAZE-COR-native-v1' -and
       $pass.binary_kind -ceq 'native-cxx20' -and
       $pass.qualification -ceq 'PASS' -and
       $pass.cor_rupture_flags -eq 0 -and
       $pass.cor_logical_evaluations -eq 96 -and
       $pass.nop_held_outcomes -ceq '0x15' -and
       $pass.observed_outcomes -ceq '0x15' -and
       $pass.observed_conformance -ceq '0x1f' -and
       $pass.source_mutated -eq $false -and
       $pass.externally_authenticated -eq $false) 'COR holder failed expected five-ligand binding'
# A second, expected-negative native test: alteration remains visible.
$negative=InvokeHolder ($raw -bxor 1) $conformed
Check ($negative.qualification -ceq 'FAIL' -and
       $negative.cor_rupture_flags -eq 17 -and
       $negative.observed_outcomes -ceq '0x14' -and
       $negative.nop_held_outcomes -ceq '0x14' -and
       $negative.source_mutated -eq $false) 'Native COR did not flag one-bit rupture in both views'
$jar=Join-Path $BuildDir 'pentagonal-supertaoism.jar'
Check ((HashFile $jar) -ceq $built.jar_sha256) 'Java JAR identity changed'
$source=if(Test-Path -LiteralPath 'tools/pentagonal_ligaze.cpp'){
  'tools/pentagonal_ligaze.cpp'
}else{'native/pentagonal_ligaze.cpp'}
$report=[ordered]@{
  schema='PENTAGONAL-LIGAZE-NATIVE-GAMP4-v1'
  commit=$commit
  source_mutated=$false
  binary_kind='native-cxx20'
  native_binary_sha256=HashFile $program
  native_source_sha256=HashFile $source
  native_header_sha256=HashFile $extensionHeader
  companion_jar_sha256=HashFile $jar
  order=@('YIN','YAN','ZING','YING','YANG')
  intended_raw_behavior=@('PASS','EXCEPTION','PASS','EXCEPTION','PASS')
  observed_raw_mask='0x15'
  observed_conformance_mask='0x1f'
  held_cor=$pass
  injected_fault_test=$negative
  individual_evidence_hashes=@(foreach($f in @('yin-run.json','yan.json','zing.json','ying.json','yang-run.json','decompiled.json')) {
    [ordered]@{file=$f;sha256=HashFile (Join-Path $EvidenceDir $f)}
  })
  independent_authentication=$false
  regulatory_qa_release='NOT_APPROVED'
}
$path=Join-Path $EvidenceDir 'ligaze-native.json'
$report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $path -Encoding utf8
Write-Host "LIGAZE|NATIVE|PASS|outcomes=0x15|conformance=0x1f|cor_rupture=0|injected_rupture=17|sha256=$(HashFile $program)"
if($env:GITHUB_STEP_SUMMARY) {
  @('### Native PENTAGONAL-LIGAZE COR',
    '',
    '- Five ligands: YIN / YAN / ZING / YING / YANG',
    '- Raw outcomes: 0x15, including expected YAN/YING failures',
    '- Conformance: 0x1f, all five requirements observed',
    '- COR audit: 96 logical evaluations, no rupture',
    '- Fault injection: rupture bits 0 and 4 asserted (0x0011)',
    "- Native C++20 binary SHA-256: $(HashFile $program)",
    '- Companion Java JAR remains a separate bytecode artifact',
    '- No source mutation or GxP approval inferred'
  ) | Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Encoding utf8
}
