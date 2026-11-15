<#
 Build Ardour natively on Windows inside MSYS2 UCRT64.
   .\scripts\win\build.ps1                 # deps + configure + build
   .\scripts\win\build.ps1 -Action package # also stage a runnable bundle in build\win-bundle
   -Action deps|configure|build|package|clean   -Jobs N   -Optimize
#>
param(
    [ValidateSet('all','deps','configure','build','package','clean')][string]$Action = 'all',
    [int]$Jobs = [Environment]::ProcessorCount,
    [switch]$Optimize
)
$ErrorActionPreference = 'Stop'
$msys = if ($env:MSYS2_ROOT) { $env:MSYS2_ROOT } else { 'C:\msys64' }
if (-not (Test-Path "$msys\usr\bin\bash.exe")) { throw "MSYS2 missing; run scripts\win\bootstrap-msys2.ps1" }
$repo = (Resolve-Path "$PSScriptRoot\..\..").Path
$env:MSYSTEM = 'UCRT64'; $env:CHERE_INVOKING = '1'; $env:MSYS2_PATH_TYPE = 'inherit'
$env:ARDOUR_JOBS = $Jobs; $env:ARDOUR_OPTIMIZE = [int]$Optimize.IsPresent
$posix = (& "$msys\usr\bin\cygpath.exe" -u $repo).Trim()
& "$msys\usr\bin\bash.exe" -lc "cd '$posix' && bash scripts/win/build-msys2.sh $Action"
if ($LASTEXITCODE) { throw "build failed ($LASTEXITCODE)" }
