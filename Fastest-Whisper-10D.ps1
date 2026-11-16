# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Fastest-Whisper-10D: PowerShell 7, StrictMode v2.0, no model weights.
# Transparent bridge into the existing DUNGU-derived C# audio transform.
# The compiled converter uses no Whisper, VAD, ONNX, Hub or Python runtime.
[CmdletBinding(DefaultParameterSetName = 'Files')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Files')]
    [ValidateNotNullOrEmpty()]
    [string] $SourcePath,

    [Parameter(Mandatory = $true, ParameterSetName = 'Files')]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath,

    [Parameter(ParameterSetName = 'Files')]
    [string] $QuadOutputPath,

    [Parameter(ParameterSetName = 'Files')]
    [string] $FfmpegPath,

    [Parameter(Mandatory = $true, ParameterSetName = 'StdinStdout')]
    [switch] $StdinStdout,

    [Parameter(ParameterSetName = 'StdinStdout')]
    [ValidateRange(1, 1048576)]
    [int] $FramesPerBlock = 16384,

    [Parameter(Mandatory = $true, ParameterSetName = 'StreamSelfTest')]
    [switch] $StreamSelfTest,

    [Parameter(Mandatory = $true, ParameterSetName = 'Analyze10D')]
    [switch] $Analyze10D,

    [Parameter(Mandatory = $true, ParameterSetName = 'Analyze10D')]
    [ValidateNotNullOrEmpty()]
    [string] $RawStereoFloat32Path
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ($PSCmdlet.ParameterSetName -eq 'Analyze10D') {
    & (Join-Path $PSScriptRoot 'ci/Measure-10D.ps1') -RawStereoFloat32Path $RawStereoFloat32Path
    return
}

$converter = Join-Path $PSScriptRoot 'faster_whisper/assets/Convert-AnythingToCoreoFloat.ps1'
if (!(Test-Path -LiteralPath $converter -PathType Leaf)) {
    throw 'The pinned PowerShell/C# Coreo converter is missing.'
}

$forward = @{
    ErrorAction = 'Stop'
}
if ($PSCmdlet.ParameterSetName -eq 'StreamSelfTest') {
    $forward['StreamSelfTest'] = $true
} elseif ($PSCmdlet.ParameterSetName -eq 'StdinStdout') {
    $forward['StdinStdout'] = $true
    $forward['FramesPerBlock'] = $FramesPerBlock
} else {
    $forward['SourcePath'] = $SourcePath
    $forward['OutputPath'] = $OutputPath
    if ($PSBoundParameters.ContainsKey('QuadOutputPath')) {
        $forward['QuadOutputPath'] = $QuadOutputPath
    }
    if ($PSBoundParameters.ContainsKey('FfmpegPath')) {
        $forward['FfmpegPath'] = $FfmpegPath
    }
}

# The raw-stdio route must never emit incidental text to stdout.
& $converter @forward
