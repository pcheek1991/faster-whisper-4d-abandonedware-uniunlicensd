# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# The current branch may not build through retired source/build layers.
[CmdletBinding()]param()
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$paths=@(& git -C $root ls-files)
if($LASTEXITCODE -ne 0){throw 'Unable to enumerate tracked source.'}
$forbidden=@($paths | Where-Object {
  $_ -match '(?i)\.py$|(^|/)requirements[^/]*\.txt$|(^|/)setup\.(py|cfg)$|(^|/)pyproject\.toml$|(^|/)MANIFEST\.in$|(^|/)(gradlew(\.bat)?|gradle\.properties|settings\.gradle(\.kts)?|build\.gradle(\.kts)?)$|(^|/)gradle/|^android/.*\.java$'
})
if($forbidden.Count -gt 0){
  throw ('Retired source/build paths remain in CURRENT: '+($forbidden -join ', '))
}
foreach($file in @('LICENSE-ISC-WIKIPEDIA-DATA',
  'data/wikimedia-languages.json','native/wikimedia_languages.inc',
  'native/diamond.cpp','native/acoustic.cpp','native/word_bridges.hpp',
  'ci/Build-NativeAndroid.ps1')){
  if(!(Test-Path -LiteralPath (Join-Path $root $file) -PathType Leaf)){
    throw "Required native-source or source-license record missing: $file"
  }
}
$docFiles=@($paths | Where-Object {$_ -match '(?i)\.(md|rst)$'})
foreach($p in $docFiles){
  $body=Get-Content -LiteralPath (Join-Path $root $p) -Raw
  if($body -match '(?i)\bpython(?:3)?\b|\bpip(?:3)?\b|\bpytest\b|\bgradle\b|\bsetup\.py\b'){
    throw "Current documentation still names a retired runtime/tool: $p"
  }
}
# This check intentionally excludes the immutable historical Git submodule,
# whose original source and license cannot be silently rewritten.
Write-Host ("PASS: {0} native tracked paths, current docs and license provenance." -f $paths.Count)
exit 0
