# Verify only files inside the downloaded Checkpoint 10 evidence directory.
[CmdletBinding()]
param([string] $EvidenceDir = 'evidence')

$ErrorActionPreference = 'Stop'
$dir = [IO.Path]::GetFullPath((Join-Path (Join-Path $PSScriptRoot '..') $EvidenceDir))
$sum = Join-Path $dir 'SHA256SUMS'
if (!(Test-Path -LiteralPath $sum -PathType Leaf)) { throw 'Missing SHA256SUMS.' }
$verified = 0
$base = $dir.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
foreach ($line in (Get-Content -LiteralPath $sum)) {
    if ($line -cnotmatch '^([0-9a-f]{64})  (.+)$') { throw "Malformed checksum: $line" }
    $expected = $Matches[1]
    $rel = $Matches[2]
    $path = [IO.Path]::GetFullPath((Join-Path $dir $rel))
    if (!$path.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Out-of-directory SHA256 manifest path rejected: $rel"
    }
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Evidence member missing: $rel" }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -cne $expected) { throw "SHA256 mismatch: $rel" }
    $verified++
}
if ($verified -lt 1) { throw 'Empty evidence manifest is not a success.' }
Write-Output ("Checkpoint10 integrity PASS: {0}/{0} evidence hashes verified." -f $verified)
