# SPDX-License-Identifier: 0BSD
# Controlled MSVC A/B Windows study. No Python, Node, or source rewrites.
# /O2 is already the Release default. Test header effects independently from WPO.
[CmdletBinding()]
param(
    [int]$Iterations = 500000,
    [int]$Warmup = 50000,
    [int]$Repeats = 5,
    [int]$Trials = 3,
    [string]$Root = 'build-ligaze-windows-ab',
    [string]$Evidence = 'evidence-ligaze-windows-ab'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Require([bool]$condition,[string]$message) {
    if(-not $condition) { throw "WINDOWS_AB: $message" }
}
function Hash([string]$path) {
    Require (Test-Path -LiteralPath $path -PathType Leaf) "Missing path: $path"
    return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Program([string]$variant) {
    $path=Join-Path (Join-Path (Join-Path $Root $variant) 'Release') 'pentagonal_ligaze_benchmark.exe'
    Require (Test-Path -LiteralPath $path -PathType Leaf) "Missing executable: $path"
    return $path
}
function Sample([string]$exe) {
    $output=@(& $exe ([string]$Iterations) ([string]$Warmup) ([string]$Repeats))
    Require ($LASTEXITCODE -eq 0 -and $output.Count -gt 0) "Benchmark $exe failed"
    $record=[string]$output[-1] | ConvertFrom-Json
    Require ($record.schema -ceq 'SWE-LIGAZE-BENCH-v1' -and
             $record.iterations -eq $Iterations -and
             $record.repeats -eq $Repeats -and
             $record.threat_fixtures -ceq 'PASS' -and
             $record.median_ns_per_call -gt 0) "Benchmark contract violation: $exe"
    return $record
}
function InvokeBuild([string]$variant) {
    $dir=Join-Path $Root $variant
    $logs=@()
    $configure=@('-S','.','-B',$dir,
      ("-DSWE_LIGAZE_WINDOWS_AB_VARIANT=$variant"),
      '-DBUILD_TESTING=ON')
    $out=@(& cmake @configure 2>&1 | ForEach-Object { [string]$_ })
    $configCode=$LASTEXITCODE
    $logs+=@($out)
    if($configCode -ne 0) { return [ordered]@{status='REJECTED_COMPILE';stage='configure';exit=$configCode;log=$logs} }
    $args=@('--build',$dir,'--config','Release','--parallel','2','--target',
       'pentagonal_ligaze_benchmark','pentagonal_ligaze_test','pentagonal_ligaze','pentagonal_platform_v2_contract_test')
    $out=@(& cmake @args 2>&1 | ForEach-Object { [string]$_ })
    $compileCode=$LASTEXITCODE
    $logs+=@($out)
    if($compileCode -ne 0) { return [ordered]@{status='REJECTED_COMPILE';stage='build';exit=$compileCode;log=$logs} }
    $out=@(& ctest --test-dir $dir -C Release -R ligaze --output-on-failure 2>&1 | ForEach-Object { [string]$_ })
    $testCode=$LASTEXITCODE
    $logs+=@($out)
    if($testCode -ne 0) { return [ordered]@{status='REJECTED_TEST';stage='ctest';exit=$testCode;log=$logs} }
    return [ordered]@{status='COMPILED_TESTED';stage='ctest';exit=0;log=$logs}
}
Require ($IsWindows -and $env:RUNNER_OS -ceq 'Windows') 'Only run on Windows runner with MSVC'
Require ($Iterations -gt 0 -and $Warmup -gt 0 -and $Repeats -ge 3 -and ($Repeats%2 -eq 1) -and $Trials -ge 3) 'Invalid protocol'
$commit=((& git rev-parse HEAD)|Out-String).Trim()
Require ($LASTEXITCODE -eq 0 -and $commit -match '^[0-9a-f]{40}$') 'Invalid Git commit'
Require (!$env:GITHUB_SHA -or $commit -ceq $env:GITHUB_SHA) 'Wrong Git SHA'
$compiler=((& cmake --version)|Select-Object -First 1)
$jvm=((& javac -version 2>&1)|Out-String).Trim()
Require ($LASTEXITCODE -eq 0 -and $jvm -match 'javac 17[.]') 'Requires JDK 17'
New-Item -ItemType Directory -Path $Evidence -Force | Out-Null
$variants=@('baseline','safe_header','full_header','ltcg','safe_header_ltcg','platform_v2','platform_v2_ltcg','full_header_v2')
$builds=[ordered]@{}
foreach($variant in $variants) {
    Write-Host "WINDOWS_AB|BUILD|$variant"
    $status=InvokeBuild $variant
    $path=Join-Path $Evidence ('build-'+$variant+'.log')
    $status.log | Set-Content -LiteralPath $path -Encoding utf8
    $builds[$variant]=[ordered]@{
        status=$status.status;stage=$status.stage;exit=$status.exit
        log_sha256=Hash $path
    }
    if($variant -eq 'baseline' -or $variant -eq 'ltcg') {
      Require ($status.status -ceq 'COMPILED_TESTED') 'Canonical native control must compile and pass'
    }
    # V2 no-op functions MUST fail the real Win32 API contract.
    if($variant -eq 'full_header_v2') {
      Require ($status.status -ceq 'REJECTED_COMPILE') 'Dangerous full v2 header unexpectedly passed the strict Win32 contract'
    }
    Write-Host "WINDOWS_AB|BUILD_RESULT|$variant|$($status.status)"
}
$javaDir=Join-Path $Root 'java'
New-Item -ItemType Directory -Path $javaDir -Force | Out-Null
& javac --release 17 -encoding UTF-8 -d $javaDir java/PentagonalControl.java java/LigazeJavaBenchmark.java
Require ($LASTEXITCODE -eq 0) 'Cannot compile Java baseline'
$javaRuns=@()
$paired=[ordered]@{}
foreach($variant in $variants) {
    if($variant -ceq 'baseline') {continue}
    $pairs=@()
    # Isolate the *incremental* effect of safe metadata from the
    # already-promoted LTCG optimization. Never credit LTCG to macros.
    $reference=if($variant -ceq 'platform_v2_ltcg') {'ltcg'} else {'baseline'}
    if($builds[$variant].status -ceq 'COMPILED_TESTED') {
        for($t=0;$t -lt $Trials;$t++) {
            # Alternate the run order within each paired experiment.
            if(($t%2) -eq 0) {
                $a=Sample (Program $reference)
                $b=Sample (Program $variant)
            } else {
                $b=Sample (Program $variant)
                $a=Sample (Program $reference)
            }
            Require ([string]$a.checksum -ceq [string]$b.checksum) "Different native checksum in $variant trial $t"
            $joutput=@(& java -cp $javaDir LigazeJavaBenchmark ([string]$Iterations) ([string]$Warmup) ([string]$Repeats))
            Require ($LASTEXITCODE -eq 0 -and $joutput.Count -gt 0) "Java failed in trial $t"
            $j=[string]$joutput[-1] | ConvertFrom-Json
            Require ([string]$a.checksum -ceq [string]$j.checksum) "Java/native checksum mismatch in $variant"
            $javaRuns+=@([ordered]@{candidate=$variant;trial=$t;java_ns=$j.median_ns_per_call;checksum=$j.checksum})
            $ratio=[double]$b.median_ns_per_call/[double]$a.median_ns_per_call
            $pairs+=@([ordered]@{
               trial=$t;order=if(($t%2) -eq 0){'baseline-candidate'}else{'candidate-baseline'}
               baseline_ns=$a.median_ns_per_call
               candidate_ns=$b.median_ns_per_call
               java_ns=$j.median_ns_per_call
               candidate_over_baseline=$ratio
               checksum=$a.checksum
            })
            Write-Host ("WINDOWS_AB|PAIR|$variant|trial=$t|baseline_ns=$($a.median_ns_per_call)|candidate_ns=$($b.median_ns_per_call)|candidate_over_baseline=$([math]::Round($ratio,4))")
        }
    }
    $ratios=@($pairs | ForEach-Object { [double]$_.candidate_over_baseline })
    $faster=0
    foreach($r in $ratios){if($r -le 0.95){$faster++}}
    $tested=($pairs.Count -eq $Trials)
    $acceptable=($tested -and $faster -eq $Trials -and $builds[$variant].status -ceq 'COMPILED_TESTED')
    # Full user-supplied Win32 no-op API shadows are NOT safe, even if fast.
    $safety=($variant -ne 'full_header' -and $variant -ne 'full_header_v2')
    $paired[$variant]=[ordered]@{
      compile_status=$builds[$variant].status
      comparison_reference=$reference
      pairs=$pairs
      speed_threshold='at least 5% faster in all 3 paired trials'
      speed_pass=($acceptable)
      safe_to_consider_for_promotion=($acceptable -and $safety)
      risk_note=if($safety){'No semantic WinAPI stubs in this variant'}else{'Variadic no-op shadow functions can silently intercept real Win32 calls: never promote'}
    }
}
$report=[ordered]@{
 schema='SWE-LIGAZE-WINDOWS-AB-v2'
 source_commit=$commit
 host_os='Windows Server MSVC hosted runner'
 cmake_version=$compiler
 java_version=$jvm
 iterations=$Iterations;warmup=$Warmup;repeats=$Repeats;trials=$Trials
 cxx_release_default_o2=$true
 candidates=$builds
 paired_comparison=$paired
 java_control_samples=$javaRuns
 v2_header_api_contract_expected_rejection=($builds['full_header_v2'].status -ceq 'REJECTED_COMPILE')
 no_op_shadows_prohibited_in_production=$true
 promoted_automatically=$false
 original_source_mutated=$false
}
$reportPath=Join-Path $Evidence 'windows-optimizer-ab.json'
$report|ConvertTo-Json -Depth 16|Set-Content -LiteralPath $reportPath -Encoding utf8
Write-Host "WINDOWS_AB|SUMMARY|PASS|tested=$($variants.Count)|sha256=$(Hash $reportPath)"
foreach($variant in $paired.Keys) {
   $p=$paired[$variant]
   Write-Host "WINDOWS_AB|DECISION|$variant|speed_pass=$($p.speed_pass)|safe_promotion=$($p.safe_to_consider_for_promotion)"
}
if($env:GITHUB_STEP_SUMMARY){
  @('## LIGAZE Windows compiler A/B',
    '',
    "- Git SHA: $commit",
    '- MSVC Release already uses /O2',
    '- Full requested header tested in isolation; no-op WinAPI shadow functions remain prohibited in production',
    '- Evidence: JSON artifact with all paired trials, CTest outcomes and compile errors',
    '- Rejected candidates remain historical evidence'
  ) | Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Encoding utf8
}
