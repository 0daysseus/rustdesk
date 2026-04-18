Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $IsWindows) {
    throw "This script must be run on Windows."
}

function Require-Command {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name"
    }
}

Require-Command cargo
Require-Command flutter

if (-not $env:VCPKG_ROOT) {
    throw "VCPKG_ROOT must be set before running this script."
}

if (-not (Test-Path $env:VCPKG_ROOT)) {
    throw "VCPKG_ROOT does not exist: $env:VCPKG_ROOT"
}

$pythonCommand = $null
$pythonArgs = @()
if (Get-Command py -ErrorAction SilentlyContinue) {
    $pythonCommand = "py"
    $pythonArgs = @("-3")
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCommand = "python"
} else {
    throw "Python 3 launcher not found. Install Python and ensure py or python is on PATH."
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Push-Location $repoRoot

try {
    & $pythonCommand @pythonArgs "build.py" "--portable" "--flutter" "--hwcodec" "--vram"

    $versionLine = Select-String -Path "Cargo.toml" -Pattern '^version\s*=' | Select-Object -First 1
    if (-not $versionLine) {
        throw "Unable to read version from Cargo.toml."
    }

    $version = ($versionLine.Line -split "=", 2)[1].Trim().Trim('"')
    $portableName = "HomeRemote-$version-portable.exe"
    $portablePath = Join-Path $repoRoot $portableName

    if (-not (Test-Path $portablePath)) {
        throw "Expected portable output not found: $portablePath"
    }

    Write-Host "Portable output: $portablePath"
} finally {
    Pop-Location
}
