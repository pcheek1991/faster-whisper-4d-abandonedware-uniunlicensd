# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# All-on source-of-truth pipeline: orchestration only, not new math.
[CmdletBinding()]
param(
  [Parameter(ValueFromPipeline=$true)][AllowNull()][object]$InputObject,
  [Nullable[double]]$GainDbi,
  [Nullable[double]]$Watts,
  [string]$RawStereoFloat32Path,
  [string]$BuildDir='build-pxor'
)
begin {
  Set-StrictMode -Version 2.0
  $ErrorActionPreference='Stop'
  $root=[IO.Path]::GetFullPath($PSScriptRoot)
  $exe=if($IsWindows){'fastest_whisper_pxor_adapter.exe'}else{'fastest_whisper_pxor_adapter'}
  $guardExe=if($IsWindows){'swe_guard.exe'}else{'swe_guard'}
  $adapter=@((Join-Path $root "$BuildDir/Release/$exe"),(Join-Path $root "$BuildDir/$exe"),(Join-Path $root $exe)) |
    Where-Object {Test-Path -LiteralPath $_ -PathType Leaf} | Select-Object -First 1
  $guard=@((Join-Path $root "$BuildDir/canonical-guard/Release/$guardExe"),
           (Join-Path $root "$BuildDir/canonical-guard/$guardExe"),(Join-Path $root $guardExe)) |
    Where-Object {Test-Path -LiteralPath $_ -PathType Leaf} | Select-Object -First 1
  if(!$adapter -or !$guard) {
    throw 'Build the canonical C++20/C11 submodule first: git submodule update --init --recursive; cmake -S . -B build-pxor; cmake --build build-pxor --config Release'
  }
  $seen=$false
  $hasGain=$PSBoundParameters.ContainsKey('GainDbi')
  $hasWatts=$PSBoundParameters.ContainsKey('Watts')
  $hasRaw=$PSBoundParameters.ContainsKey('RawStereoFloat32Path')
  $culture=[Globalization.CultureInfo]::InvariantCulture
  function Finite([object]$v,[string]$field) {
    if($null -eq $v -or $v -is [bool]){throw "Invalid $field"}
    $n=[double]0
    if(![double]::TryParse([string]$v,[Globalization.NumberStyles]::Float,
      $culture,[ref]$n) -or [double]::IsNaN($n) -or [double]::IsInfinity($n)){
      throw ("Invalid {0}: expected finite numeric value." -f $field)
    }
    return $n
  }
  function Vector([object]$v,[string]$field,[int]$required) {
    if($v -is [string] -or $v -isnot [Collections.IEnumerable]){
      throw "Expected array: $field"
    }
    $a=@($v)
    if(($required -gt 0 -and $a.Count -ne $required) -or
      ($required -eq 0 -and ($a.Count -lt 2 -or ($a.Count%2) -ne 0 -or $a.Count -gt 8192))){
      throw "Invalid $field vector length: $($a.Count)"
    }
    return ,([double[]]@($a | ForEach-Object {Finite $_ $field}))
  }
  function Invariant([double[]]$a){
    return ,([string[]]@($a | ForEach-Object {$_.ToString('R',$culture)}))
  }
  function Native([string]$mode,[string[]]$argsList){
    $response=@(& $adapter $mode @argsList)
    if($LASTEXITCODE -ne 0){throw "Canonical operator $mode rejected values (exit $LASTEXITCODE)."}
    return (ConvertFrom-Json -InputObject ($response -join [Environment]::NewLine) -AsHashtable -Depth 20)
  }
  function AsRecord([AllowNull()][object]$v){
    if($null -eq $v){return @{}}
    if($v -is [string]){
      $text=$v.Trim()
      if($text.StartsWith('{')){
        $r=ConvertFrom-Json -InputObject $text -AsHashtable -Depth 20
        if($r -isnot [Collections.IDictionary]){throw 'Expected one JSON object.'}
        return $r
      }
      return @{gain_dbi=(Finite $text 'piped gain_dbi')}
    }
    if($v -is [ValueType]){return @{gain_dbi=(Finite $v 'piped gain_dbi')}}
    if($v -is [Collections.IDictionary]){return $v}
    return (ConvertFrom-Json -InputObject ($v | ConvertTo-Json -Depth 20) -AsHashtable -Depth 20)
  }
  function Run([AllowNull()][object]$source) {
    $r=AsRecord $source
    $fixtures=[Collections.Generic.List[string]]::new()
    # Input overrides CLI, CLI overrides +9 dBi default.
    $g=if($r.Contains('gain_dbi')){Finite $r['gain_dbi'] 'gain_dbi'}
       elseif($hasGain){Finite $GainDbi 'GainDbi'}else{9.0}
    if($g -lt -100 -or $g -gt 100){throw 'Gain dBi outside [-100,100]'}
    $w=if($r.Contains('watts')){Finite $r['watts'] 'watts'}
       elseif($hasWatts){Finite $Watts 'Watts'}else{
         $fixtures.Add('watts=1 W reference, not measured RF power')
         1.0
       }
    $raw=if($r.Contains('raw_stereo_float32_path')){[string]$r['raw_stereo_float32_path']}
         elseif($hasRaw){$RawStereoFloat32Path}else{$null}
    if($raw -and ($r.Contains('measurements') -or $r.Contains('ligands'))){
      throw 'Conflicting raw-stereo and explicit measurement fields.'
    }
    $analysis=$null
    if($raw){
      $rawJson=@(& (Join-Path $root 'ci/Measure-10D.ps1') -RawStereoFloat32Path $raw)
      if(!$?){throw 'Input measurement failed.'}
      $analysis=ConvertFrom-Json -InputObject ($rawJson -join [Environment]::NewLine) -AsHashtable -Depth 20
      if(@($analysis.vector).Count -ne 10){throw 'Malformed source acoustic vector.'}
    }
    $out=[ordered]@{}
    $out.platform=Native 'platform' @()
    $out.rf_gain=Native 'gain' (Invariant ([double[]]@($w,$g)))
    $out.rf_gain.input_origin=if($r.Contains('watts') -or $hasWatts){'supplied_watts'}else{'reference_watts'}
    $out.rf_gain.audio_gain_applied=$false
    if($r.Contains('measurements')){
      $out.stability=Native 'measurements' (Invariant (Vector $r['measurements'] 'measurements' 9))
      $out.stability.input_origin='supplied_measurements'
    }elseif($r.Contains('ligands')){
      $out.stability=Native 'ligands' (Invariant (Vector $r['ligands'] 'ligands' 9))
      $out.stability.input_origin='supplied_ligands'
    }elseif($analysis){
      $out.stability=Native 'measurements' (Invariant ([double[]]@($analysis.vector[0..8])))
      $out.stability.input_origin='measured_from_raw_stereo'
      $out.stability.source_sha256=$analysis.input_sha256
      $out.stability.pearson_diagnostic=$analysis.diagnostics.legacy_pearson_lr
    }else{
      $fixtures.Add('stability=9 half-ligand reference')
      $out.stability=Native 'ligands' (Invariant ([double[]]@(0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5)))
      $out.stability.input_origin='reference_fixture'
    }
    $f=if($r.Contains('features')){Vector $r['features'] 'features' 5}
       else{[double[]]@($out.stability.ligands[0..4])}
    $origin=if($r.Contains('features')){'supplied_features'}else{'derived_from_canonical_stability_ligands'}
    $out.parity=Native 'parity' (Invariant $f)
    $out.parity.input_origin=$origin
    $out.scores5=Native 'scores' (Invariant $f)
    $out.scores5.input_origin=$origin
    $fifth=if($r.Contains('fifth_root_input')){Finite $r['fifth_root_input'] 'fifth_root_input'}
           else{$fixtures.Add('fifth_root_input=-32 reference');-32.0}
    $out.fifth_root=Native 'fifth-root' (Invariant ([double[]]@($fifth)))
    $out.fifth_root.input_origin=if($r.Contains('fifth_root_input')){'supplied'}else{'reference_fixture'}
    $d=if($r.Contains('deca_input')){Finite $r['deca_input'] 'deca_input'}
       else{$fixtures.Add('deca_input=2 reference');2.0}
    $dArgs=Invariant ([double[]]@($d))
    $out.deca_sigma=Native 'deca-sigma' $dArgs
    $out.tri_pi=Native 'tri-pi' $dArgs
    $out.coreao=Native 'coreao' $dArgs
    $dOrigin=if($r.Contains('deca_input')){'supplied'}else{'reference_fixture'}
    foreach($key in @('deca_sigma','tri_pi','coreao')){$out[$key].input_origin=$dOrigin}
    $samples=if($r.Contains('stereo')){Vector $r['stereo'] 'stereo' 0}
             else{$fixtures.Add('stereo=[1,-2,3,-4] reference');[double[]]@(1,-2,3,-4)}
    $out.coreo_stereo=Native 'coreo-stereo' (Invariant $samples)
    $out.coreo_stereo.input_origin=if($r.Contains('stereo')){'supplied'}else{'reference_fixture'}
    if($r.Contains('metadata')){
      $m=$r['metadata']
      if($m -isnot [Collections.IDictionary]){throw 'metadata must be a JSON object.'}
      foreach($k in @('url','path','sha256','artifact')){
        if(!$m.Contains($k) -or [string]::IsNullOrWhiteSpace([string]$m[$k])){
          throw "Missing trust-guard metadata field $k"
        }
      }
      $guardLog=@(& $guard ([string]$m['url']) ([string]$m['path']) ([string]$m['sha256']) ([string]$m['artifact']))
      if($LASTEXITCODE -ne 0){throw "Original five-channel AND guard REJECTED metadata: $($guardLog -join '; ')"}
      $out.metadata_guard=[ordered]@{validated=$true;decision='passed_all_five';original_output=$guardLog}
    }else{
      $guardLog=@(& $guard '--self-test')
      if($LASTEXITCODE -ne 0){throw 'Original metadata guard self-test failed.'}
      $fixtures.Add('metadata guard self-test only, no real metadata validated')
      $out.metadata_guard=[ordered]@{validated=$false;decision='self_test_only';original_output=$guardLog}
    }
    # Original counterarccosine research lives in upstream CTest, not a
    # callable production function. Never invent an alternate algorithm.
    [ordered]@{
      schema='SWE-Canonical-AllOn-Pipeline-v1'
      original_source='Simply-Well-Executed/pentagonal-xor-cpp20'
      original_source_sha='fb23b40480476c98e992762ace37761b6fd8ba0e'
      enabled_by_default=$true
      references_not_measurements=@($fixtures.ToArray())
      raw_input_path=if($raw){[IO.Path]::GetFullPath($raw)}else{$null}
      is_trained_asr=$false
      rf_gain_not_audio_gain=$true
      counterarccosine='upstream CTest research witness; no runtime API'
      results=$out
    } | ConvertTo-Json -Depth 20 -Compress
  }
}
process {
  if($null -ne $InputObject){$seen=$true;Run $InputObject}
}
end {
  # Native pwsh -File with redirected stdin may not bind pipe objects.
  if(!$seen -and [Console]::IsInputRedirected){
    while($null -ne ($line=[Console]::In.ReadLine())){
      if($line.Trim() -ne ''){$seen=$true;Run $line}
    }
  }
  if(!$seen){Run $null}
  $global:LASTEXITCODE=0
}
