<#
.SYNOPSIS
    Operating System data collection module (Windows).
.DESCRIPTION
    This script collects information about Windows version, build,
    and calculates system uptime.
#>

Write-Host "[*] Starting Windows audit..." -ForegroundColor Cyan

$os = Get-CimInstance -ClassName Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime

$windowsData = [PSCustomObject]@{
    Module        = "Windows"
    CollectedAt   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    OperatingSystem = [PSCustomObject]@{
        Edition      = $os.Caption.Replace("Microsoft ", "").Trim()
        Version      = $os.Version
        Build        = $os.BuildNumber
        Architecture = $os.OSArchitecture
    }
    Status = [PSCustomObject]@{
        LastBoot     = $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss")
        Uptime_Hours = [Math]::Round($uptime.TotalHours, 2)
        Uptime_Days  = [Math]::Round($uptime.TotalDays, 2)
    }
}

$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\output\Windows.json"
$windowsData | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[+] Windows audit completed! Data saved to: output\Windows.json" -ForegroundColor Green