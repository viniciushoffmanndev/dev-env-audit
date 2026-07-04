<#
.SYNOPSIS
    Cache and temporary files sizing module.
.DESCRIPTION
    Measures space occupied by package managers (npm, pip) and
    Windows system temp folders safely.
#>

Write-Host "[*] Starting cache analysis..." -ForegroundColor Cyan

function Get-FolderSizeGB {
    param (
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return 0
    }

    try {
        $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
        $totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
        
        if (-not $totalBytes) { $totalBytes = 0 }
        
        return [Math]::Round(($totalBytes / 1GB), 2)
    }
    catch {
        return 0
    }
}

$userProfile = $env:USERPROFILE
$localAppData = $env:LOCALAPPDATA

$paths = @{
    WindowsTemp = "$env:SystemRoot\Temp"
    UserTemp    = "$localAppData\Temp"
    NpmCache    = "$userProfile\AppData\Local\npm-cache"
    PipCache    = "$localAppData\pip\Cache"
}

Write-Host "[*] Measuring development caches (NPM, Pip)..." -ForegroundColor Yellow
$npmSize = Get-FolderSizeGB -Path $paths.NpmCache
$pipSize = Get-FolderSizeGB -Path $paths.PipCache

Write-Host "[*] Measuring system temporary folders..." -ForegroundColor Yellow
$winTempSize = Get-FolderSizeGB -Path $paths.WindowsTemp
$userTempSize = Get-FolderSizeGB -Path $paths.UserTemp

$totalRecoverable = $npmSize + $pipSize + $winTempSize + $userTempSize

$cacheData = [PSCustomObject]@{
    Module        = "Caches"
    CollectedAt   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    DevelopmentCaches = [PSCustomObject]@{
        NPM_Cache_GB = $npmSize
        PIP_Cache_GB = $pipSize
    }
    SystemTemporary = [PSCustomObject]@{
        Windows_Temp_GB = $winTempSize
        User_Temp_GB    = $userTempSize
    }
    Summary = [PSCustomObject]@{
        TotalSafeCleanup_GB = [Math]::Round($totalRecoverable, 2)
    }
}

$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\output\Caches.json"
$cacheData | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[+] Cache analysis completed! Data saved to: output\Caches.json" -ForegroundColor Green