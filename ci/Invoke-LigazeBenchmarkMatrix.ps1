# SPDX-License-Identifier: 0BSD
# PowerShell 7 matrix benchmark: Windows, macOS, openSUSE container.
# All measurements use the same COR checks and pseudorandom input stream.
[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet('Windows','macOS','openSUSE')]
  [string]$Platform,
  [int]$Iterations=500000,
  [int]$Warmup=50000,
  [int]$Repeats=5,
  [string]$BuildDir='build-ligaze-matrix',
  [string]$EvidenceDir='evidence-ligaze-matrix'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Ensure([bool]$yes,[string]$message) {
    if(-not $yes){ throw "LIGAZE_MATRIX_$($Platform): $message" }
}
function Hash([string]$path) {
    Ensure (Test-Path -LiteralPath $path -PathType Leaf) "Missing file $path"
    return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function InvokeChecked([string]$command,[string[]]$arguments) {
    & $command @arguments
    Ensure ($LASTEXITCODE -eq 0) "$command returned code $LASTEXITCODE"
}
function InvokeJson([string]$command,[string[]]$arguments) {
    $lines=@(& $command @arguments)
    Ensure ($LASTEXITCODE -eq 0 -and $lines.Count -ge 1) "$command benchmark failed"
    return ([string]$lines[-1] | ConvertFrom-Json)
}
$commit=((& git rev-parse HEAD) | Out-String).Trim()
Ensure ($LASTEXITCODE -eq 0 -and $commit -match '^[0-9a-f]{40}$') 'No exact Git commit'
if($env:GITHUB_SHA){ Ensure ($commit -ceq $env:GITHUB_SHA) 'Checkout does not match GitHub SHA' }
Ensure ($Iterations -gt 0 -and $Warmup -gt 0 -and $Repeats -ge 3 -and ($Repeats%2) -eq 1) 'Require positive sample counts and odd repeats >=3'
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $BuildDir 'java-classes') -Force | Out-Null
$dockerImage=''
$engine='native-host'
$javaClassPath=Join-Path $BuildDir 'java-classes'
$native=''

if($Platform -eq 'openSUSE') {
    Ensure ($env:RUNNER_OS -eq 'Linux') 'openSUSE container requires Linux Docker host'
    $dockerImage='swe-ligaze-matrix:'+($commit.Substring(0,12).ToLowerInvariant())
    InvokeChecked 'docker' @('build','--file','ci/opensuse-benchmark.Dockerfile',
                              '--tag',$dockerImage,'.')
    $workspace=(Get-Location).Path
    $mount=$workspace+':/work'
    $base=@('run','--rm','--network','none','--volume',$mount,'--workdir','/work',$dockerImage)
    InvokeChecked 'docker' ($base+@('cmake','-S','.','-B',$BuildDir,
                                    '-DCMAKE_BUILD_TYPE=Release','-DBUILD_TESTING=ON'))
    InvokeChecked 'docker' ($base+@('cmake','--build',$BuildDir,'--config','Release',
           '--parallel','2','--target','pentagonal_ligaze_benchmark','pentagonal_ligaze_test','pentagonal_ligaze'))
    InvokeChecked 'docker' ($base+@('ctest','--test-dir',$BuildDir,'-C','Release',
           '-R','ligaze','--output-on-failure'))
    InvokeChecked 'docker' ($base+@('javac','--release','17','-encoding','UTF-8','-d',$javaClassPath,
                                    'java/PentagonalControl.java','java/LigazeJavaBenchmark.java'))
    $native=Join-Path $BuildDir 'pentagonal_ligaze_benchmark'
    $nativeResults=InvokeJson 'docker' ($base+@($native,
                [string]$Iterations,[string]$Warmup,[string]$Repeats))
    $javaResults=InvokeJson 'docker' ($base+@('java','-cp',$javaClassPath,
                'LigazeJavaBenchmark',[string]$Iterations,[string]$Warmup,[string]$Repeats))
    $engine='openSUSE-container-on-ubuntu-host'
} else {
    # JDK 17 selection occurs in the GitHub Actions job before this script.
    InvokeChecked 'cmake' @('-S','.','-B',$BuildDir,'-DCMAKE_BUILD_TYPE=Release','-DBUILD_TESTING=ON')
    InvokeChecked 'cmake' @('--build',$BuildDir,'--config','Release','--parallel','2',
             '--target','pentagonal_ligaze_benchmark','pentagonal_ligaze_test','pentagonal_ligaze')
    InvokeChecked 'ctest' @('--test-dir',$BuildDir,'-C','Release','-R','ligaze','--output-on-failure')
    InvokeChecked 'javac' @('--release','17','-encoding','UTF-8','-d',$javaClassPath,
                             'java/PentagonalControl.java','java/LigazeJavaBenchmark.java')
    $ext=if($IsWindows){'.exe'}else{''}
    $native=Join-Path $BuildDir ('pentagonal_ligaze_benchmark'+$ext)
    if(!(Test-Path -LiteralPath $native)){
       $native=Join-Path (Join-Path $BuildDir 'Release') ('pentagonal_ligaze_benchmark'+$ext)
    }
    Ensure (Test-Path -LiteralPath $native -PathType Leaf) 'Native benchmark binary missing'
    $nativeResults=InvokeJson $native @([string]$Iterations,[string]$Warmup,[string]$Repeats)
    $javaResults=InvokeJson 'java' @('-cp',$javaClassPath,'LigazeJavaBenchmark',
                                    [string]$Iterations,[string]$Warmup,[string]$Repeats)
}
foreach($result in @($nativeResults,$javaResults)){
    Ensure ($result.schema -ceq 'SWE-LIGAZE-BENCH-v1') 'Benchmark protocol mismatch'
    Ensure ($result.iterations -eq $Iterations -and $result.warmup -eq $Warmup -and $result.repeats -eq $Repeats) 'Unequal workload'
    Ensure ($result.median_ns_per_call -gt 0 -and $result.threat_fixtures -ceq 'PASS') 'Invalid measurement or threat fixtures'
    Ensure ($result.same_inputs_and_expected_fixture -eq $true -and $result.external_authentication -eq $false) 'Invalid source/reliability claim'
}
Ensure ($nativeResults.runtime -ceq 'native-cxx20' -and $javaResults.runtime -ceq 'java17-hotspot') 'Wrong runtime identities'
Ensure ([string]$nativeResults.checksum -ceq [string]$javaResults.checksum) 'Native and Java semantic checksums disagree'
$ratio=[double]$javaResults.median_ns_per_call/[double]$nativeResults.median_ns_per_call
$bench=[ordered]@{
    schema='SWE-COR-THREAT-BENCH-MATRIX-v1'
    git_sha=$commit
    platform=$Platform
    execution_environment=$engine
    host_platform=$env:RUNNER_OS
    host_arch=$env:RUNNER_ARCH
    iterations=$Iterations
    warmup=$Warmup
    repeats=$Repeats
    native=$nativeResults
    java=$javaResults
    java_over_native_ns_ratio=$ratio
    checksum_equal=$true
    threat_tests_passed=$true
    witness_external_authentication=$false
    system_kernel_same_as_openSUSE_container_host=($Platform -eq 'openSUSE')
    source_mutated=$false
    method_notes='Correlated views; benchmark compares one COR operation plus gate checks, not a hardware instruction or authenticated evidence. Cross-runner timing is not controlled.'
    sha256_native_binary=Hash $native
    sha256_native_source=Hash $(if(Test-Path 'benchmarks/pentagonal_ligaze_benchmark.cpp'){'benchmarks/pentagonal_ligaze_benchmark.cpp'}else{'native/benchmarks/pentagonal_ligaze_benchmark.cpp'})
    sha256_java_source=Hash 'java/LigazeJavaBenchmark.java'
}
$path=Join-Path $EvidenceDir ('ligaze-'+$Platform.ToLowerInvariant()+'.json')
$bench|ConvertTo-Json -Depth 10|Set-Content -LiteralPath $path -Encoding utf8
Write-Host ('LIGAZE_MATRIX|PASS|platform='+$Platform+
 '|native_ns='+$nativeResults.median_ns_per_call+
 '|java_ns='+$javaResults.median_ns_per_call+
 '|java_over_native='+([math]::Round($ratio,4))+
 '|checksum='+$nativeResults.checksum)
if($env:GITHUB_STEP_SUMMARY){
    @("### LIGAZE COR benchmark: $Platform",'',
     "- Environment: $engine",
     "- Native median ns/COR operation: $($nativeResults.median_ns_per_call)",
     "- Java median ns/COR operation: $($javaResults.median_ns_per_call)",
     "- Java/native ratio: $([math]::Round($ratio,4))",
     "- Repeated samples: $Repeats, measured iterations/sample: $Iterations",
     "- Same semantic checksum: $($nativeResults.checksum)",
     "- Exact Git SHA: $commit",
     '- Correlated inputs and self-supplied expected mask do not prove data authentication',
     '- Measurements are runner-specific, not cross-OS controlled hardware comparisons'
    )|Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Encoding utf8
}
