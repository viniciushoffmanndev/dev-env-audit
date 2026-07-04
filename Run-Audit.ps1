<#
.SYNOPSIS
    Orquestrador principal do dev-env-audit (Versão Corrigida).
.DESCRIPTION
    Este script roda todos os módulos de auditoria localizados na pasta 'src'
    e centraliza o fluxo de diagnóstico de forma automatizada.
#>

Clear-Host
Write-Host "==================================================" -ForegroundColor DarkBlue
Write-Host "          DEV-ENV-AUDIT - ORQUESTRADOR             " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor DarkBlue
Write-Host "Iniciando varredura completa do sistema...`n" -ForegroundColor White

# 1. Garante que a pasta 'output' exista na raiz do projeto
$outputFolder = Join-Path -Path $PSScriptRoot -ChildPath "output"
if (-not (Test-Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory | Out-Null
}

# 2. Mapeia e ordena todos os scripts dentro da pasta 'src'
$modulos = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "src") -Filter "*.ps1" | Sort-Object Name

# 3. Executa cada módulo sequencialmente
foreach ($modulo in $modulos) {
    Write-Host "--------------------------------------------------" -ForegroundColor Gray
    Write-Host "[MÓDULO] Executando: $($modulo.Name)" -ForegroundColor Yellow
    
    # Invoca o script do módulo
    & $modulo.FullName
}

Write-Host "`n==================================================" -ForegroundColor DarkBlue
Write-Host "  [SUCESSO] Auditoria completa finalizada!         " -ForegroundColor Green
Write-Host "  Todos os relatórios estruturados estão em 'output'" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor DarkBlue