<#
.SYNOPSIS
    Hardware data collection module for dev-env-audit.
.DESCRIPTION
    This script collects information about Manufacturer, Model, BIOS, CPU, and RAM
    in a safe, read-only mode.
#>

Write-Host "[*] Starting Hardware audit..." -ForegroundColor Cyan

$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
$bios = Get-CimInstance -ClassName Win32_BIOS
$cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
$ram = Get-CimInstance -ClassName Win32_PhysicalMemory

$totalRamGB = [Math]::Round(($computerSystem.TotalPhysicalMemory / 1GB), 2)
$slotsUsed = $ram.Count
$ramSpeed = ($ram | Select-Object -ExpandProperty Speed -Unique) -join ", "

$hardwareData = [PSCustomObject]@{
    Module        = "Hardware"
    CollectedAt   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    System = [PSCustomObject]@{
        Manufacturer = $computerSystem.Manufacturer
        Model        = $computerSystem.Model
        Type         = $computerSystem.SystemType
    }
    BIOS = [PSCustomObject]@{
        Version     = $bios.SMBIOSBIOSVersion
        Manufacturer = $bios.Manufacturer
        ReleaseDate  = $bios.ReleaseDate
    }
    CPU = [PSCustomObject]@{
        Name           = $cpu.Name.Trim()
        PhysicalCores  = $cpu.NumberOfCores
        LogicalProcessors = $cpu.NumberOfLogicalProcessors
        Architecture   = if ($cpu.Architecture -eq 9) { "x64" } else { "x86/Others" }
    }
    RAM = [PSCustomObject]@{
        TotalInstalled_GB = $totalRamGB
        SlotsUsed         = $slotsUsed
        Speed_MHz         = $ramSpeed
    }
}

$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\output\Hardware.json"
$hardwareData | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[+] Hardware audit completed! Data saved to: output\Hardware.json" -ForegroundColor Green