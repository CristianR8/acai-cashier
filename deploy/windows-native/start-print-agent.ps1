param(
  [string]$ProjectRoot = "C:\Users\This\acai-sw-cashier",
  [int]$Port = 8765,
  [string]$BindAddress = "0.0.0.0"
)

$ErrorActionPreference = "Stop"
$backendDir = Join-Path $ProjectRoot "acaipark-back"
$venvPy = Join-Path $backendDir ".venv\Scripts\python.exe"
$backendEnv = Join-Path $backendDir ".env"
$logDir = Join-Path $env:LOCALAPPDATA "AcaiPark\logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

if (!(Test-Path $venvPy) -or !(Test-Path $backendEnv)) {
  throw "Falta el entorno local del backend o su archivo .env."
}

Push-Location $backendDir
try {
  # Uvicorn escribe mensajes informativos por la salida de error. Mantener
  # Continue evita que Windows PowerShell finalice este servicio persistente.
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  & $venvPy -m uvicorn app.print_agent:app --host $BindAddress --port $Port --env-file $backendEnv *>> (Join-Path $logDir "print-agent.log")
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
  Pop-Location
}
