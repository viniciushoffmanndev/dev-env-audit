<#
.SYNOPSIS
    Módulo de detecção do ecossistema de desenvolvimento (Versão Corrigida).
.DESCRIPTION
    Este script verifica quais linguagens, runtimes e ferramentas estão instaladas
    e trata codificações de texto especiais como o UTF-16 do WSL.
#>

Write-Host "[*] Iniciando varredura do ambiente de desenvolvimento..." -ForegroundColor Cyan

function Get-CommandVersion {
    param (
        [string]$CommandName,
        [string]$VersionArgs = "--version"
    )

    $cmdExists = Get-Command $CommandName -ErrorAction SilentlyContinue
    if (-not $cmdExists) {
        return "Não Instalado"
    }

    try {
        if ($CommandName -eq "wsl") {
            # Se for o WSL, usamos o argumento -v que traz apenas números e evita textos longos regionalizados
            $output = & $CommandName "-v" 2>$null | Select-Object -First 1
            
            # Se o output vier codificado errado, limpamos os bytes nulos e filtramos apenas o que importa (versão)
            if ($output) {
                $output = [string]$output -replace "`0", ""
                $output = $output.Trim()
            }
            
            # Se mesmo assim falhar ou vier vazio, pegamos uma resposta padrão segura
            if (-not $output) {
                $output = "Instalado (Subprocesso Ativo)"
            }
        } else {
            $output = & $CommandName $VersionArgs 2>$null | Select-Object -First 1
        }

        if ($output) {
            return $output.Trim()
        }
        return "Instalado (Versão Indisponível)"
    }
    catch {
        return "Erro ao ler versão"
    }
}

# 1. Varredura das ferramentas básicas e runtimes
$devTools = [PSCustomObject]@{
    Modulo      = "Desenvolvimento"
    DataColeta  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Ferramentas = [PSCustomObject]@{
        Git              = Get-CommandVersion -CommandName "git" -VersionArgs "version"
        Docker           = Get-CommandVersion -CommandName "docker" -VersionArgs "-v"
        WSL              = Get-CommandVersion -CommandName "wsl" -VersionArgs "--status"
    }
    Runtimes = [PSCustomObject]@{
        Node             = Get-CommandVersion -CommandName "node" -VersionArgs "-v"
        NPM              = Get-CommandVersion -CommandName "npm" -VersionArgs "-v"
        PNPM             = Get-CommandVersion -CommandName "pnpm" -VersionArgs "-v"
        Yarn             = Get-CommandVersion -CommandName "yarn" -VersionArgs "-v"
        Python           = Get-CommandVersion -CommandName "python" -VersionArgs "--version"
        Pip              = Get-CommandVersion -CommandName "pip" -VersionArgs "--version"
        Poetry           = Get-CommandVersion -CommandName "poetry" -VersionArgs "--version"
    }
}

# 2. Define o caminho de saída e salva o JSON
$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\output\Desenvolvimento.json"
$devTools | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[+] Varredura de desenvolvimento concluída! Dados salvos em: output\Desenvolvimento.json" -ForegroundColor Green