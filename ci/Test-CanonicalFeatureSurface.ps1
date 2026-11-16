# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Source-of-truth acceptance tests. Original functions execute through the
# thin C++ bridge. This PowerShell file does not recreate the algorithms.
[CmdletBinding()]
param([string]$BuildDir='build-pxor')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$bin=if($IsWindows){'fastest_whisper_pxor_adapter.exe'}else{'fastest_whisper_pxor_adapter'}
$candidates=@(
  (Join-Path $root "$BuildDir/Release/$bin"),
  (Join-Path $root "$BuildDir/$bin")
)
$adapter=$candidates | Where-Object {Test-Path -LiteralPath $_ -PathType Leaf} | Select-Object -First 1
if(!$adapter){throw "Compiled canonical feature adapter missing: $bin"}
function Invoke-Canonical {
  param([string]$Mode,[string[]]$Values=@())
  $response=& $adapter $Mode @Values
  if($LASTEXITCODE -ne 0){throw "Canonical $Mode failed with code $LASTEXITCODE"}
  return ($response | ConvertFrom-Json)
}
function Assert-Close {
  param([double]$Actual,[double]$Expected,[double]$Tolerance=1e-12)
  if([double]::IsNaN($Actual) -or [Math]::Abs($Actual-$Expected) -gt $Tolerance){
    throw "Mismatch: actual $Actual, expected $Expected, tolerance $Tolerance"
  }
}
function Assert-Rejects {
  param([string]$Mode,[string[]]$Values)
  & $adapter $Mode @Values 2>$null | Out-Null
  if($LASTEXITCODE -eq 0){throw "Invalid $Mode unexpectedly succeeded"}
}
$p=Invoke-Canonical parity @('1','1','1','0','0')
Assert-Close $p.score 1
$s=Invoke-Canonical scores @('1','1','1','0','0')
Assert-Close $s.and 0
Assert-Close $s.or 1
Assert-Close $s.xor 1
Assert-Close $s.partial 1
Assert-Close $s.legacy_fifth_root 0
$s2=Invoke-Canonical scores @('1','1','1','1','1')
Assert-Close $s2.and 1
Assert-Close $s2.legacy_fifth_root 1
$r=Invoke-Canonical fifth-root @('-32')
Assert-Close $r.value (-2.0) 1e-10
Write-Host 'PASS original scores5, parity, partial, AND/OR and signed fifth root'

$g=Invoke-Canonical gain9dbi @('1')
if($g.domain -cne 'idealized-rf-eirp' -or !$g.admissible -or !$g.passed){
  throw 'The RF COREAO +9 dBi domain or audit is wrong.'
}
Assert-Close $g.gain_dbi 9
Assert-Close $g.gain_linear 7.943282347242816
Assert-Close $g.field_factor 2.8183829312644537
Assert-Close $g.input_watts 1
Assert-Close $g.output_eirp_watts 7.943282347242816
Assert-Close $g.recovered_input_watts 1
Assert-Close $g.normalized_residual 0
$g0=Invoke-Canonical gain9dbi @('0')
Assert-Close $g0.output_eirp_watts 0
Assert-Rejects gain9dbi @('-1')
Assert-Rejects gain9dbi @('1e308')
Write-Host 'PASS canonical COREAO +9 dBi RF/EIRP, zero, negative and overflow guards'

$d=Invoke-Canonical deca-sigma @('2')
if(!$d.returned -or $d.operations -cne 'RSRTRSRTRR' -or @($d.stages).Count -ne 11){
  throw 'DecaSigma canonical stages/return witness mismatch'
}
$t=Invoke-Canonical tri-pi @('2')
if(!$t.forward -or !$t.reverse -or !$t.zfold -or !$t.passed){
  throw 'TriPi three canonical route witnesses disagree'
}
$c=Invoke-Canonical coreao @('2')
if(!$c.admissible -or !$c.passed){throw 'Scalar COREAO inadmissible'}
Assert-Close $c.scalar 0
Assert-Rejects deca-sigma @('0')
Assert-Rejects coreao @('1')
Write-Host 'PASS original DecaSigma, all TriPi routes and scalar COREAO'

$st=Invoke-Canonical ligands @('0.5','0.5','0.5','0.5','0.5','0.5','0.5','0.5','0.5')
if($st.hexabyte -cne '008000800080' -or @($st.ring_u16).Count -ne 3){
  throw 'Original 10D six-byte Stability witness mismatch'
}
$measured=Invoke-Canonical measurements @('1024','0','0','0.5','0.5','1','1','64','64')
if(!$measured.admissible){throw 'Original Stability normalization rejected valid CORE'}
$stereo=Invoke-Canonical coreo-stereo @('1','-2','3','-4')
if(!$stereo.admissible -or $stereo.frames -ne 2 -or
   @($stereo.quad).Count -ne 2){
  throw 'Original stereo COREO was not exercised'
}
Assert-Close $stereo.largest_disagreement 0
$sourceSamples=[double[]]@(1,-2,3,-4)
for($i=0;$i -lt 4;$i++){
  Assert-Close $stereo.recovered[$i] $sourceSamples[$i]
}
Assert-Rejects coreo-stereo @('1','2','3')
Write-Host 'PASS original Stability-10D and reversible COREO stereo/Z-fold'

$target=Invoke-Canonical platform
if($target.windows -notin @(0,1) -or $target.android -notin @(0,1)){
  throw 'Platform compile target macros are malformed.'
}
Write-Host 'PASS original strict C API target macros and all public adapter modes.'
exit 0
