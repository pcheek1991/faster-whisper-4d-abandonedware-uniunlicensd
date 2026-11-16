# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Independent compatibility witnesses: compare native verbatim C++ with the
# *preexisting* PowerShell compatibility layer, do not recreate the math.
[CmdletBinding()]
param([string]$BuildDir = 'build-pxor')
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'Stability.ps1')
$binaryName = if ($IsWindows) { 'fastest_whisper_pxor_adapter.exe' } else { 'fastest_whisper_pxor_adapter' }
$candidates = @(
  (Join-Path $root "$BuildDir/Release/$binaryName"),
  (Join-Path $root "$BuildDir/$binaryName")
)
$adapter = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (!$adapter) { throw 'Canonical bridge binary missing; build the original CMake project first.' }
$inputs = @(
  [double[]]@(0,0,0,0,0,0,0,0,0),
  [double[]]@(1,1,1,1,1,1,1,1,1),
  [double[]]@(0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5),
  [double[]]@(0,0,0,1,0,0,0,0,0),
  [double[]]@(0.13,0.27,0.39,0.41,0.55,0.68,0.72,0.81,0.94)
)
$expectedHex = @('000000000000','ffffffffffff','008000800080','ffffffff0000',$null)
for ($i = 0; $i -lt $inputs.Count; ++$i) {
  $ligands = [double[]]$inputs[$i]
  $arguments = @('ligands') + @($ligands | ForEach-Object { $_.ToString('R',[Globalization.CultureInfo]::InvariantCulture) })
  $response = & $adapter @arguments
  if ($LASTEXITCODE -ne 0) { throw "Canonical bridge rejected vector $i" }
  $native = $response | ConvertFrom-Json
  $compat = Get-Stability10D -Ligands $ligands
  if ($native.hexabyte -cne $compat.hexabyte) { throw "Verbatim/compatibility hexabyte mismatch on case $i" }
  if ([Math]::Abs([double]$native.stability - [double]$compat.stability) -gt 1e-12) {
    throw "Verbatim/compatibility Stability mismatch on case $i"
  }
  if ($expectedHex[$i] -and $native.hexabyte -cne $expectedHex[$i]) {
    throw "Canonical original golden hex mismatch in case $i"
  }
  Write-Host "PASS bridge witness $i hex=$($native.hexabyte)"
}
Write-Host 'PASS canonical original upstream parity/Stability agrees with existing 10D compatibility witnesses.'
exit 0
