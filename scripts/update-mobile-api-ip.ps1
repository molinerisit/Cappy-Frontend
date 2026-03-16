param(
  [int]$BackendPort = 3000
)

$ErrorActionPreference = 'Stop'

function Get-LanIPv4 {
  $route = Get-NetRoute -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' |
    Where-Object { $_.NextHop -ne '0.0.0.0' } |
    Sort-Object -Property RouteMetric, InterfaceMetric |
    Select-Object -First 1

  if ($route) {
    $ip = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $route.InterfaceIndex |
      Where-Object {
        $_.IPAddress -match '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)'
      } |
      Select-Object -ExpandProperty IPAddress -First 1

    if ($ip) {
      return $ip
    }
  }

  $fallback = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
      $_.IPAddress -match '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)'
    } |
    Select-Object -ExpandProperty IPAddress -First 1

  if ($fallback) {
    return $fallback
  }

  throw 'No se pudo detectar una IPv4 LAN privada.'
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$envPath = Join-Path $frontendRoot 'config/env/.env.development'
$networkConfigPath = Join-Path $frontendRoot 'android/app/src/main/res/xml/network_security_config.xml'

$lanIp = Get-LanIPv4
$apiBaseUrl = "http://$lanIp`:$BackendPort/api"

if (-not (Test-Path $envPath)) {
  throw "No existe $envPath"
}

$envContent = Get-Content -Path $envPath -Raw
if ($envContent -match '(?m)^API_BASE_URL=') {
  $envContent = [regex]::Replace(
    $envContent,
    '(?m)^API_BASE_URL=.*$',
    "API_BASE_URL=$apiBaseUrl"
  )
} else {
  if ($envContent -notmatch '\r?\n$') {
    $envContent += "`r`n"
  }
  $envContent += "API_BASE_URL=$apiBaseUrl`r`n"
}
Set-Content -Path $envPath -Value $envContent -Encoding UTF8

if (-not (Test-Path $networkConfigPath)) {
  throw "No existe $networkConfigPath"
}

$xmlContent = Get-Content -Path $networkConfigPath -Raw
$xmlContent = [regex]::Replace(
  $xmlContent,
  '(?m)^\s*<domain includeSubdomains="false">(192\.168\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]+\.[0-9]+|10\.(?!0\.2\.2)[0-9]+\.[0-9]+\.[0-9]+)</domain>\s*\r?\n?',
  ''
)

$lanDomainLine = "        <domain includeSubdomains=`"false`">$lanIp</domain>`r`n"
$lanDomainBare = "<domain includeSubdomains=`"false`">$lanIp</domain>"

if ($xmlContent -notmatch [regex]::Escape($lanDomainBare)) {
  if ($xmlContent -match '<domain includeSubdomains="false">10\.0\.2\.2</domain>') {
    $xmlContent = $xmlContent -replace '(<domain includeSubdomains="false">10\.0\.2\.2</domain>\r?\n)', "`$1$lanDomainLine"
  } else {
    $xmlContent = $xmlContent -replace '(\r?\n\s*</domain-config>)', "`r`n        <domain includeSubdomains=`"false`">10.0.2.2</domain>`r`n$lanDomainLine`$1"
  }
}

Set-Content -Path $networkConfigPath -Value $xmlContent -Encoding UTF8

Write-Host "LAN IP detectada: $lanIp"
Write-Host "API_BASE_URL actualizada: $apiBaseUrl"
Write-Host "Android network_security_config.xml actualizado con $lanIp"
Write-Host ""
Write-Host "Siguiente comando recomendado:"
Write-Host "flutter run --dart-define-from-file=config/env/.env.development"
