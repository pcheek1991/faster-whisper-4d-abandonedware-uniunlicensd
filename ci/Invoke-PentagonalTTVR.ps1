# SPDX-License-Identifier: 0BSD
# PENTAGONAL TEST -> TILT(expected error) -> VALIDATE -> RUN(60 active seconds)
# Native PowerShell 7 + C++20 + self-contained Java 17; no source mutation.
[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet('TEST','TILT','VALIDATE','RUN')][string]$Phase,
  [string]$BuildDir='build-ttvr',
  [string]$EvidenceDir='evidence-ttvr',
  [string]$Validator='pentagonal_gamp4_validation_test'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
function Guard([bool]$yes,[string]$reason){if(-not $yes){throw "PENTAGONAL $Phase failed: $reason"}}
function Fingerprint([string]$path){
  Guard (Test-Path -LiteralPath $path -PathType Leaf) "Missing $path"
  return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function SaveJson([string]$name,[object]$obj){
  $obj | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $EvidenceDir $name) -Encoding utf8
}
function LoadJson([string]$name){
  $file=Join-Path $EvidenceDir $name
  Guard (Test-Path -LiteralPath $file -PathType Leaf) "Missing $name"
  return (Get-Content -LiteralPath $file -Raw | ConvertFrom-Json)
}
function Executable([string]$name){
  $ext=if($IsWindows){'.exe'}else{''}
  foreach($p in @((Join-Path $BuildDir ($name+$ext)),(Join-Path (Join-Path $BuildDir 'Release') ($name+$ext)))){
    if(Test-Path -LiteralPath $p -PathType Leaf){return $p}
  }
  throw "Missing compiled program $name"
}
function JavaSetup {
  if($env:JAVA_HOME_17_X64){
    $bin=Join-Path $env:JAVA_HOME_17_X64 'bin'
    if(Test-Path -LiteralPath $bin -PathType Container){
      $env:PATH=$bin+[IO.Path]::PathSeparator+$env:PATH
    }
  }
}
function Summary([string[]]$lines){
  if($env:GITHUB_STEP_SUMMARY){$lines|Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Encoding utf8}
}
$commit=((& git rev-parse HEAD)|Out-String).Trim()
Guard ($LASTEXITCODE -eq 0 -and $commit -match '^[0-9a-f]{40}$') 'Not an exact Git checkout'
if($env:GITHUB_SHA){Guard ($commit -ceq $env:GITHUB_SHA) 'Git checkout SHA mismatch'}
New-Item -ItemType Directory -Path $EvidenceDir -Force|Out-Null
JavaSetup

if($Phase -eq 'TEST'){
  & cmake -S . -B $BuildDir -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Release
  Guard ($LASTEXITCODE -eq 0) 'CMake configure'
  & cmake --build $BuildDir --config Release --parallel 2
  Guard ($LASTEXITCODE -eq 0) 'C++20 compile'
  $xml=Join-Path ([IO.Path]::GetFullPath($EvidenceDir)) 'ctest-results.xml'
  & ctest --test-dir $BuildDir -C Release --output-on-failure --output-junit $xml
  Guard ($LASTEXITCODE -eq 0) 'C++ CTest'
  & javac -version
  Guard ($LASTEXITCODE -eq 0) 'Java compiler unavailable'
  $javaOut=Join-Path $BuildDir 'java'
  New-Item -ItemType Directory -Path $javaOut -Force|Out-Null
  & javac -encoding UTF-8 -d $javaOut java/PentagonalControl.java
  Guard ($LASTEXITCODE -eq 0) 'Java compilation'
  $out=@(& java -cp $javaOut PentagonalControl --self-test 2>&1)
  Guard ($LASTEXITCODE -eq 0 -and $out.Count -eq 1) 'Java self-test process'
  Guard ([string]$out[0] -match '^PENTAGONAL_JAVA_SELF_TEST\|PASS\|') 'Java self-test summary'
  SaveJson 'test.json' ([ordered]@{
    phase='TEST';pass=$true;commit=$commit
    java_source_sha256=Fingerprint 'java/PentagonalControl.java'
    native_executable_sha256=Fingerprint (Executable 'pentagonal_control')
    ctest_xml_sha256=Fingerprint $xml
    java_test=[string]$out[0]
  })
  Write-Host $out[0]
  Write-Host 'TTVR|TEST|PASS|cpp_ctest=all|java_self_test=pass'
  Summary @('### TEST: PASS', "- Commit: $commit", '- CTest and Java exhaustive tests passed')
  return
}
$test=LoadJson 'test.json'
Guard ($test.pass -eq $true -and $test.commit -ceq $commit) 'TEST must pass before progressing'
Guard ((Fingerprint 'java/PentagonalControl.java') -ceq $test.java_source_sha256) 'Source digest changed since TEST'
Guard ((Fingerprint (Executable 'pentagonal_control')) -ceq $test.native_executable_sha256) 'Native executable changed'

if($Phase -eq 'TILT'){
  # Deliberately wrong test operand, not a change to source:
  # baseline 0x3fffffff, observed 0x3ffffffb (bit 2 off).
  $raw=(& (Executable 'pentagonal_control') 0x3ffffffb 0x3fffffff or | Out-String)
  Guard ($LASTEXITCODE -eq 0) 'Native fault injection invocation'
  $native=$raw|ConvertFrom-Json
  Guard ($native.rupture_flags -eq 1 -and $native.logical_evaluations -eq 96 -and $native.source_mutated -eq $false) 'Native failed to detect deliberate bit rupture'
  $java=@(& java -cp (Join-Path $BuildDir 'java') PentagonalControl --tilt 2>&1)
  Guard ($LASTEXITCODE -eq 0 -and $java.Count -eq 1) 'Java fault injection process'
  Guard ([string]$java[0] -match '^PENTAGONAL_JAVA_TILT\|PASS\|') 'Java did not detect injected error'
  Guard ((Fingerprint 'java/PentagonalControl.java') -ceq $test.java_source_sha256) 'TILT modified original Java source'
  SaveJson 'tilt.json' ([ordered]@{
    phase='TILT';pass=$true;commit=$commit
    error_injected=$true;error_detected=$true;rupture_flags=1
    original_operand='0x3fffffff';injected_operand='0x3ffffffb'
    native_source_mutated=$false;java_witness=[string]$java[0]
  })
  Write-Host $java[0]
  Write-Host 'TTVR|TILT|PASS|expected_error_detected=true|source_mutated=false'
  Summary @('### TILT: PASS (expected error detected)', '- Injected one-bit error in test operand only', '- Both native and Java reported rupture 0x0001')
  return
}
$tilt=LoadJson 'tilt.json'
Guard ($tilt.pass -eq $true -and $tilt.error_detected -eq $true -and $tilt.commit -ceq $commit) 'TILT must detect expected fault'

if($Phase -eq 'VALIDATE'){
  & ./ci/Invoke-PentagonalGamp4.ps1 -BuildDir $BuildDir -EvidenceDir $EvidenceDir -ExecutableName $Validator
  Guard ($?) 'GAMP 4-style supplier verification'
  $reports=@(Get-ChildItem -LiteralPath $EvidenceDir -Filter 'pentagonal-gamp4-*.json' -File)
  Guard ($reports.Count -eq 1) 'Expected precisely one URS report'
  $qualified=Get-Content -LiteralPath $reports[0].FullName -Raw|ConvertFrom-Json
  Guard ($qualified.pass -eq $true -and $qualified.process_exit -eq 0) 'GAMP report not passing'
  Guard ($qualified.commit -ceq $commit -and $qualified.test_count -eq 12 -and @($qualified.observed_pass_ids).Count -eq 12) 'Wrong commit or URS count'
  SaveJson 'validate.json' ([ordered]@{
    phase='VALIDATE';pass=$true;commit=$commit
    gamp4_style_urs=12
    original_report=$reports[0].Name
    original_report_sha256=Fingerprint $reports[0].FullName
    test_sha256=Fingerprint (Join-Path $EvidenceDir 'test.json')
    tilt_sha256=Fingerprint (Join-Path $EvidenceDir 'tilt.json')
    pq_status='NOT_PERFORMED';qa_approval='NOT_APPROVED'
  })
  Write-Host 'TTVR|VALIDATE|PASS|urs=12|independent_qa_approval=false'
  Summary @('### VALIDATE: PASS', '- Twelve GAMP 4-style URS checks passed', '- Source, test and fault-injection custody recorded', '- PQ / QA approval remains OPEN')
  return
}
$validation=LoadJson 'validate.json'
Guard ($validation.pass -eq $true -and $validation.gamp4_style_urs -eq 12 -and $validation.commit -ceq $commit) 'VALIDATE must pass'
Guard ((Fingerprint (Join-Path $EvidenceDir 'test.json')) -ceq $validation.test_sha256) 'TEST changed since validation'
Guard ((Fingerprint (Join-Path $EvidenceDir 'tilt.json')) -ceq $validation.tilt_sha256) 'TILT changed since validation'
$originalReport=Join-Path $EvidenceDir $validation.original_report
Guard ((Fingerprint $originalReport) -ceq $validation.original_report_sha256) 'Validation evidence changed'
$run=@(& java -cp (Join-Path $BuildDir 'java') PentagonalControl --stress 60 2>&1)
Guard ($LASTEXITCODE -eq 0 -and $run.Count -gt 0) 'Java 60-second active run'
$last=[string]$run[-1]
Guard ($last -match '^PENTAGONAL_JAVA_STRESS\|PASS\|elapsed_seconds=([0-9]+(\.[0-9]+)?)\|ticks=([0-9]+)\|loops=([0-9]+)\|checksum=(-?[0-9]+)\|source_mutated=false$') 'Malformed 60-second evidence'
$seconds=[double]::Parse($Matches[1],[Globalization.CultureInfo]::InvariantCulture)
$ticks=[long]::Parse($Matches[3]);$loops=[long]::Parse($Matches[4])
Guard ($seconds -ge 60.0 -and $ticks -gt 0 -and $loops -gt 0) 'Run did not actively execute for 60 seconds'
$logFile=Join-Path $EvidenceDir 'pentagonal-java-60-seconds.log'
$run|Set-Content -LiteralPath $logFile -Encoding utf8
$hashes=@(foreach($file in @(Get-ChildItem -LiteralPath $EvidenceDir -File | Sort-Object Name)){
  [ordered]@{name=$file.Name;sha256=Fingerprint $file.FullName}
})
SaveJson 'run.json' ([ordered]@{
  phase='RUN';pass=$true;commit=$commit
  active_seconds=$seconds;ticks=$ticks;six_stage_loops=$loops
  test_pass=$true;tilt_pass=$true;validate_pass=$true;source_mutated=$false
  no_gxp_certification=$true;evidence_hashes=$hashes
})
$run|ForEach-Object{Write-Host $_}
Write-Host "TTVR|RUN|PASS|active_seconds=$seconds|loops=$loops"
Summary @('### RUN: PASS', "- Active duration: $seconds seconds", "- Six-stage loops: $loops",
  "- Source: $commit", '- No data overwritten; this is not operational PQ')
