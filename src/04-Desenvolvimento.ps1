<#
.SYNOPSIS
    Development ecosystem detection module.
.DESCRIPTION
    Checks for languages, runtimes, and tools installed in the system PATH,
    safely handling complex string encodings like WSL UTF-16 output.
#>

Write-Host "[*] Starting development environment scan..." -ForegroundColor Cyan

function Get-CommandVersion {
    param (
        [string]$CommandName,
        [string]$VersionArgs = "--version"
    )

    $cmdExists = Get-Command $CommandName -ErrorAction SilentlyContinue
    if (-not $cmdExists) {
        return "Not Installed"
    }

    try {
        if ($CommandName -eq "wsl") {
            $output = & $CommandName "-v" 2>$null | Select-Object -First 1
            if ($output) {
                $output = [string]$output -replace "`0", ""
                $output = $output.Trim()
            }
            if (-not $output) {
                $output = "Installed (Subprocess Active)"
            }
        } else {
            $output = & $CommandName $VersionArgs 2>$null | Select-Object -First 1
        }

        if ($output) {
            return $output.Trim()
        }
        return "Installed (Version Unavailable)"
    }
    catch {
        return "Error reading version"
    }
}

$devTools = [PSCustomObject]@{
    Module      = "Development"
    CollectedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Tools = [PSCustomObject]@{
        Git    = Get-CommandVersion -CommandName "git" -VersionArgs "version"
        Docker = Get-CommandVersion -CommandName "docker" -VersionArgs "-v"
        WSL    = Get-CommandVersion -CommandName "wsl"
    }
    Runtimes = [PSCustomObject]@{
        Node   = Get-CommandVersion -CommandName "node" -VersionArgs "-v"
        NPM    = Get-CommandVersion -CommandName "npm" -VersionArgs "-v"
        PNPM   = Get-CommandVersion -CommandName "pnpm" -VersionArgs "-v"
        Yarn   = Get-CommandVersion -CommandName "yarn" -VersionArgs "-v"
        Python = Get-CommandVersion -CommandName "python" -VersionArgs "--version"
        Pip    = Get-CommandVersion -CommandName "pip" -VersionArgs "--version"
        Poetry = Get-CommandVersion -CommandName "poetry" -VersionArgs "--version"
    }
}

$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\output\Development.json"
$devTools | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[+] Development environment scan completed! Data saved to: output\Development.json" -ForegroundColor Green