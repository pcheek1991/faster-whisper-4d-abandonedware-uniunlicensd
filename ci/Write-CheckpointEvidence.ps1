# Checkpoint 10 evidence: fingerprints only, never model/audio/transcript payloads.
# Run at the end of a CI job even if pre-flight or a synthetic test fails.
[CmdletBinding()]
param([string] $EvidenceDir = 'evidence')

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$target = [IO.Path]::GetFullPath((Join-Path $root $EvidenceDir))
New-Item -ItemType Directory -Force -Path $target | Out-Null

function Get-Sha256([string] $path) {
    return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
}

$tracked = & git -C $root ls-files
if ($LASTEXITCODE -ne 0) { throw 'Unable to enumerate source identity.' }
$sourceFingerprints = [Collections.Generic.List[object]]::new()
foreach ($name in ($tracked | Sort-Object)) {
    $source = Join-Path $root $name
    if (!(Test-Path -LiteralPath $source -PathType Leaf)) { continue }
    $item = Get-Item -LiteralPath $source
    $sourceFingerprints.Add([ordered]@{
        path = $name.Replace('\', '/')
        bytes = $item.Length
        sha256 = Get-Sha256 $source
    })
}

$executables = [Collections.Generic.List[object]]::new()
foreach ($tool in @('pwsh','git','dotnet','python','clang','cl.exe')) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue | Where-Object {
        $_.Source -and (Test-Path -LiteralPath $_.Source -PathType Leaf)
    } | Select-Object -First 1
    if (!$cmd) { continue }
    $executables.Add([ordered]@{
        tool = $tool
        path = $cmd.Source
        bytes = (Get-Item -LiteralPath $cmd.Source).Length
        sha256 = Get-Sha256 $cmd.Source
        redistributed = $false
    })
}

$head = (& git -C $root rev-parse HEAD 2>$null | Select-Object -First 1)
if ($LASTEXITCODE -ne 0) { $head = 'unavailable' }
$rightState = if (Test-Path -LiteralPath (Join-Path $root 'LICENSE') -PathType Leaf) {
    'license-file-present-requires-rights-review'
} else {
    'NO-LICENSE-FILE-PUBLISH-BLOCKED'
}

# No PATH, environment-variable dump, Git remotes, private audio, or models.
$report = [ordered]@{
    schema = 'Checkpoint10-Provenance-v1'
    generated_utc = (Get-Date).ToUniversalTime().ToString('o')
    repository = $env:GITHUB_REPOSITORY
    run_id = $env:GITHUB_RUN_ID
    run_attempt = $env:GITHUB_RUN_ATTEMPT
    workflow = $env:GITHUB_WORKFLOW
    github_sha = $env:GITHUB_SHA
    checkout_sha = $head
    runner_os = $env:RUNNER_OS
    runner_arch = $env:RUNNER_ARCH
    powershell_version = $PSVersionTable.PSVersion.ToString()
    rights_state = $rightState
    raw_audio_or_models_uploaded = $false
    compiler_executables_redistributed = $false
    tool_fingerprints = @($executables)
    tracked_source_fingerprints = @($sourceFingerprints)
}
$manifest = Join-Path $target 'manifest.json'
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifest -Encoding utf8

# Conventional SHA256SUMS, relative paths only. Checksum file is excluded.
$sumPath = Join-Path $target 'SHA256SUMS'
$lines = [Collections.Generic.List[string]]::new()
Get-ChildItem -LiteralPath $target -Recurse -File |
    Where-Object { $_.FullName -ne $sumPath } |
    Sort-Object FullName | ForEach-Object {
        $rel = [IO.Path]::GetRelativePath($target, $_.FullName).Replace('\','/')
        $lines.Add(('{0}  {1}' -f (Get-Sha256 $_.FullName), $rel))
    }
$lines | Set-Content -LiteralPath $sumPath -Encoding utf8
Write-Output ("Checkpoint10 evidence: {0} source fingerprints, {1} artifact checksums, no audio payloads" -f $sourceFingerprints.Count,$lines.Count)
Write-Output ("Release rights state: {0}" -f $rightState)
