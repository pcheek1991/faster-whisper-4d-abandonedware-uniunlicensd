# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Integration conformance: the default-on script must execute actual upstream
# operator binaries, not merely list mode names.
[CmdletBinding()]
param([string]$BuildDir='build-pxor')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$entry=Join-Path $root 'Invoke-PentagonalPipeline.ps1'
function Check([object]$json){
  $value=($json -join [Environment]::NewLine | ConvertFrom-Json)
  if($value.schema -cne 'SWE-Canonical-AllOn-Pipeline-v1'){throw 'Wrong pipeline schema.'}
  foreach($name in @('platform','rf_gain','stability','parity','scores5',
    'fifth_root','deca_sigma','tri_pi','coreao','coreo_stereo','metadata_guard')){
    if(!$value.results.PSObject.Properties[$name]){throw "Missing automatically executed $name"}
  }
  if(!$value.results.rf_gain.passed -or $value.is_trained_asr -or
     !$value.rf_gain_not_audio_gain){throw 'False gain or model provenance.'}
  return $value
}
function Near([double]$actual,[double]$expected,[double]$tol=1e-10){
  if([Math]::Abs($actual-$expected) -gt $tol){throw "Expected $expected, got $actual"}
}
# Zero switches: every original public computation runs on clearly marked
# reference fixtures; no physical RF/audio values silently invented.
$default=Check @(& $entry -BuildDir $BuildDir)
Near $default.results.rf_gain.gain_dbi 9
Near $default.results.rf_gain.output_eirp_watts 7.943282347242816
if(@($default.references_not_measurements).Count -lt 5 -or
   $default.results.metadata_guard.validated){
  throw 'Default reference inputs were incorrectly treated as real evidence.'
}
Write-Host 'PASS default-on, no switches: every operator executed, references identified.'

# Explicit option and single numeric piped gain both change gain without
# selecting individual operator modes. The original +9 result is retained.
$eleven=Check @(& $entry -BuildDir $BuildDir -Watts 1 -GainDbi 11)
Near $eleven.results.rf_gain.gain_dbi 11
Near $eleven.results.rf_gain.output_eirp_watts ([Math]::Pow(10.0,1.1))
Near $eleven.results.rf_gain.canonical_9dbi_eirp_watts 7.943282347242816
if($eleven.results.rf_gain.model -cne 'downstream-rf-dbi-offset-v1'){
  throw 'The parameterized +11 dBi calculation was mislabeled as upstream.'
}
$piped=Check @(11 | & $entry -BuildDir $BuildDir -Watts 1 -GainDbi 7)
Near $piped.results.rf_gain.gain_dbi 11
Write-Host 'PASS +9 dBi default, +11 dBi explicit and numeric pipe, precedence.'

# Native process directly accepts the requested gain from stdin.
$binary=if($IsWindows){'fastest_whisper_pxor_adapter.exe'}else{'fastest_whisper_pxor_adapter'}
$adapter=@((Join-Path $root "$BuildDir/Release/$binary"),
  (Join-Path $root "$BuildDir/$binary")) |
  Where-Object {Test-Path -LiteralPath $_ -PathType Leaf} | Select-Object -First 1
if(!$adapter){throw 'Native adapter not built.'}
$native=@('11' | & $adapter gain 1 '-')
if($LASTEXITCODE -ne 0){throw 'Native scalar stdin override failed.'}
$n=$native -join [Environment]::NewLine | ConvertFrom-Json
Near $n.gain_dbi 11
Near $n.output_eirp_watts ([Math]::Pow(10.0,1.1))
Write-Host 'PASS native gain override via standard-input pipe.'

# Fully populated record runs all applicable original algorithms with real
# *supplied* source operands. No debug or third-party model download.
$metadata=@{url='https://simpwellx.com/';path='public/downloads/color.svg';
  sha256=('a'*64);artifact='artifact.tar.gz'}
$inputRecord=@{
  gain_dbi=11;watts=1
  features=@(1,1,1,0,0)
  measurements=@(1024,0,0,0.5,0.5,1,1,64,64)
  deca_input=2;fifth_root_input=-32;stereo=@(1,-2,3,-4)
  metadata=$metadata
}
$all=Check @($inputRecord | & $entry -BuildDir $BuildDir)
if(!$all.results.metadata_guard.validated -or
  $all.results.stability.input_origin -cne 'supplied_measurements'){
  throw 'Supplied metadata and source measurements were not honored.'
}
Near $all.results.scores5.xor 1
Near $all.results.coreo_stereo.largest_disagreement 0
$jsonLine=$inputRecord | ConvertTo-Json -Depth 10 -Compress
$jsonReport=Check @($jsonLine | & $entry -BuildDir $BuildDir -GainDbi 7)
Near $jsonReport.results.rf_gain.gain_dbi 11
Write-Host 'PASS full structured PowerShell and JSONL record, five-channel metadata guard.'

# Do not permit a security veto, malformed power, invalid scalar, or
# unverifiable source input to be turned into a successful JSON output.
$denied=$false
try{
  $bad=@{watts=1;metadata=@{url='https://evil.example/';path='x';
    sha256=('a'*64);artifact='a.zip'}}
  $null=& $entry -InputObject $bad -BuildDir $BuildDir
}catch{$denied=$true}
if(!$denied){throw 'Untrusted release metadata bypassed the original AND guard.'}
$denied=$false
try{$null=& $entry -BuildDir $BuildDir -GainDbi 101}catch{$denied=$true}
if(!$denied){throw 'Invalid gain override did not fail closed.'}

# A raw wave file uses original 10D measurements and preserves its SHA256.
$temp=Join-Path ([IO.Path]::GetTempPath()) ('swe-pxor-'+[guid]::NewGuid().ToString('N')+'.raw')
try{
  $samples=[float[]]@(1,10,2,20,3,30)
  $bytes=[byte[]]::new($samples.Length*4)
  for($i=0;$i -lt $samples.Length;$i++){
    [BitConverter]::GetBytes($samples[$i]).CopyTo($bytes,4*$i)
  }
  [IO.File]::WriteAllBytes($temp,$bytes)
  $audio=Check @(& $entry -RawStereoFloat32Path $temp -BuildDir $BuildDir)
  if($audio.results.stability.input_origin -cne 'measured_from_raw_stereo' -or
    $audio.results.stability.source_sha256 -cne
    (Get-FileHash -LiteralPath $temp -Algorithm SHA256).Hash.ToLowerInvariant()){
    throw 'Original acoustic CORE and source SHA256 not retained.'
  }
}finally{Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue}
Write-Host 'PASS raw audio 10D source, malformed input fail closed, zero model weights.'
exit 0
