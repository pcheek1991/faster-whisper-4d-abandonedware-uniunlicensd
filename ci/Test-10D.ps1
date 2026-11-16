# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Verify no-weight 10D acoustic signatures using synthetic vectors only.
[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$main = Join-Path $root 'Fastest-Whisper-10D.ps1'
$temp = Join-Path ([IO.Path]::GetTempPath()) ('fastest-whisper-10d-' + [guid]::NewGuid().ToString('N') + '.raw')
try {
    $samples = [float[]]@(1,10,2,20,3,30)
    $bytes = [byte[]]::new($samples.Length * 4)
    for ($i = 0; $i -lt $samples.Length; $i++) {
        [BitConverter]::GetBytes($samples[$i]).CopyTo($bytes, 4*$i)
    }
    [IO.File]::WriteAllBytes($temp, $bytes)
    $reportJson = & $main -Analyze10D -RawStereoFloat32Path $temp
    $record = ($reportJson -join [Environment]::NewLine) | ConvertFrom-Json
    if ($record.trained_model_used -ne $false -or $record.transcript_generated -ne $false) {
        throw '10D falsely claims a model or transcript.'
    }
    if ($record.dimensions.Count -ne 10 -or $record.vector.Count -ne 10) {
        throw 'Exactly ten dimensions are required.'
    }

    $tolerance = 0.00001
    function Assert-Near([double]$actual,[double]$expected,[string]$field) {
        if ([Math]::Abs($actual-$expected) -gt $tolerance) {
            throw "$field differs: $actual vs $expected"
        }
    }
    Assert-Near $record.vector[0] 3 'frame count'
    Assert-Near $record.vector[1] 2 'mean left'
    Assert-Near $record.vector[2] 20 'mean right'
    Assert-Near $record.vector[3] ([Math]::Sqrt(14.0/3.0)) 'RMS left'
    Assert-Near $record.vector[4] ([Math]::Sqrt(1400.0/3.0)) 'RMS right'
    Assert-Near $record.vector[5] 3 'peak left'
    Assert-Near $record.vector[6] 30 'peak right'
    Assert-Near $record.vector[7] 0 'zero crossings left'
    Assert-Near $record.vector[8] 0 'zero crossings right'
    if ($record.dimensions[9] -cne 'Stability' -or
        $record.schema -cne 'Fastest-Whisper-10D-acoustic-v2-Stability') {
        throw 'Tenth output dimension is not Stability.'
    }
    if ($record.Stability.protocol -cne 'Stability-9L3PX5-U16LE-v1' -or
        $record.Stability.normalized_ligands.Count -ne 9 -or
        $record.Stability.ring_probabilities.Count -ne 3 -or
        $record.Stability.ring_u16.Count -ne 3 -or
        $record.Stability.hexabyte_bytes_le.Count -ne 6 -or
        $record.Stability.hexabyte.Length -ne 12) {
        throw 'Malformed nine-ligand, three-ring, six-byte Stability witness.'
    }
    Assert-Near $record.vector[9] $record.Stability.scalar 'Stability dimension'
    Assert-Near $record.diagnostics.legacy_pearson_lr 1 'preserved Pearson diagnostic'
    $maxRing = ($record.Stability.ring_probabilities | Measure-Object -Maximum).Maximum
    $minRing = ($record.Stability.ring_probabilities | Measure-Object -Minimum).Minimum
    Assert-Near $record.Stability.scalar (1.0 - ($maxRing - $minRing)) 'ring agreement'
    if ($record.Stability.scalar -lt 0.0 -or $record.Stability.scalar -gt 1.0) {
        throw 'Stability scalar is outside [0,1].'
    }
    $original = (Get-FileHash -LiteralPath $temp -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($record.input_sha256 -cne $original) { throw 'Source hash mismatch.' }

    # Deliberate fault injection: truncated frame and nonfinite float.
    [IO.File]::WriteAllBytes($temp, [byte[]](1,2,3,4,5,6,7))
    $failedLength = $false
    try { $null = & $main -Analyze10D -RawStereoFloat32Path $temp } catch { $failedLength = $true }
    if (!$failedLength) { throw 'Truncated source must fail.' }

    $bad = [byte[]]::new(8)
    [BitConverter]::GetBytes([float]::NaN).CopyTo($bad,0)
    [IO.File]::WriteAllBytes($temp,$bad)
    $failedNaN = $false
    try { $null = & $main -Analyze10D -RawStereoFloat32Path $temp } catch { $failedNaN = $true }
    if (!$failedNaN) { throw 'Nonfinite source must fail.' }

    Write-Output 'PASS zero-weight Fastest-Whisper-10D: Stability pinned at dimension 10, SHA-256 and failure guards'
} finally {
    Remove-Item -LiteralPath $temp -ErrorAction SilentlyContinue
}
