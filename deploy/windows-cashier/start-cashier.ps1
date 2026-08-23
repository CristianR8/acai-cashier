param(
  [string]$ProjectRoot = "C:\Users\This\acai-sw-cashier"
)

$ErrorActionPreference = "Stop"
$composeFile = Join-Path $ProjectRoot "docker-compose.yml"
$printAgentScript = Join-Path $ProjectRoot "deploy\windows-native\start-print-agent.ps1"
$launcherLog = Join-Path $ProjectRoot "logs\cashier-launcher.log"
New-Item -ItemType Directory -Force -Path (Split-Path $launcherLog -Parent) | Out-Null

trap {
  "[$(Get-Date -Format s)] $($_ | Out-String)" | Add-Content -Path $launcherLog -Encoding UTF8
  exit 1
}

function Test-DockerReady {
  # Cuando Docker Desktop todavía está arrancando, docker.exe escribe el error
  # en stderr. Con $ErrorActionPreference = Stop PowerShell lo trataba como una
  # excepción y el lanzador terminaba antes de poder abrir Docker Desktop.
  # Ejecutarlo mediante cmd descarta esa salida esperada y conserva el código
  # de salida para saber si el daemon ya está disponible.
  & cmd.exe /d /c 'docker version --format "{{.Server.Version}}" >NUL 2>&1'
  return $LASTEXITCODE -eq 0
}

function Wait-Until {
  param([scriptblock]$Condition, [int]$TimeoutSeconds, [string]$Description)
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    if (& $Condition) { return }
    Start-Sleep -Seconds 2
  }
  throw "Tiempo de espera agotado: $Description"
}

if (!(Test-Path $composeFile)) { throw "No se encontró $composeFile" }

if (!(Test-DockerReady)) {
  $dockerDesktop = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
  if (!(Test-Path $dockerDesktop)) { throw "Docker Desktop no está instalado." }
  Start-Process -FilePath $dockerDesktop | Out-Null
  Wait-Until -Condition ${function:Test-DockerReady} -TimeoutSeconds 120 -Description "Docker Desktop"
}

# Usa exclusivamente la base existente: nunca crea ni reemplaza contenedores o volúmenes PostgreSQL.
$dbState = & docker inspect -f '{{.State.Running}}' acaipark-db 2>$null
if ($LASTEXITCODE -ne 0) {
  throw "No se encontró la base compartida acaipark-db. El lanzador no creará otra base de datos."
}
if ($dbState.Trim() -ne "true") { & docker start acaipark-db | Out-Null }
Wait-Until -Condition { (& docker inspect -f '{{.State.Health.Status}}' acaipark-db 2>$null).Trim() -eq "healthy" } -TimeoutSeconds 90 -Description "PostgreSQL compartido"

# El agente se ejecuta en Windows para acceder a la impresora USB. Solo se inicia si no existe.
if (!(Get-NetTCPConnection -LocalPort 8765 -State Listen -ErrorAction SilentlyContinue)) {
  Start-Process -FilePath powershell.exe -ArgumentList @(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $printAgentScript,
    "-ProjectRoot", $ProjectRoot
  ) -WindowStyle Hidden | Out-Null
  Wait-Until -Condition { Get-NetTCPConnection -LocalPort 8765 -State Listen -ErrorAction SilentlyContinue } -TimeoutSeconds 30 -Description "agente de impresión"
}

& docker compose -f $composeFile up -d backend frontend
if ($LASTEXITCODE -ne 0) { throw "No se pudo iniciar el cajero." }

Wait-Until -Condition {
  try {
    (Invoke-WebRequest -UseBasicParsing "http://localhost:3001" -TimeoutSec 5).StatusCode -eq 200
  } catch { $false }
} -TimeoutSeconds 120 -Description "frontend del cajero"

Start-Process "http://localhost:3001"
