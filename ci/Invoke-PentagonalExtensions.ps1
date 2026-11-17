# SPDX-License-Identifier: 0BSD
# Additional supplier-side exercises: YING -> ZING -> DECOMPILED
# Only Java 17, PowerShell 7, JDK tools; no untrusted dynamically loaded source.
[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet('Ying','Zing','Decompiled')][string]$Stage,
  [string]$BuildDir='build-supertaoism',
  [string]$EvidenceDir='evidence-supertaoism'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
function Assert([bool]$pass,[string]$reason){
  if (-not $pass) {throw "SUPERTAOISM $($Stage) failed: $reason"}
}
function SHA([string]$file) {
  Assert (Test-Path -LiteralPath $file -PathType Leaf) "Missing $file"
  return (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Load([string]$filename) {
  $path=Join-Path $EvidenceDir $filename
  Assert (Test-Path -LiteralPath $path -PathType Leaf) "Missing $filename"
  return (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)
}
function Save([string]$filename,[object]$data) {
  $data | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $EvidenceDir $filename) -Encoding utf8
}
function RecordLine([string[]]$lines,[string]$regex) {
  $matchesFound=@($lines | Where-Object {$_ -match $regex})
  Assert ($matchesFound.Count -eq 1) "Expected one evidence line matching $regex"
  return [string]$matchesFound[0]
}
function Summary([string]$s){
  Write-Host $s
  if($env:GITHUB_STEP_SUMMARY){$s | Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Encoding utf8}
}
$commit=((& git rev-parse HEAD)|Out-String).Trim()
Assert ($LASTEXITCODE -eq 0 -and $commit -match '^[0-9a-f]{40}$') 'Invalid Git commit'
if ($env:GITHUB_SHA) { Assert ($commit -ceq $env:GITHUB_SHA) 'Source commit drift' }
$jar=Join-Path $BuildDir 'pentagonal-supertaoism.jar'
$built=Load 'build.json'
Assert ($built.passed -eq $true -and $built.commit -ceq $commit) 'Wrong build witness'
Assert ((SHA $jar) -ceq $built.jar_sha256) 'JAR digest drift'
Assert ((SHA 'java/PentagonalExtensions.java') -ceq $built.extension_source_sha256) 'Extension source digest drift'
$yin=Load 'yin-run.json'
$yan=Load 'yan.json'
$yang=Load 'yang-run.json'
Assert ($yin.passed -eq $true -and $yin.elapsed_seconds -ge 60 -and $yin.commit -ceq $commit) 'YIN execution missing'
Assert ($yan.passed -eq $true -and $yan.error_observed -eq $true -and $yan.timed_run_started -eq $false -and $yan.commit -ceq $commit) 'YAN failure not verified'
Assert ($yang.passed -eq $true -and $yang.elapsed_seconds -ge 60 -and $yang.commit -ceq $commit) 'YANG execution missing'

if ($Stage -eq 'Ying') {
  $jitLog=[IO.Path]::GetFullPath((Join-Path $EvidenceDir 'ying-jit-compilation.log'))
  $stdout=Join-Path $EvidenceDir 'ying.stdout.log'
  $stderr=Join-Path $EvidenceDir 'ying.stderr.log'
  $jitArg="-Xlog:jit+compilation=debug:file=$($jitLog):uptime,level,tags"
  $argsList=@($jitArg,'-cp',$jar,'PentagonalExtensions','--ying')
  $p=Start-Process -FilePath 'java' -ArgumentList $argsList -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
  $out=Get-Content -LiteralPath $stdout -Raw
  $err=Get-Content -LiteralPath $stderr -Raw
  Assert ($p.ExitCode -ne 0) 'YING injection was unexpectedly tolerated'
  Assert ($out.Contains('SUPERTAOISM_YING|CLEAN_HOT_PATH|PASS') -and
          $out.Contains('SUPERTAOISM_YING|FAULT_INJECTED|phase=runtime_dispatch')) 'Clean/poison transition not observed'
  Assert ($err.Contains('java.lang.IllegalStateException: SUPERTAOISM_YING_INJECTED_RUNTIME_FAULT')) 'Wrong or caught YING exception'
  $jit=@(Get-Content -LiteralPath $jitLog | Where-Object { $_.Contains('PentagonalExtensions::cleanHot') })
  Assert ($jit.Count -gt 0) 'No observed HotSpot JIT compilation of initial valid method'
  Assert ((SHA $jar) -ceq $built.jar_sha256) 'JAR mutated during YING'
  Save 'ying.json' ([ordered]@{
    schema='SUPERTAOISM-YING-v1';passed=$true;commit=$commit
    original_method_warmed=$true
    jit_compilation_observed=$true
    compiled_method='PentagonalExtensions::cleanHot'
    jit_events=$jit.Count
    poison_injected_at='mutable-call-site'
    runtime_exit_code=$p.ExitCode
    unhandled_application_exception=$true
    os_kernel_panicked=$false
    timed_run_started=$false
    source_mutated=$false
    stdout_sha256=SHA $stdout
    stderr_sha256=SHA $stderr
    jit_sha256=SHA $jitLog
  })
  Summary "SUPERTAOISM|YING|EXPECTED_UNHANDLED_EXCEPTION|jit_events=$($jit.Count)|exit=$($p.ExitCode)|kernel_panic=false"
  return
}
$ying=Load 'ying.json'
Assert ($ying.passed -eq $true -and $ying.unhandled_application_exception -eq $true -and $ying.os_kernel_panicked -eq $false) 'YING negative test missing'

if ($Stage -eq 'Zing') {
  $jitLog=[IO.Path]::GetFullPath((Join-Path $EvidenceDir 'zing-jit-compilation.log'))
  $stdout=Join-Path $EvidenceDir 'zing.stdout.log'
  $stderr=Join-Path $EvidenceDir 'zing.stderr.log'
  $jitArg="-Xlog:jit+compilation=debug:file=$($jitLog):uptime,level,tags"
  $p=Start-Process -FilePath 'java' -ArgumentList @($jitArg,'-cp',$jar,'PentagonalExtensions','--zing') -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
  Assert ($p.ExitCode -eq 0) "ZING failed with exit $($p.ExitCode): $(Get-Content $stderr -Raw)"
  $lines=@(Get-Content -LiteralPath $stdout)
  $line=RecordLine $lines '^SUPERTAOISM_ZING[|]PASS[|]inverse_square_inputs=5[|]inverse_square_outputs=3[|]'
  Assert ($line.Contains('|negative_tests=11|')) 'ZING did not test zero/NaN and singularity'
  $jit=@(Get-Content -LiteralPath $jitLog | Where-Object { $_.Contains('PentagonalExtensions::zingJit') })
  Assert ($jit.Count -gt 0) 'No observed HotSpot JIT compilation of inverse-square method'
  Assert ((SHA $jar) -ceq $built.jar_sha256) 'JAR changed during ZING'
  Save 'zing.json' ([ordered]@{
    schema='SUPERTAOISM-ZING-v1';passed=$true;commit=$commit
    numeric_input_count=5;numeric_output_count=3
    normalized_to_unit_interval=$true
    singular_and_nonfinite_input_rejection=$true
    observed_jit_events=$jit.Count
    observed_method='PentagonalExtensions::zingJit'
    source_mutated=$false
    summary=$line
    stdout_sha256=SHA $stdout
    stderr_sha256=SHA $stderr
    jit_sha256=SHA $jitLog
  })
  Summary "SUPERTAOISM|ZING|PASS|input_ligands=5|output_scores=3|jit_events=$($jit.Count)"
  return
}
$zing=Load 'zing.json'
Assert ($zing.passed -eq $true -and $zing.numeric_input_count -eq 5 -and $zing.numeric_output_count -eq 3) 'ZING not verified'

# DECOMPILED is a report overlay, not an actual Java bytecode decompiler.
# Read actual CI outcomes before applying the NOP identity function.
Assert ((SHA (Join-Path $EvidenceDir 'ying.stdout.log')) -ceq $ying.stdout_sha256) 'YING evidence changed'
Assert ((SHA (Join-Path $EvidenceDir 'zing.stdout.log')) -ceq $zing.stdout_sha256) 'ZING evidence changed'
$lines=@(& java -cp $jar PentagonalExtensions --decompiled PASS FAIL PASS FAIL 2>&1)
Assert ($LASTEXITCODE -eq 0) 'DECOMPILED process failed'
$summary=RecordLine $lines '^SUPERTAOISM_DECOMPILED[|]PASS[|]paths=4[|]healthy=2[|]faulted=2[|]'
foreach($case in @('YIN','YAN','YANG','YING')){
  $retained=if($case -eq 'YAN' -or $case -eq 'YING') {'FAIL'} else {'PASS'}
  $null=RecordLine $lines "^SUPERTAOISM_DECOMPILED[|]$case[|]retained_status=$retained[|]pentagonal_nop=identity[|]exception_suppressed=false"
}
Save 'decompiled.json' ([ordered]@{
  schema='SUPERTAOISM-DECOMPILED-v1';passed=$true;commit=$commit
  paths=@('YIN','YAN','YANG','YING')
  observed_outcomes=@('PASS','FAIL','PASS','FAIL')
  pentagonal_nop_is_identity=$true
  failed_scenarios_remain_failed=$true
  is_java_bytecode_decompiler=$false
  source_mutated=$false
  summary=$summary
  jar_sha256=SHA $jar
  ying_evidence_sha256=SHA (Join-Path $EvidenceDir 'ying.json')
  zing_evidence_sha256=SHA (Join-Path $EvidenceDir 'zing.json')
})
$lines|ForEach-Object{Write-Host $_}
Summary 'SUPERTAOISM|DECOMPILED|PASS|YIN=PASS|YAN=FAIL|YANG=PASS|YING=FAIL|NOP=identity|ZING=validated'
