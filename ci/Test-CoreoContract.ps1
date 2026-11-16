# Checkpoint 10: independent, synthetic-only PowerShell 7 Coreo contract audit.
# No Whisper model weights, Python runner, external audio, or transcript needed.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$converter = Join-Path $root 'faster_whisper/assets/Convert-AnythingToCoreoFloat.ps1'
if (!(Test-Path -LiteralPath $converter -PathType Leaf)) { throw 'Missing bundled Coreo implementation.' }
if (![BitConverter]::IsLittleEndian) { throw 'Fixture requires little-endian float32.' }
$pwsh = (Get-Command pwsh -ErrorAction Stop).Source

function New-FloatBytes([float[]] $values) {
    $list = [Collections.Generic.List[byte]]::new()
    foreach ($value in $values) { $list.AddRange([BitConverter]::GetBytes($value)) }
    return ,$list.ToArray()
}

function Run-Coreo([byte[]] $inputBytes, [int] $blockFrames = 2) {
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $pwsh
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($arg in @('-NoLogo', '-NoProfile', '-NonInteractive', '-File',
                       $converter, '-StdinStdout', '-FramesPerBlock',
                       [string]$blockFrames)) { [void]$start.ArgumentList.Add($arg) }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    $out = [IO.MemoryStream]::new()
    try {
        if (!$process.Start()) { throw 'Could not start PowerShell converter.' }
        $outputTask = $process.StandardOutput.BaseStream.CopyToAsync($out)
        $errorTask = $process.StandardError.ReadToEndAsync()
        if ($inputBytes.Length) {
            $process.StandardInput.BaseStream.Write($inputBytes, 0, $inputBytes.Length)
        }
        $process.StandardInput.Close()
        if (!$process.WaitForExit(30000)) {
            $process.Kill($true)
            throw 'Coreo converter exceeded 30 seconds for a synthetic fixture.'
        }
        $outputTask.GetAwaiter().GetResult()
        $errorText = $errorTask.GetAwaiter().GetResult()
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Bytes = $out.ToArray()
            ErrorText = $errorText
        }
    } finally {
        if (!$process.HasExited) { $process.Kill($true) }
        $out.Dispose()
        $process.Dispose()
    }
}

function Assert-BytesEqual([byte[]] $actual, [byte[]] $expected, [string] $caseName) {
    if ($actual.Length -ne $expected.Length) {
        throw "$caseName output length differs: $($actual.Length) != $($expected.Length)"
    }
    for ($i = 0; $i -lt $actual.Length; $i++) {
        if ($actual[$i] -ne $expected[$i]) { throw "$caseName byte mismatch at offset $i" }
    }
}

# Forward (source -> four-channel), reverse (YIN -> source), then
# Z-fold (YIN[k] == YAN[N-1-k]): one maximum scalar, never an average.
function Get-Scalar([float[]] $source, [float[]] $actual) {
    $frames = [int]($source.Length / 2)
    if ($actual.Length -ne 4 * $frames) { throw 'Invalid four-channel fixture.' }
    $largest = [double]0.0
    for ($i = 0; $i -lt $frames; $i++) {
        $j = $frames - $i - 1
        # Parenthesize each scalar; PowerShell's comma operator can bind
        # more tightly than addition, manufacturing an Object[] operand.
        $relations = @(
            ([double]$actual[4*$i] + [double]$source[2*$j])
            ([double]$actual[4*$i+1] + [double]$source[2*$j+1])
            ([double]$actual[4*$i+2] + [double]$source[2*$i])
            ([double]$actual[4*$i+3] + [double]$source[2*$i+1])
            ([double]$actual[4*$i] - [double]$actual[4*$j+2])
            ([double]$actual[4*$i+1] - [double]$actual[4*$j+3])
        )
        foreach ($residual in $relations) {
            $largest = [Math]::Max($largest, [Math]::Abs($residual))
        }
    }
    return $largest
}

$source = [float[]]@(1, 10, 2, 20, 3, 30)
$sourceBytes = New-FloatBytes $source
$expected = New-FloatBytes ([float[]]@(
    -3, -30, -1, -10,
    -2, -20, -2, -20,
    -1, -10, -3, -30
))
$good = Run-Coreo $sourceBytes
if ($good.ExitCode -ne 0) {
    throw "Golden stream rejected: $($good.ErrorText)"
}
Assert-BytesEqual $good.Bytes $expected 'golden vector'
$actual = [float[]]::new(12)
for ($i = 0; $i -lt 12; $i++) {
    $actual[$i] = [BitConverter]::ToSingle($good.Bytes, 4 * $i)
}
if ((Get-Scalar $source $actual) -ne 0.0) { throw 'Golden scalar must be exactly zero.' }

$tampered = [float[]]$actual.Clone()
$tampered[0] += 0.5
if ((Get-Scalar $source $tampered) -le 0.0) {
    throw 'Corrupted data evaded the maximum-disagreement scalar.'
}
Assert-BytesEqual $sourceBytes (New-FloatBytes $source) 'unmodified source'

$empty = Run-Coreo ([byte[]]@())
if ($empty.ExitCode -ne 0 -or $empty.Bytes.Length -ne 0) {
    throw 'Empty input must produce empty output successfully.'
}
$badLength = Run-Coreo ([byte[]](1,2,3,4,5,6,7))
if ($badLength.ExitCode -eq 0 -or $badLength.Bytes.Length -ne 0) {
    throw 'Truncated stereo frame must fail without emitting output.'
}
$nanInput = New-FloatBytes ([float[]]@([float]::NaN, 0))
$badFloat = Run-Coreo $nanInput
if ($badFloat.ExitCode -eq 0 -or $badFloat.Bytes.Length -ne 0) {
    throw 'Non-finite float32 input must fail without emitting output.'
}

$selfTestLog = & $pwsh -NoLogo -NoProfile -NonInteractive -File $converter -StreamSelfTest 2>&1
if ($LASTEXITCODE -ne 0 -or !(($selfTestLog -join ' ') -match 'All stdin/stdout transform tests passed')) {
    throw "Bundled converter self-test failed: $($selfTestLog -join ' ')"
}

$digest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($good.Bytes)).ToLowerInvariant()
Write-Output 'PASS Checkpoint10: forward / reverse / Z-fold scalar = 0'
Write-Output 'PASS source unchanged; correlated output protected by cross-fold witnesses'
Write-Output 'PASS empty, malformed, NaN and injected tampering cases'
Write-Output ('Synthetic golden output SHA256: ' + $digest)
