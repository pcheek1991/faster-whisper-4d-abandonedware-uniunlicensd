# SPDX-FileCopyrightText: 2026 Project contributors
# CI diagnostic tooling; no license grant is asserted for upstream sources.
# Read-only pre-flight, with an optional strict distribution-rights gate.

[CmdletBinding()]
param([switch] $RequireVerifiedLicense)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$files = & git -C $root ls-files
if ($LASTEXITCODE -ne 0) { throw 'Cannot enumerate tracked source files.' }

$patterns = [ordered]@{
    'Python interactive breakpoint' = '(?i)\b(?:breakpoint|pdb\.set_trace|ipdb\.set_trace|debugpy\.breakpoint|debugpy\.wait_for_client)\s*\('
    'Native debugger stop' = '(?i)\b(?:__debugbreak|DebugBreak|__builtin_debugtrap|__builtin_trap|SIGTRAP|SIGSTOP)\b'
    'PowerShell debugger stop' = '(?i)\b(?:Wait-Debugger|Read-Host|Pause-Process)\b'
    'Disabled compile block' = '(?m)^\s*#\s*if\s+0(?:\s|$)'
}
$issues = [System.Collections.Generic.List[string]]::new()
$examined = 0
foreach ($name in $files) {
    $ext = [IO.Path]::GetExtension($name).ToLowerInvariant()
    if ($ext -in @('.onnx','.safetensors','.pt','.pth','.ckpt',
                   '.gguf','.ggml','.tflite') -or
        $name -match '(?i)(^|[\\/])model\.bin
    # The scanner includes its own diagnostic phrases, so do not treat its
    # match definitions as source-code debugger statements.
    if ($name -eq 'ci/Test-ReleaseReadiness.ps1') { continue }
    $path = Join-Path $root $name
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $examined++
    $src = [IO.File]::ReadAllText($path)
    foreach ($rule in $patterns.GetEnumerator()) {
        foreach ($match in [regex]::Matches($src, $rule.Value)) {
            $line = 1 + [regex]::Matches($src.Substring(0, $match.Index), '\n').Count
            $issues.Add(('{0}:{1}: {2}' -f $name, $line, $rule.Key))
        }
    }
}

if ($RequireVerifiedLicense) {
    $licensePath = Join-Path $root 'LICENSE'
    if (!(Test-Path -LiteralPath $licensePath -PathType Leaf)) {
        $issues.Add('LICENSE: missing; inherited setup.py MIT metadata is not a rights grant.')
    }
    # Presence of a LICENSE is a minimum condition, not verification that
    # the maintainer holds copyright or has upstream redistribution rights.
}

if ($issues.Count) {
    foreach ($issue in $issues) { [Console]::Error.WriteLine($issue) }
    throw ("Checkpoint 10 pre-flight FAILED: {0} issue(s)." -f $issues.Count)
}
Write-Output ("Checkpoint 10 pre-flight PASS: {0} tracked source files inspected; no debugger-stop patterns." -f $examined)
if (!$RequireVerifiedLicense) {
    Write-Output 'Rights gate not asserted in CI; distribution requires separate maintainer review.'
}) {
        $issues.Add(('{0}: pretrained model weight artifact is forbidden by the weight-free release policy.' -f $name))
    }
    if ($ext -notin @('.py', '.ps1', '.cpp', '.c', '.hpp', '.h', '.java')) { continue }
    # The scanner includes its own diagnostic phrases, so do not treat its
    # match definitions as source-code debugger statements.
    if ($name -eq 'ci/Test-ReleaseReadiness.ps1') { continue }
    $path = Join-Path $root $name
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $examined++
    $src = [IO.File]::ReadAllText($path)
    foreach ($rule in $patterns.GetEnumerator()) {
        foreach ($match in [regex]::Matches($src, $rule.Value)) {
            $line = 1 + [regex]::Matches($src.Substring(0, $match.Index), '\n').Count
            $issues.Add(('{0}:{1}: {2}' -f $name, $line, $rule.Key))
        }
    }
}

if ($RequireVerifiedLicense) {
    $licensePath = Join-Path $root 'LICENSE'
    if (!(Test-Path -LiteralPath $licensePath -PathType Leaf)) {
        $issues.Add('LICENSE: missing; inherited setup.py MIT metadata is not a rights grant.')
    }
    # Presence of a LICENSE is a minimum condition, not verification that
    # the maintainer holds copyright or has upstream redistribution rights.
}

if ($issues.Count) {
    foreach ($issue in $issues) { [Console]::Error.WriteLine($issue) }
    throw ("Checkpoint 10 pre-flight FAILED: {0} issue(s)." -f $issues.Count)
}
Write-Output ("Checkpoint 10 pre-flight PASS: {0} tracked source files inspected; no debugger-stop patterns." -f $examined)
if (!$RequireVerifiedLicense) {
    Write-Output 'Rights gate not asserted in CI; distribution requires separate maintainer review.'
}