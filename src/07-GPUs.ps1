<#
.SYNOPSIS
    GPU telemetry module.
.DESCRIPTION
    Collects active video controller adapters (Intel Integrated and NVIDIA Dedicated),
    extracting VRAM capacity, driver versions, and statuses.
#>

Write-Host "[*] Starting GPU and video controllers telemetry scan..." -ForegroundColor Cyan

# 1. Varre os controladores de vídeo ativos no sistema
$gpuData = Get-CimInstance -ClassName Win32_VideoController | ForEach-Object {
    # Converte os bytes brutos de VRAM para Gigabytes (se houver dados)
    $vramBytes = $_.AdapterRAM
    $vramGB = 0
    if ($vramBytes -and $vramBytes -gt 0) {
        $vramGB = [math]::Round($vramBytes / 1GB, 2)
    }

    [PSCustomObject]@{
        Name          = $_.Name
        VRAM_GB       = if ($vramGB -gt 0) { $vramGB } else { "Dynamic/Shared" }
        DriverVersion = $_.DriverVersion
        Status        = $_.Status
    }
}

# 2. Montagem do Objeto JSON estruturado
$gpuTelemetry = [PSCustomObject]@{
    Module      = "GPU"
    CollectedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    VideoCards  = $gpuData
}

# 3. Exportação segura para o arquivo JSON
$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\output\GPU.json"
$gpuTelemetry | ConvertTo-Json -Depth 4 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[+] GPU scan completed! Data saved to: output\GPU.json" -ForegroundColor Green