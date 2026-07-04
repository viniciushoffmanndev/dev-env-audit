<#
.SYNOPSIS
    Módulo de coleta de dados de Armazenamento (Discos).
.DESCRIPTION
    Este script coleta informações sobre os discos lógicos instalados,
    calculando o espaço total, espaço livre e a porcentagem de uso.
#>

Write-Host "[*] Iniciando auditoria de Armazenamento..." -ForegroundColor Cyan

# 1. Coleta os Discos Lógicos Locais (DriveType = 3 significa discos rígidos/SSDs locais)
$discos = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"

$listaDiscos = @()

# 2. Processa cada disco encontrado
foreach ($disco in $discos) {
    $espacoTotalGB = [Math]::Round(($disco.Size / 1GB), 2)
    $espacoLivreGB = [Math]::Round(($disco.FreeSpace / 1GB), 2)
    $espacoUsadoGB = $espacoTotalGB - $espacoLivreGB
    
    # Prevenção de divisão por zero caso haja algum erro de leitura
    $porcentagemUso = 0
    if ($espacoTotalGB -gt 0) {
        $porcentagemUso = [Math]::Round((($espacoUsadoGB / $espacoTotalGB) * 100), 2)
    }

    $dadosDisco = [PSCustomObject]@{
        Letra         = $disco.DeviceID
        NomeVolume    = $disco.VolumeName
        SistemaArquivo = $disco.FileSystem
        Total_GB      = $espacoTotalGB
        Livre_GB      = $espacoLivreGB
        Usado_GB      = $espacoUsadoGB
        Uso_Porcentagem = $porcentagemUso
    }
    
    $listaDiscos += $dadosDisco
}

# 3. Criando o Objeto Estruturado Principal
$armazenamentoData = [PSCustomObject]@{
    Modulo      = "Armazenamento"
    DataColeta  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Discos      = $listaDiscos
}

# 4. Define o caminho de saída e salva o JSON
$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\output\Armazenamento.json"
$armazenamentoData | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[+] Auditoria de Armazenamento concluída! Dados salvos em: output\Armazenamento.json" -ForegroundColor Green