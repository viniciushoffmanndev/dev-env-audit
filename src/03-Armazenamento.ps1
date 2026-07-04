<#
.SYNOPSIS
    Storage data collection module (Drives).
.DESCRIPTION
    This script collects information about local logical disks,
    calculating total space, free space, and usage percentages.
#>

Write-Host "[*] Starting Storage audit..." -ForegroundColor Cyan

$drives = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
$driveList = @()

foreach ($drive in $drives) {
    $totalSpaceGB = [Math]::Round(($drive.Size / 1GB), 2)
    $freeSpaceGB = [Math]::Round(($drive.FreeSpace / 1GB), 2)
    $usedSpaceGB = $totalSpaceGB - $freeSpaceGB
    
    $usagePercentage = 0
    if ($totalSpaceGB -gt 0) {
        $usagePercentage = [Math]::Round((($usedSpaceGB / $totalSpaceGB) * 100), 2)
    }

    $driveDetails = [PSCustomObject]@{
        Letter          = $drive.DeviceID
        VolumeName      = $drive.VolumeName
        FileSystem      = $drive.FileSystem
        Total_GB        = $totalSpaceGB
        Free_GB         = $freeSpaceGB
        Used_GB         = $usedSpaceGB
        UsagePercentage = $usagePercentage
    }
    
    $driveList += $driveDetails
}

$storageData = [PSCustomObject]@{
    Module      = "Storage"
    CollectedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Drives      = $driveList
}

$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\output\Storage.json"
$storageData | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[+] Storage audit completed! Data saved to: output\Storage.json" -ForegroundColor Green