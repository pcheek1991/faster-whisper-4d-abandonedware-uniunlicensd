# SPDX-License-Identifier: 0BSD
# Copyright (c) 2026 Paul Allen Cheek
# Read-only release pre-flight: no debugger stops or model-weight artifacts.
[CmdletBinding()]
param([switch] $RequireVerifiedLicense)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$tracked = @(& git -C $root ls-files)
if ($LASTEXITCODE -ne 0) { throw 'Unable to enumerate tracked files.' }

$patterns = [ordered]@{
    'interactive debugger stop' = '(?i)\b(?:breakpoint|pdb[.]set_trace|ipdb[.]set_trace|debugpy[.]breakpoint|debugpy[.]wait_for_client)\s*\('
    'native debugger trap' = '(?i)\b(?:__debugbreak|DebugBreak|__builtin_debugtrap|__builtin_trap|SIGTRAP|SIGSTOP)\b'
    'PowerShell interactive stop' = '(?i)\b(?:Wait-Debugger|Read-Host|Pause-Process)\b'
    'disabled preprocessor block' = '(?m)^\s*#\s*if\s+0(?:\s|$)'
}

$issues = [Collections.Generic.List[string]]::new()
$inspected = 0
foreach ($name in $tracked) {
    $extension = [IO.Path]::GetExtension($name).ToLowerInvariant()

    if ($extension -in @('.onnx','.safetensors','.pt','.pth','.ckpt',
                          '.gguf','.ggml','.tflite') -or
        $name -match '(?i)(^|[/\\])model[.]bin$') {
        $issues.Add(('{0}: pretrained model-weight artifact is prohibited.' -f $name))
    }

    if ($extension -notin @('.py','.ps1','.java','.cpp','.c','.hpp','.h')) {
        continue
    }
    # This scanner contains the prohibited names as data, not execution.
    if ($name -eq 'ci/Test-ReleaseReadiness.ps1') { continue }

    $path = Join-Path $root $name
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $source = [IO.File]::ReadAllText($path)
    $inspected++
    foreach ($rule in $patterns.GetEnumerator()) {
        foreach ($match in [regex]::Matches($source, $rule.Value)) {
            $line = 1 + [regex]::Matches($source.Substring(0, $match.Index), '\n').Count
            $issues.Add(('{0}:{1}: {2}' -f $name,$line,$rule.Key))
        }
    }
}

if ($RequireVerifiedLicense) {
    if (!(Test-Path -LiteralPath (Join-Path $root 'LICENSE') -PathType Leaf)) {
        $issues.Add('Missing LICENSE. Repository metadata is not a grant.')
    }
    # Presence of a license does not establish rights to external components.
}

if ($issues.Count -gt 0) {
    foreach ($issue in $issues) { [Console]::Error.WriteLine($issue) }
    throw ('Release pre-flight FAILED: {0} violation(s).' -f $issues.Count)
}
Write-Output ('Release pre-flight PASS: {0} tracked sources scanned; no debugger-stop patterns or trained weights.' -f $inspected)
if (!$RequireVerifiedLicense) {
    Write-Output 'Rights review remains separate from successful source verification.'
}
