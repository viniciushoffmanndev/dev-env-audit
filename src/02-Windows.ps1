<#
.SYNOPSIS
    Operating System and Licensing data collection module (Windows).
.DESCRIPTION
    This script collects information about Windows version, build,
    licensing status, and calculates system uptime.
#>

Write-Host "[*] Starting Windows audit..." -ForegroundColor Cyan

# 1. Coleta de Informações do Sistema Operacional
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$osBranch = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").UBR
if (-not $osBranch) {
    $osBranch = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId
}

# 2. Cálculo de Uptime (Tempo que o PC está ligado)
$uptime = (Get-Date) - $os.LastBootUpTime

# 3. Coleta de Licenciamento do Windows
$license = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' and Description like '%Windows%'" | 
    Where-Object { $_.PartialProductKey } | Select-Object -First 1

$statusMap = @{
    0 = "Unlicensed"
    1 = "Licensed"
    2 = "OOBE Grace"
    3 = "Out-of-Tolerance Grace"
    4 = "Non-Genuine Grace"
    5 = "Notification"
}
$currentStatus = $statusMap[[int]$license.LicenseStatus]
if (-not $currentStatus) { $currentStatus = "Unknown" }

$channel = "Volume/Other"
if ($license.Description -like "*OEM*") { $channel = "OEM" }
elseif ($license.Description -like "*RETAIL*") { $channel = "Retail" }

# 4. Criando o Objeto Estruturado Unificado
$windowsData = [PSCustomObject]@{
    Module        = "Windows"
    CollectedAt   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    OperatingSystem = [PSCustomObject]@{
        Edition      = $os.Caption.Replace("Microsoft ", "").Trim()
        Version      = $os.Version
        Build        = $os.BuildNumber
        Architecture = $os.OSArchitecture
        Branch       = $osBranch
    }
    Licensing = [PSCustomObject]@{
        Status       = $currentStatus
        Channel      = $channel
        PartialKey   = $license.PartialProductKey
    }
    Status = [PSCustomObject]@{
        LastBoot     = $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss")
        Uptime_Hours = [Math]::Round($uptime.TotalHours, 2)
        Uptime_Days  = [Math]::Round($uptime.TotalDays, 2)
    }
}

# 5. Define o caminho de saída e salva o JSON
$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\output\Windows.json"
$windowsData | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[+] Windows audit completed! Data saved to: output\Windows.json" -ForegroundColor Green