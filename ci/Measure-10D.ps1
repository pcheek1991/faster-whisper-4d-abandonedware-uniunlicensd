# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Fastest-Whisper-10D: ten descriptive acoustic measurements, no trained model.
# Input: raw interleaved stereo IEEE-754 float32 little-endian; output: JSON.
# This script does NOT decode words or substitute a feature vector for text.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $RawStereoFloat32Path
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$source = [IO.Path]::GetFullPath($RawStereoFloat32Path)
if (!(Test-Path -LiteralPath $source -PathType Leaf)) { throw "Input not found: $source" }
if (![BitConverter]::IsLittleEndian) { throw 'The raw input format requires little-endian float32.' }

$stream = [IO.File]::Open($source, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
$reader = [IO.BinaryReader]::new($stream)
try {
    if (($stream.Length % 8L) -ne 0) {
        throw 'Raw stereo float32 length must be a multiple of 8 bytes.'
    }

    $n = [long]0
    $meanL = [double]0
    $meanR = [double]0
    $m2L = [double]0
    $m2R = [double]0
    $cov = [double]0
    $powerL = [double]0
    $powerR = [double]0
    $peakL = [double]0
    $peakR = [double]0
    $crossL = [long]0
    $crossR = [long]0
    $prevL = [double]0
    $prevR = [double]0

    while ($stream.Position -lt $stream.Length) {
        $l = [double]$reader.ReadSingle()
        $r = [double]$reader.ReadSingle()
        if ([double]::IsNaN($l) -or [double]::IsInfinity($l) -or
            [double]::IsNaN($r) -or [double]::IsInfinity($r)) {
            throw 'Non-finite input sample rejected; no feature report emitted.'
        }

        if ($n -gt 0) {
            if ($prevL -ne 0 -and $l -ne 0 -and (($prevL -lt 0) -ne ($l -lt 0))) { $crossL++ }
            if ($prevR -ne 0 -and $r -ne 0 -and (($prevR -lt 0) -ne ($r -lt 0))) { $crossR++ }
        }
        $n++
        $dl = $l - $meanL
        $dr = $r - $meanR
        $meanL += $dl / $n
        $meanR += $dr / $n
        $m2L += $dl * ($l - $meanL)
        $m2R += $dr * ($r - $meanR)
        $cov += $dl * ($r - $meanR)
        $powerL += $l * $l
        $powerR += $r * $r
        $peakL = [Math]::Max($peakL, [Math]::Abs($l))
        $peakR = [Math]::Max($peakR, [Math]::Abs($r))
        $prevL = $l
        $prevR = $r
    }

    if ($n -eq 0) { throw 'Empty input has no acoustic features; no success report emitted.' }

    $correlation = [double]0
    if ($m2L -gt 0 -and $m2R -gt 0) {
        $correlation = $cov / [Math]::Sqrt($m2L * $m2R)
        $correlation = [Math]::Max(-1.0, [Math]::Min(1.0, $correlation))
    }
    $rmsL = [Math]::Sqrt($powerL / $n)
    $rmsR = [Math]::Sqrt($powerR / $n)
    $vector = @(
        [double]$n,
        [double]$meanL,
        [double]$meanR,
        [double]$rmsL,
        [double]$rmsR,
        [double]$peakL,
        [double]$peakR,
        [double]$crossL,
        [double]$crossR,
        [double]$correlation
    )
    foreach ($component in $vector) {
        if ([double]::IsNaN($component) -or [double]::IsInfinity($component)) {
            throw 'Numeric overflow in the 10D feature vector.'
        }
    }

    $record = [ordered]@{
        schema = 'Fastest-Whisper-10D-acoustic-v1'
        trained_model_used = $false
        transcript_generated = $false
        input_format = 'stereo-float32le'
        input_sha256 = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
        dimensions = @('frame_count','mean_left','mean_right',
                       'rms_left','rms_right','peak_left','peak_right',
                       'zero_crossings_left','zero_crossings_right','pearson_lr')
        vector = $vector
        note = 'Descriptive waveform statistics, not lexical recognition. Zero-variance correlation uses 0 by convention.'
    }
    $record | ConvertTo-Json -Depth 5
} finally {
    $reader.Dispose()
    $stream.Dispose()
}
