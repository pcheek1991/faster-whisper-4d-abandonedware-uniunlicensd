# SPDX-License-Identifier: 0BSD
# SUPERTAOISM-GAMP4: compiled Java->JAR and observed YIN/YAN/YANG.
# PowerShell 7 + JDK 17, no Gradle, Maven, npm, Python or source mutation.
[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('Build','Test','Tilt','Validate','YinRun','Yan','YangPreflight','YangRun','Audit')]
  [string]$Stage,
  [string]$BuildDir='build-supertaoism',
  [string]$EvidenceDir='evidence-supertaoism',
  [string]$Validator='pentagonal_gamp4_validation_test'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
function Check([bool]$ok,[string]$why){if(-not $ok){throw "SUPERTAOISM $($Stage): $why"}}
function SHA([string]$file){
  Check (Test-Path -LiteralPath $file -PathType Leaf) "Missing file: $file"
  return (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Save([string]$name,[object]$data){
  $data|ConvertTo-Json -Depth 12|Set-Content -LiteralPath (Join-Path $EvidenceDir $name) -Encoding utf8
}
function Load([string]$name){
  $file=Join-Path $EvidenceDir $name
  Check (Test-Path -LiteralPath $file -PathType Leaf) "Missing evidence: $name"
  return (Get-Content -LiteralPath $file -Raw|ConvertFrom-Json)
}
function RequireWitness([string]$name){
  $record=Load $name
  Check ($record.commit -ceq $commit -and $record.passed -eq $true) "Invalid $name or different commit"
  return $record
}
function Summary([string]$message){
  Write-Host $message
  if($env:GITHUB_STEP_SUMMARY){$message|Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Encoding utf8}
}
function JavaCommand([string[]]$arguments){
  $output=@(& java @arguments 2>&1)
  $exit=$LASTEXITCODE
  Check ($exit -eq 0) "Java exited $exit : $($output -join ' ')"
  foreach($line in $output){Write-Host $line}
  return @($output)
}
function MatchesLine([string[]]$lines,[string]$expression){
  $found=@($lines|Where-Object{$_ -match $expression})
  Check ($found.Count -eq 1) "Expected one successful line matching $expression; found $($found.Count)"
  return [string]$found[0]
}
if($env:JAVA_HOME_17_X64){
  $bin=Join-Path $env:JAVA_HOME_17_X64 'bin'
  if(Test-Path -LiteralPath $bin -PathType Container){
    $env:PATH=$bin+[IO.Path]::PathSeparator+$env:PATH
  }
}
$commit=((& git rev-parse HEAD)|Out-String).Trim()
Check ($LASTEXITCODE -eq 0 -and $commit -match '^[0-9a-f]{40}$') 'Invalid exact source commit'
if($env:GITHUB_SHA){Check ($commit -ceq $env:GITHUB_SHA) 'Wrong checked-out Git SHA'}
New-Item -ItemType Directory -Force -Path $EvidenceDir|Out-Null
$jar=Join-Path $BuildDir 'pentagonal-supertaoism.jar'
$source='java/SupertaoismGamp4.java'
$extension='java/PentagonalExtensions.java'
$original='java/PentagonalControl.java'
$recovery='dd57ce6e8bbeeaad4af14cb06a08ec83c38d2deab16e814f97e963f5a94b0114'

if($Stage -eq 'Build'){
  $javaVersion=((& javac -version 2>&1)|Out-String).Trim()
  Check ($LASTEXITCODE -eq 0 -and $javaVersion -match 'javac 17[.]') 'Requires JDK 17 for portable reproducible builds'
  $classes=Join-Path $BuildDir 'java-classes'
  New-Item -ItemType Directory -Force -Path $classes|Out-Null
  & javac --release 17 -encoding UTF-8 -d $classes $original $source $extension
  Check ($LASTEXITCODE -eq 0) 'Java sources failed compilation'
  & jar --create --file $jar --main-class SupertaoismGamp4 -C $classes .
  Check ($LASTEXITCODE -eq 0) 'JAR packaging failed'
  $members=@(& jar --list --file $jar)
  Check ($LASTEXITCODE -eq 0) 'Cannot inspect JAR'
  foreach($entry in @('META-INF/MANIFEST.MF','PentagonalControl.class','SupertaoismGamp4.class','SupertaoismGamp4$PoisonedCycle.class','PentagonalExtensions.class')){
    Check ($members -contains $entry) "Missing JAR entry $entry"
  }
  Save 'build.json' ([ordered]@{
    schema='SUPERTAOISM-GAMP4-JAVA-JAR-v1';stage='BUILD';passed=$true
    commit=$commit;compiler=$javaVersion
    java17_release=$true
    class_main='SupertaoismGamp4'
    jar_sha256=SHA $jar
    original_source_sha256=SHA $original
    supertaoism_source_sha256=SHA $source
    extension_source_sha256=SHA $extension
    recovery_embedded_source_sha256=$recovery
    packaging='executable-jar'
    gxp_certified=$false
  })
  Summary "SUPERTAOISM|BUILD|PASS|jar_sha256=$(SHA $jar)|compiler=$javaVersion"
  return
}
$build=RequireWitness 'build.json'
Check ((SHA $jar) -ceq $build.jar_sha256) 'JAR changed after build'
Check ((SHA $source) -ceq $build.supertaoism_source_sha256) 'Supertaoism source changed after build'
Check ((SHA $extension) -ceq $build.extension_source_sha256) 'Extension source changed after build'
Check ((SHA $original) -ceq $build.original_source_sha256) 'Original Pentagonal class changed after build'

if($Stage -eq 'Test'){
  & ./ci/Invoke-PentagonalTTVR.ps1 -Phase TEST -BuildDir $BuildDir -EvidenceDir $EvidenceDir -Validator $Validator
  Check ($?) 'Original C++20 CTest and Java reference test failed'
  $lines=JavaCommand @('-jar',$jar,'--yin-test')
  $line=MatchesLine $lines '^SUPERTAOISM_YIN_TEST[|]PASS[|]'
  Save 'yin-test.json' ([ordered]@{stage='YIN_TEST';passed=$true;commit=$commit;result=$line;jar_sha256=$build.jar_sha256})
  Summary 'SUPERTAOISM|YIN_TEST|PASS|original_ctest=pass'
  return
}
$yinTest=RequireWitness 'yin-test.json'
if($Stage -eq 'Tilt'){
  & ./ci/Invoke-PentagonalTTVR.ps1 -Phase TILT -BuildDir $BuildDir -EvidenceDir $EvidenceDir -Validator $Validator
  Check ($?) 'Original native/Java one-bit TILT failed'
  $lines=JavaCommand @('-jar',$jar,'--yin-tilt')
  $line=MatchesLine $lines '^SUPERTAOISM_YIN_TILT[|]PASS[|]expected_fault_detected=true'
  Save 'yin-tilt.json' ([ordered]@{stage='YIN_TILT';passed=$true;commit=$commit;result=$line;source_mutated=$false})
  Summary 'SUPERTAOISM|YIN_TILT|PASS|error_detected=1|source_unchanged=true'
  return
}
$yinTilt=RequireWitness 'yin-tilt.json'
if($Stage -eq 'Validate'){
  & ./ci/Invoke-PentagonalTTVR.ps1 -Phase VALIDATE -BuildDir $BuildDir -EvidenceDir $EvidenceDir -Validator $Validator
  Check ($?) 'Supplier-side GAMP 4-style URS validation failed'
  $lines=JavaCommand @('-jar',$jar,'--yin-validate')
  $line=MatchesLine $lines '^SUPERTAOISM_YIN_VALIDATE[|]PASS[|]'
  Save 'yin-validate.json' ([ordered]@{
    stage='YIN_VALIDATE';passed=$true;commit=$commit
    result=$line;urs_checks=12;pq='NOT_PERFORMED';qa='NOT_APPROVED'
    original_gamp4_validation_sha256=SHA (Join-Path $EvidenceDir 'validate.json')
  })
  Summary 'SUPERTAOISM|YIN_VALIDATE|PASS|12_URS=true|pq=NOT_PERFORMED'
  return
}
$yinValidation=RequireWitness 'yin-validate.json'
Check ((SHA (Join-Path $EvidenceDir 'validate.json')) -ceq $yinValidation.original_gamp4_validation_sha256) 'YIN validation record changed'
if($Stage -eq 'YinRun'){
  $lines=JavaCommand @('-jar',$jar,'--yin-run','60')
  $line=MatchesLine $lines '^PENTAGONAL_JAVA_STRESS[|]PASS[|]elapsed_seconds=([0-9.]+)[|]ticks=([0-9]+)[|]loops=([0-9]+)[|]'
  $regex='^PENTAGONAL_JAVA_STRESS[|]PASS[|]elapsed_seconds=([0-9.]+)[|]ticks=([0-9]+)[|]loops=([0-9]+)[|]'
  $null=$line -match $regex
  $seconds=[double]::Parse($Matches[1],[Globalization.CultureInfo]::InvariantCulture)
  $ticks=[long]::Parse($Matches[2]);$loops=[long]::Parse($Matches[3])
  Check ($seconds -ge 60 -and $ticks -gt 0 -and $loops -gt 0) 'YIN did not actively execute for 60 seconds'
  $closing=MatchesLine $lines '^SUPERTAOISM_YIN_RUN[|]PASS[|]'
  $log=Join-Path $EvidenceDir 'yin-60seconds.log'
  $lines|Set-Content -LiteralPath $log -Encoding utf8
  Save 'yin-run.json' ([ordered]@{
    stage='YIN_RUN';passed=$true;commit=$commit
    elapsed_seconds=$seconds;stage_ticks=$ticks;six_stage_loops=$loops
    log_sha256=SHA $log
    last=$line;closing=$closing;source_mutated=$false
  })
  Summary "SUPERTAOISM|YIN_RUN|PASS|elapsed_seconds=$seconds|loops=$loops"
  return
}
$yinRun=RequireWitness 'yin-run.json'
Check ($yinRun.elapsed_seconds -ge 60) 'Missing successful 60 second YIN run'
Check ((SHA (Join-Path $EvidenceDir 'yin-60seconds.log')) -ceq $yinRun.log_sha256) 'YIN evidence changed'

if($Stage -eq 'Yan'){
  $out=Join-Path $EvidenceDir 'yan.stdout.log'
  $err=Join-Path $EvidenceDir 'yan.stderr.log'
  # Expected crash: isolate stderr so an anticipated nonzero exit cannot
  # be misconstrued as a passing production execution.
  $process=Start-Process -FilePath 'java' -ArgumentList @('-jar',$jar,'--yan') -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
  $output=Get-Content -LiteralPath $out -Raw
  $errorText=Get-Content -LiteralPath $err -Raw
  Check ($process.ExitCode -ne 0) 'Poisoned class unexpectedly succeeded'
  Check ($errorText.Contains('java.lang.IllegalStateException: SUPERTAOISM_YAN_RUNTIME_POISON')) 'Runtime poison did not fail with the exact approved marker'
  Check ($output.Contains('SUPERTAOISM_YAN|INTENTIONAL_RUNTIME_FAILURE')) 'YAN test did not visibly identify negative intent'
  Check (-not $output.Contains('SUPERTAOISM_YANG_RUN') -and -not $output.Contains('SUPERTAOISM_YIN_RUN')) 'Poisoned class actually started timed run'
  Save 'yan.json' ([ordered]@{
    stage='YAN_EXPECTED_FAILURE';passed=$true;commit=$commit
    runtime_exit_code=$process.ExitCode;error_observed=$true
    timed_run_started=$false;poison_class_unchanged=$true
    stdout_sha256=SHA $out;stderr_sha256=SHA $err
  })
  Summary "SUPERTAOISM|YAN|EXPECTED_FAILURE_CONFIRMED|exit=$($process.ExitCode)|no_run=true"
  return
}
$yan=RequireWitness 'yan.json'
Check ($yan.error_observed -eq $true -and $yan.timed_run_started -eq $false) 'YAN runtime-failure record invalid'
if($Stage -eq 'YangPreflight'){
  $lines=JavaCommand @('-jar',$jar,'--yang-preflight')
  $line=MatchesLine $lines '^SUPERTAOISM_YANG_PREFLIGHT[|]PASS[|].*runtime_compiled=true[|]relinked=true[|]'
  Check ($line.Contains("recovery_sha256=$recovery")) 'Recovery compilation did not use reviewed source'
  Save 'yang-preflight.json' ([ordered]@{
    stage='YANG_PREFLIGHT';passed=$true;commit=$commit
    original_poison_error_observed=$true
    compile_on_demand=$true;mutable_callsite_relinked=$true
    truth_states=32;bit_flip_cases=30
    approved_source_sha256=$recovery
    result=$line
  })
  Summary 'SUPERTAOISM|YANG_PREFLIGHT|PASS|runtime_compiler=true|relinked=true|bit_flips=30'
  return
}
$yangPreflight=RequireWitness 'yang-preflight.json'
Check ($yangPreflight.approved_source_sha256 -ceq $recovery) 'Reviewed recovery digest changed'

if($Stage -eq 'YangRun'){
  $jitLog=([IO.Path]::GetFullPath((Join-Path $EvidenceDir 'jit-compilation.log')))
  $runLog=Join-Path $EvidenceDir 'yang-60seconds.stdout.log'
  $runError=Join-Path $EvidenceDir 'yang-60seconds.stderr.log'
  # JVM HotSpot JIT compilation logs are separate from the application output.
  # JavaCompiler API is used to build ApprovedRecovery on demand; JIT then
  # compiles ApprovedRecovery::cycle into machine code under observed load.
  $jitFlag="-Xlog:jit+compilation=debug:file=$($jitLog):uptime,level,tags"
  $process=Start-Process -FilePath 'java' -ArgumentList @($jitFlag,'-jar',$jar,'--yang-run','60') -Wait -PassThru -RedirectStandardOutput $runLog -RedirectStandardError $runError
  Check ($process.ExitCode -eq 0) "YANG failed $($process.ExitCode): $(Get-Content $runError -Raw)"
  $lines=@(Get-Content -LiteralPath $runLog)
  $passLine=MatchesLine $lines '^SUPERTAOISM_YANG_RUN[|]PASS[|]elapsed_seconds=([0-9.]+)[|]loops=([0-9]+)[|]'
  $pattern='^SUPERTAOISM_YANG_RUN[|]PASS[|]elapsed_seconds=([0-9.]+)[|]loops=([0-9]+)[|]'
  $null=$passLine -match $pattern
  $seconds=[double]::Parse($Matches[1],[Globalization.CultureInfo]::InvariantCulture)
  $loops=[long]::Parse($Matches[2])
  Check ($seconds -ge 60 -and $loops -gt 0) 'YANG did not perform 60 seconds of productive work'
  $preflight=MatchesLine $lines '^SUPERTAOISM_YANG_PREFLIGHT[|]PASS[|]'
  Check ($preflight.Contains("recovery_sha256=$recovery")) 'Runtime recovery code digest changed'
  $jitLines=@(Get-Content -LiteralPath $jitLog | Where-Object { $_.Contains('ApprovedRecovery::cycle') })
  Check ($jitLines.Count -gt 0) 'No observed HotSpot JIT compilation of ApprovedRecovery::cycle'
  Save 'yang-run.json' ([ordered]@{
    stage='YANG_RUN';passed=$true;commit=$commit
    elapsed_seconds=$seconds;six_stage_loops=$loops
    runtime_compilation_and_relink=$true;hotspot_jit_method_compilation_observed=$true
    jit_method_events=$jitLines.Count;recovery_sha256=$recovery
    stdout_sha256=SHA $runLog;stderr_sha256=SHA $runError
    jit_log_sha256=SHA $jitLog
    no_nop_bypass=$true;poison_class_unchanged=$true
  })
  Summary "SUPERTAOISM|YANG_RUN|PASS|elapsed_seconds=$seconds|loops=$loops|observed_jit_events=$($jitLines.Count)"
  return
}
$yangRun=RequireWitness 'yang-run.json'
Check ($yangRun.elapsed_seconds -ge 60 -and $yangRun.hotspot_jit_method_compilation_observed -eq $true) 'YANG run or JIT evidence missing'
$report=[ordered]@{
  schema='SUPERTAOISM-GAMP4-EXECUTION-v1'
  commit=$commit;jar_sha256=$build.jar_sha256
  original_source_sha256=$build.original_source_sha256
  supertaoism_source_sha256=$build.supertaoism_source_sha256
  yin=$yinRun
  yan=$yan
  yang=$yangRun
  qa_status='NOT_APPROVED'
  pq_status='NOT_PERFORMED'
  externally_signed_witness=$false
  gxp_certification=$false
  source_modified=$false
  files=@(foreach($file in @(Get-ChildItem -LiteralPath $EvidenceDir -File|Sort-Object Name)){
    [ordered]@{name=$file.Name;sha256=SHA $file.FullName}
  })
}
Save 'supertaoism-final.json' $report
Summary "SUPERTAOISM|AUDIT|PASS|yin_seconds=$($yinRun.elapsed_seconds)|yan_expected_error=true|yang_seconds=$($yangRun.elapsed_seconds)|jar_sha256=$($build.jar_sha256)"
