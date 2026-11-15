# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Independent Checkpoint 10 Stability verification; no models or recordings.
[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Stability.ps1')

function Assert-Near([double]$actual,[double]$expected,[string]$label) {
    if ([Math]::Abs($actual - $expected) -gt 1.0e-12) {
        throw "$label differs: $actual vs $expected"
    }
}

# Slow, independent reference: sum all 16 odd-parity minterms of a ring.
# This implementation deliberately does not use the production product formula.
function Get-MintermReference([double[]]$ligands,[int[]]$indices) {
    $total = [double]0.0
    for ($mask = 0; $mask -lt 32; $mask++) {
        $bits = 0
        for ($i = 0; $i -lt 5; $i++) {
            if (($mask -band (1 -shl $i)) -ne 0) { $bits++ }
        }
        if (($bits % 2) -eq 0) { continue }

        $product = [double]1.0
        for ($i = 0; $i -lt 5; $i++) {
            $v = $ligands[$indices[$i]]
            if (($mask -band (1 -shl $i)) -ne 0) { $product *= $v }
            else { $product *= (1.0 - $v) }
        }
        $total += $product
    }
    return $total
}

$zero = Get-Stability10D -Ligands ([double[]]@(0,0,0,0,0,0,0,0,0))
if ($zero.hexabyte -cne '000000000000' -or $zero.stability -ne 1.0) {
    throw 'Zero-ligand exact golden vector failed.'
}
$one = Get-Stability10D -Ligands ([double[]]@(1,1,1,1,1,1,1,1,1))
if ($one.hexabyte -cne 'ffffffffffff' -or $one.stability -ne 1.0) {
    throw 'One-ligand exact golden vector failed.'
}
$half = Get-Stability10D -Ligands ([double[]]@(0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5))
if ($half.hexabyte -cne '008000800080' -or $half.stability -ne 1.0) {
    throw 'Half-ligand quantization golden vector failed.'
}
$overlap = Get-Stability10D -Ligands ([double[]]@(0,0,0,1,0,0,0,0,0))
if ($overlap.hexabyte -cne 'ffffffff0000' -or $overlap.stability -ne 0.0) {
    throw 'Interlocked ring overlap golden vector failed.'
}

$ligands = [double[]]@(0.10,0.23,0.31,0.47,0.56,0.69,0.72,0.83,0.95)
$copy = [double[]]$ligands.Clone()
$result = Get-Stability10D -Ligands $ligands
$groups = @(
    [int[]]@(0,1,2,3,4),
    [int[]]@(3,4,5,6,7),
    [int[]]@(6,7,8,0,1)
)
for ($j = 0; $j -lt 3; $j++) {
    $expected = Get-MintermReference -ligands $ligands -indices $groups[$j]
    Assert-Near $result.ring_probabilities[$j] $expected "ring $j"
    $word = [int][Math]::Floor($expected * 65535.0 + 0.5)
    if ($result.ring_u16[$j] -ne $word) { throw "Quantization mismatch in ring $j." }
    if ($result.hexabyte_bytes_le[2*$j] -ne ($word -band 255) -or
        $result.hexabyte_bytes_le[2*$j+1] -ne (($word -shr 8) -band 255)) {
        throw "Little-endian witness mismatch in ring $j."
    }
}
$expectedStability = 1.0 - (
    ($result.ring_probabilities | Measure-Object -Maximum).Maximum -
    ($result.ring_probabilities | Measure-Object -Minimum).Minimum
)
Assert-Near $result.stability $expectedStability 'Stability scalar'
for ($i = 0; $i -lt 9; $i++) {
    if ($ligands[$i] -ne $copy[$i]) { throw 'Input ligands were mutated.' }
}

# Normalization uses the original nine acoustic measurements in unchanged order.
$measurements = [double[]]@(3,2,20,[Math]::Sqrt(14.0/3.0),
    [Math]::Sqrt(1400.0/3.0),3,30,0,0)
$normalized = ConvertTo-StabilityLigands -Measurements $measurements
if ($normalized.Count -ne 9) { throw 'Ligand normalization lost a dimension.' }
Assert-Near $normalized[0] (3.0/1027.0) 'count normalization'
Assert-Near $normalized[1] (0.5*(1.0+2.0/3.0)) 'mean normalization'
Assert-Near $normalized[7] 0.0 'crossings normalization'

$badCases = @(
    [double[]]@(0,0),
    [double[]]@(0,0,0,0,0,0,0,0,[double]::NaN),
    [double[]]@(0,0,0,0,0,0,0,0,1.1),
    [double[]]@(0,0,0,0,0,0,0,0,-0.1)
)
foreach ($bad in $badCases) {
    $rejected = $false
    try { $null = Get-Stability10D -Ligands $bad } catch { $rejected = $true }
    if (!$rejected) { throw 'Invalid ligand input was accepted.' }
}

Write-Output 'PASS Stability: three interlocked Pentagonal XOR rings, nine ligands, six bytes'
Write-Output 'PASS exact golden hexabytes, independent odd-minterm reference, input guards'
