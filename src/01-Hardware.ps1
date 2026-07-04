<#
.SYNOPSIS
    Módulo de coleta de dados de Hardware do dev-env-audit.
.DESCRIPTION
    Este script coleta informações sobre Fabricante, Modelo, BIOS, CPU e RAM
    sem realizar nenhuma alteração no sistema (Modo Somente Leitura).
#>

Write-Host "[*] Iniciando auditoria de Hardware..." -ForegroundColor Cyan

# 1. Coleta de Informações do Sistema (Placa-mãe e Fabricante)
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
$bios = Get-CimInstance -ClassName Win32_BIOS

# 2. Coleta de Informações do Processador (CPU)
$cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1

# 3. Coleta de Informações de Memória RAM (Física)
$ram = Get-CimInstance -ClassName Win32_PhysicalMemory
$totalRamGB = [Math]::Round(($computerSystem.TotalPhysicalMemory / 1GB), 2)

# Verifica quantos slots estão usados e a velocidade da RAM
$slotsUsados = $ram.Count
$velocidadeRam = ($ram | Select-Object -ExpandProperty Speed -Unique) -join ", "

# 4. Criando o Objeto Estruturado (A Mágica acontece aqui)
$hardwareData = [PSCustomObject]@{
    Modulo      = "Hardware"
    DataColeta  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Sistema     = [PSCustomObject]@{
        Fabricante = $computerSystem.Manufacturer
        Modelo     = $computerSystem.Model
        Tipo       = $computerSystem.SystemType
    }
    BIOS        = [PSCustomObject]@{
        Versao       = $bios.SMBIOSBIOSVersion
        Fabricante   = $bios.Manufacturer
        DataLancamento = $bios.ReleaseDate
    }
    CPU         = [PSCustomObject]@{
        Nome         = $cpu.Name.Trim()
        NucleosFisicos = $cpu.NumberOfCores
        ProcessadoresLogicos = $cpu.NumberOfLogicalProcessors
        Arquitetura  = if ($cpu.Architecture -eq 9) { "x64" } else { "x86/Outros" }
    }
    MemoriaRAM  = [PSCustomObject]@{
        TotalInstalada_GB = $totalRamGB
        SlotsUtilizados   = $slotsUsados
        Velocidade_MHz    = $velocidadeRam
    }
}

# Define o caminho de saída para a pasta 'output' na raiz do projeto
$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\output\Hardware.json"

# Converte o objeto para JSON e salva no arquivo
$hardwareData | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[+] Auditoria de Hardware concluída! Dados salvos em: output\Hardware.json" -ForegroundColor Green