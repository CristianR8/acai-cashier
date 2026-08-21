param([string]$ProjectRoot = "C:\Users\This\acai-sw-cashier")

$ErrorActionPreference = "Stop"
& docker compose -f (Join-Path $ProjectRoot "docker-compose.yml") stop backend frontend
if ($LASTEXITCODE -ne 0) { throw "No se pudo detener el cajero." }

# PostgreSQL compartido se conserva encendido para no afectar los datos ni otros consumidores.
