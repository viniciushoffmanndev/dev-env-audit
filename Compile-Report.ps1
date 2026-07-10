<#
.SYNOPSIS
    HTML Report Compiler.
.DESCRIPTION
    This script reads the raw JSON telemetries from the 'output' directory
    and injects them into the HTML template, generating the final dashboard.
#>

Write-Host "[*] Iniciando compilação do relatório gráfico..." -ForegroundColor Cyan

# 1. Definição de caminhos
$pathOutput      = Join-Path -Path $PSScriptRoot -ChildPath "output"
$pathTemplate    = Join-Path -Path $PSScriptRoot -ChildPath "template\template.html"
$pathFinalReport = Join-Path -Path $PSScriptRoot -ChildPath "Dashboard.html"
$jsRaw           = Get-Content -Raw -Path (Join-Path $PSScriptRoot "template\js\dashboard.js")

if (-not (Test-Path $pathTemplate)) {
    Write-Error "Erro: Arquivo template.html não foi encontrado!"
    return
}

# 2. Carrega e decodifica os arquivos JSON de forma segura
$hwData      = Get-Content -Raw -Path (Join-Path $pathOutput "Hardware.json") | ConvertFrom-Json
$winData     = Get-Content -Raw -Path (Join-Path $pathOutput "Windows.json") | ConvertFrom-Json
$cacheData   = Get-Content -Raw -Path (Join-Path $pathOutput "Caches.json") | ConvertFrom-Json
$storageRaw  = Get-Content -Raw -Path (Join-Path $pathOutput "Storage.json")
$devRaw      = Get-Content -Raw -Path (Join-Path $pathOutput "Development.json")
$networkRaw  = Get-Content -Raw -Path (Join-Path $pathOutput "Network.json")

# 3. Lê o conteúdo do arquivo de template
$htmlContent = Get-Content -Raw -Path $pathTemplate

# 4. Faz as substituições das tags pelos dados reais (Casando com o padrão em inglês)
$htmlContent = $htmlContent.Replace("{{DATA_COLETA}}", $hwData.CollectedAt)
$htmlContent = $htmlContent.Replace("{{NETWORK_JSON_DATA}}", $networkRaw)

# Módulo 01: Dados do Hardware
$htmlContent = $htmlContent.Replace("{{HW_CPU}}", $hwData.CPU.Name)
$htmlContent = $htmlContent.Replace("{{HW_RAM}}", $hwData.RAM.TotalInstalled_GB)
$htmlContent = $htmlContent.Replace("{{HW_BIOS}}", $hwData.BIOS.Version)

# Módulo 02: Dados do Windows
$htmlContent = $htmlContent.Replace("{{WIN_NAME}}", $winData.OperatingSystem.Edition)
$htmlContent = $htmlContent.Replace("{{WIN_BUILD}}", $winData.OperatingSystem.Build)
$htmlContent = $htmlContent.Replace("{{WIN_BRANCH}}", $winData.OperatingSystem.Branch)
$htmlContent = $htmlContent.Replace("{{WIN_LICENSE_STATUS}}", $winData.Licensing.Status)
$htmlContent = $htmlContent.Replace("{{WIN_LICENSE_CHANNEL}}", $winData.Licensing.Channel)
$htmlContent = $htmlContent.Replace("{{WIN_LICENSE_KEY}}", $winData.Licensing.PartialKey)
$htmlContent = $htmlContent.Replace("{{WIN_UPTIME}}", "$($winData.Status.Uptime_Hours) Hours")

# Módulo 03: Dados de Armazenamento
$htmlContent = $htmlContent.Replace("{{STORAGE_JSON_DATA}}", $storageRaw)

# Módulo 04: Dados de Desenvolvimento
$htmlContent = $htmlContent.Replace("{{DEV_JSON_DATA}}", $devRaw)

# Módulo 05: Dados de Caches
$htmlContent = $htmlContent.Replace("{{CACHE_NPM}}", $cacheData.DevelopmentCaches.NPM_Cache_GB)
$htmlContent = $htmlContent.Replace("{{CACHE_PIP}}", $cacheData.DevelopmentCaches.PIP_Cache_GB)
$htmlContent = $htmlContent.Replace("{{CACHE_TEMP}}", ($cacheData.SystemTemporary.Windows_Temp_GB + $cacheData.SystemTemporary.User_Temp_GB))
$htmlContent = $htmlContent.Replace("{{CACHE_TOTAL}}", $cacheData.Summary.TotalSafeCleanup_GB)

# Injeção do Script de Comportamento Isolado
$htmlContent = $htmlContent.Replace("{{DASHBOARD_JS_SCRIPT}}", $jsRaw)

# 5. Salva o relatório final na raiz do projeto
$htmlContent | Out-File -FilePath $pathFinalReport -Encoding UTF8

Write-Host "[+] Relatório compilado com sucesso com design Premium!" -ForegroundColor Green
Write-Host "[*] Abrindo o Dashboard no seu navegador..." -ForegroundColor Yellow

# Abre o navegador nativo para exibir o resultado
Invoke-Item $pathFinalReport