$ErrorActionPreference = 'Stop'

function Get-FreeSpaceGiB {
    $workspaceDrive = [System.IO.Path]::GetPathRoot($env:GITHUB_WORKSPACE).TrimEnd('\').TrimEnd(':')
    $drive = Get-PSDrive -Name $workspaceDrive
    return [math]::Floor($drive.Free / 1GB)
}

Write-Host "Free space before cleanup: $(Get-FreeSpaceGiB) GiB"

# The source build needs substantial temporary space. Remove only optional SDK
# caches that are unrelated to this Windows C++/WinUI build; keep VS, Windows
# SDKs, .NET, Git, and all compiler components intact.
$optionalPaths = @(
    (Join-Path $env:ProgramFiles 'Android'),
    (Join-Path ${env:ProgramFiles(x86)} 'Android'),
    (Join-Path $env:USERPROFILE '.android'),
    (Join-Path $env:USERPROFILE '.gradle'),
    (Join-Path $env:USERPROFILE '.m2\repository'),
    (Join-Path $env:USERPROFILE '.cargo\registry'),
    (Join-Path $env:RUNNER_TOOL_CACHE 'Python'),
    (Join-Path $env:RUNNER_TOOL_CACHE 'Go'),
    (Join-Path $env:RUNNER_TOOL_CACHE 'Ruby'),
    (Join-Path $env:RUNNER_TOOL_CACHE 'Java_Temurin-Hotspot_jdk')
)

foreach ($path in $optionalPaths) {
    if (Test-Path -LiteralPath $path) {
        Write-Host "Removing unrelated cached tool data: $path"
        Remove-Item -LiteralPath $path -Recurse -Force
    }
}

$freeGiB = Get-FreeSpaceGiB
Write-Host "Free space after cleanup: $freeGiB GiB"
if ($freeGiB -lt 36) {
    throw "WinUI source build requires at least 36 GiB free before restore; runner has $freeGiB GiB."
}
