<#
.SYNOPSIS
    Módulo de coleta de dados do Sistema Operacional (Windows).
.DESCRIPTION
    Este script coleta informações sobre a versão do Windows, build
    e calcula o tempo de atividade (Uptime) do notebook.
#>

Write-Host "[*] Iniciando auditoria do Windows..." -ForegroundColor Cyan

# 1. Coleta de Informações do Sistema Operacional
$os = Get-CimInstance -ClassName Win32_OperatingSystem

# 2. Cálculo de Uptime (Tempo que o PC está ligado)
$tempoLigado = (Get-Date) - $os.LastBootUpTime

# 3. Criando o Objeto Estruturado
$windowsData = [PSCustomObject]@{
    Modulo      = "Windows"
    DataColeta  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    SistemaOperacional = [PSCustomObject]@{
        Edicao      = $os.Caption.Replace("Microsoft ", "").Trim()
        Versao      = $os.Version
        Build       = $os.BuildNumber
        Arquitetura = $os.OSArchitecture
    }
    Status = [PSCustomObject]@{
        UltimoBoot          = $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss")
        TempoLigado_Horas   = [Math]::Round($tempoLigado.TotalHours, 2)
        TempoLigado_Dias    = [Math]::Round($tempoLigado.TotalDays, 2)
    }
}

# Define o caminho de saída
$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\output\Windows.json"

# Converte e salva
$windowsData | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[+] Auditoria do Windows concluída! Dados salvos em: output\Windows.json" -ForegroundColor Green