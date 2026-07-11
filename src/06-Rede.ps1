<#
.SYNOPSIS
    Network and connectivity telemetry module.
.DESCRIPTION
    Collects all active network interfaces (Physical, WSL, Docker) 
    and measures core latencies for the development environment.
#>

Write-Host "[*] Starting network and latency telemetry scan..." -ForegroundColor Cyan

# 1. Coleta e mapeia TODOS os adaptadores IPv4 ativos da máquina
$interfaces = Get-NetIPAddress -AddressFamily IPv4 | 
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | 
    ForEach-Object {
        [PSCustomObject]@{
            InterfaceName = $_.InterfaceAlias
            IPAddress     = $_.IPAddress
        }
    }

# 2. Descobre qual é a interface de internet primária para extrair o Gateway real
$primaryAdapter = Get-NetIPAddress -AddressFamily IPv4 | 
    Where-Object { 
        $_.IPAddress -notlike "127.*" -and 
        $_.IPAddress -notlike "169.254.*" -and
        $_.InterfaceAlias -notlike "*WSL*" -and
        $_.InterfaceAlias -notlike "*Docker*" -and
        $_.InterfaceAlias -notlike "*vEthernet*"
    } | Select-Object -First 1

$gateway = "N/A"
if ($primaryAdapter) {
    $route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -InterfaceIndex $primaryAdapter.InterfaceIndex -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($route) { $gateway = $route.NextHop }
}

# 3. Captura IP Público com Esteira de Fallback Avançada (Resiliente a bloqueios/rotas virtuais)
$publicIP = "Offline / Blocked"
$ipServices = @(
    "https://api.ipify.org",
    "https://icanhazip.com",
    "https://ifconfig.me/ip"
)

foreach ($service in $ipServices) {
    try {
        # Usa o Invoke-RestMethod moderno com teto estrito de 2 segundos por tentativa
        $response = Invoke-RestMethod -Uri $service -TimeoutSec 2 -ErrorAction Stop
        if ($response) {
            $cleanIP = $response.ToString().Trim()
            # Validação rápida via Regex para garantir que o retorno é um formato IP válido
            if ($cleanIP -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
                $publicIP = $cleanIP
                break # Encontrou um IP válido? Aborta o loop e segue o fluxo
            }
        }
    } catch {
        # Se falhar, o foreach pula silenciosamente para o próximo resolvedor da lista
        continue
    }
}

# 4. Medição robusta de Latência usando o .NET de infraestrutura
function Measure-PingLatency ([string]$Target) {
    try {
        $pingSender = New-Object System.Net.NetworkInformation.Ping
        $timeout = 1000 # 1 segundo max
        $reply = $pingSender.Send($Target, $timeout)
        if ($reply.Status -eq "Success") {
            return $reply.RoundtripTime
        }
        return "Timeout"
    } catch {
        return "Timeout"
    }
}

Write-Host "[*] Measuring DNS and gateway latencies..." -ForegroundColor Yellow
$googlePing     = Measure-PingLatency -Target "8.8.8.8"
$cloudflarePing = Measure-PingLatency -Target "1.1.1.1"
$gatewayPing    = if ($gateway -ne "N/A") { Measure-PingLatency -Target $gateway } else { "Timeout" }

# 5. Montagem do Objeto JSON estruturado com o array de interfaces
$networkData = [PSCustomObject]@{
    Module      = "Network"
    CollectedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Addressing  = [PSCustomObject]@{
        Interfaces = $interfaces
        Gateway    = $gateway
        PublicIP   = $publicIP
    }
    Latency_ms  = [PSCustomObject]@{
        Gateway    = $gatewayPing
        Google     = $googlePing
        Cloudflare = $cloudflarePing
    }
}

# 6. Exportação segura para o arquivo JSON
$outputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\output\Network.json"
$networkData | ConvertTo-Json -Depth 4 | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "[+] Network scan completed! Data saved to: output\Network.json" -ForegroundColor Green