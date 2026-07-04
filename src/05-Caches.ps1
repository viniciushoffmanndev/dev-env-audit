<#
.SYNOPSIS
    Módulo de cálculo de tamanho de caches e arquivos temporários.
.DESCRIPTION
    Este script mede o espaço ocupado por caches de desenvolvimento (npm, pip)
    e temporários do Windows (Temp) de forma segura e somente leitura.
#>

Write-Host "[*] Iniciando varredura e cálculo de caches..." -ForegroundColor Cyan

# Função utilitária para calcular o tamanho de uma pasta em GB de forma segura
function Get-FolderSizeGB {
    param (
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return 0
    }

    try {
        # Busca todos os arquivos recursivamente, ignorando erros de acesso/permissão
        $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
        $totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
        
        if (-not $totalBytes) { $totalBytes = 0 }
        
        return [Math]::Round(($totalBytes / 1GB), 2)
    }
    catch {
        return 0
    }
}

# 1. Mapeamento dos caminhos de cache padrões no Windows
$userProfile = $env:USERPROFILE
$localAppData = $env:LOCALAPPDATA

$paths = @{
    WindowsTemp = "$env:SystemRoot\Temp"
    UserTemp    = "$localAppData\Temp"
    NpmCache    = "$userProfile\AppData\Local\npm-cache"
    PipCache    = "$localAppData\pip\Cache"
}

Write-Host "[*] Medindo caches de desenvolvimento (NPM, Pip)..." -ForegroundColor Yellow
$npmSize = Get-FolderSizeGB -Path $paths.NpmCache
$pipSize = Get-FolderSizeGB -Path $paths.PipCache

Write-Host "[*] Medindo arquivos temporários do sistema..." -ForegroundColor Yellow
$winTempSize = Get-FolderSizeGB -Path $paths.WindowsTemp
$userTempSize = Get-FolderSizeGB -Path $paths.UserTemp

# Calcula o total que pode ser limpo com segurança
$totalRecuperavel = $npmSize + $pipSize + $winTempSize + $userTempSize

# 2. Criando o Objeto Estruturado Principal
$cacheData = [PSCustomObject]@{
    Modulo      = "Caches"
    DataColeta  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    CachesDesenvolvimento = [PSCustomObject]@{
        NPM_Cache_GB = $npmSize
        PIP_Cache_GB = $pipSize
    }
    TemporariosSistema = [PSCustomObject]@{
        Windows_Temp_GB = $winTempSize
        User_Temp_GB    = $userTempSize
    }
    Resumo = [PSCustomObject]@{
        Total_Limpeza_Segura_GB = [Math]::Round($totalRecuperavel, 2)
    }
}

# 3. Define o caminho de saída e salva o JSON
$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\output\Caches.json"
$cacheData | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[+] Varredura de caches concluída! Dados salvos em: output\Caches.json" -ForegroundColor Green