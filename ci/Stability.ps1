# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Stability v1: nine normalized ligands, three interlocked Pentagonal XOR rings.
# No model weights, no network calls, and no random seeds. PowerShell 7.
# Dot-source this file. It deliberately does not execute at import time.

Set-StrictMode -Version 2.0

function ConvertTo-StabilityLigands {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double[]] $Measurements
    )

    if ($Measurements.Count -ne 9) {
        throw 'Stability requires exactly nine original acoustic measurements.'
    }
    foreach ($value in $Measurements) {
        if ([double]::IsNaN($value) -or [double]::IsInfinity($value)) {
            throw 'Stability measurements must be finite.'
        }
    }

    # Source order: frame_count, mean_left, mean_right, rms_left,
    # rms_right, peak_left, peak_right, zero_crossings_left/right.
    $frames = $Measurements[0]
    if ($frames -lt 1.0 -or $frames -ne [Math]::Floor($frames)) {
        throw 'Frame count must be a positive integer.'
    }

    $ligands = [double[]]::new(9)
    $ligands[0] = $frames / ($frames + 1024.0)

    for ($i = 1; $i -le 2; $i++) {
        $mean = $Measurements[$i]
        $ligands[$i] = 0.5 * (1.0 + $mean / (1.0 + [Math]::Abs($mean)))
    }

    for ($i = 3; $i -le 6; $i++) {
        $value = $Measurements[$i]
        if ($value -lt 0.0) { throw 'RMS and peak measurements cannot be negative.' }
        $ligands[$i] = $value / (1.0 + $value)
    }

    $possibleTransitions = [Math]::Max(1.0, $frames - 1.0)
    for ($i = 7; $i -le 8; $i++) {
        $crossings = $Measurements[$i]
        if ($crossings -lt 0.0 -or $crossings -ne [Math]::Floor($crossings) -or
            $crossings -gt ($frames - 1.0)) {
            throw 'Zero-crossing counts must be integers between 0 and N-1.'
        }
        $ligands[$i] = $crossings / $possibleTransitions
    }

    foreach ($ligand in $ligands) {
        if ([double]::IsNaN($ligand) -or [double]::IsInfinity($ligand) -or
            $ligand -lt 0.0 -or $ligand -gt 1.0) {
            throw 'Normalization produced an inadmissible ligand.'
        }
    }
    return ,$ligands
}

function Get-Stability10D {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double[]] $Ligands
    )

    if ($Ligands.Count -ne 9) {
        throw 'Exactly nine normalized ligands are required.'
    }
    foreach ($ligand in $Ligands) {
        if ([double]::IsNaN($ligand) -or [double]::IsInfinity($ligand) -or
            $ligand -lt 0.0 -or $ligand -gt 1.0) {
            throw 'Normalized ligands must be finite values in [0,1].'
        }
    }

    # Three cyclic windows of five, shifting by three of nine positions:
    # ring 0 = (0,1,2,3,4)
    # ring 1 = (3,4,5,6,7)
    # ring 2 = (6,7,8,0,1)
    # Each pair overlaps in two ligands; no ligand belongs to all three.
    $rings = [double[]]::new(3)
    $words = [int[]]::new(3)
    $bytes = [byte[]]::new(6)
    for ($ring = 0; $ring -lt 3; $ring++) {
        $product = [double]1.0
        for ($offset = 0; $offset -lt 5; $offset++) {
            $index = (3 * $ring + $offset) % 9
            $product *= (1.0 - 2.0 * $Ligands[$index])
        }
        $p = 0.5 * (1.0 - $product)
        # Bounds defend against harmless floating-point overshoot.
        $p = [Math]::Max(0.0, [Math]::Min(1.0, $p))
        $rings[$ring] = $p

        # Uniform 16-bit unsigned quantization: nearest, ties upward.
        $word = [int][Math]::Floor($p * 65535.0 + 0.5)
        $words[$ring] = $word
        $bytes[2 * $ring] = [byte]($word -band 255)
        $bytes[2 * $ring + 1] = [byte](($word -shr 8) -band 255)
    }

    # One dimension summarizing agreement of three ring scores.
    # Interpret as *ring agreement*, not proof of real-world signal stability.
    $lowest = [Math]::Min($rings[0], [Math]::Min($rings[1], $rings[2]))
    $highest = [Math]::Max($rings[0], [Math]::Max($rings[1], $rings[2]))
    $stability = [Math]::Max(0.0, [Math]::Min(1.0, 1.0 - ($highest - $lowest)))

    return [pscustomobject]@{
        stability = [double]$stability
        ring_probabilities = $rings
        ring_u16 = $words
        hexabyte_bytes_le = $bytes
        hexabyte = [Convert]::ToHexString($bytes).ToLowerInvariant()
        protocol = 'Stability-9L3PX5-U16LE-v1'
    }
}
