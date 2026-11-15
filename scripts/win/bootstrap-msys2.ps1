<#
 Installs MSYS2 (via winget) if missing. Run once from PowerShell.
 Everything is sourced from GitHub / MSYS2 package mirrors; nothing from git.ardour.org.
#>
$ErrorActionPreference = 'Stop'
$root = if ($env:MSYS2_ROOT) { $env:MSYS2_ROOT } else { 'C:\msys64' }
if (-not (Test-Path "$root\usr\bin\bash.exe")) {
    winget install --id MSYS2.MSYS2 -e --accept-package-agreements --accept-source-agreements --location $root
}
if (-not (Test-Path "$root\usr\bin\bash.exe")) { throw "MSYS2 not found at $root" }
Write-Host "MSYS2 ready at $root. Next: scripts\win\build.ps1"
