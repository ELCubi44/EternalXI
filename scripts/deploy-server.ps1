# Compila el JAR del backend, lo sube al VPS y reinicia miapi.service
# Requiere: .local/deploy.env y .local/tools/pscp.exe + plink.exe

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $repoRoot '.local\deploy.env'
$toolsDir = Join-Path $repoRoot '.local\tools'
$pscp = Join-Path $toolsDir 'pscp.exe'
$plink = Join-Path $toolsDir 'plink.exe'

function Read-DeployEnv {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "No existe $Path. Crea el archivo de configuración local."
    }
    $vars = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { return }
        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { return }
        $key = $line.Substring(0, $idx).Trim()
        $val = $line.Substring($idx + 1).Trim()
        $vars[$key] = $val
    }
    return $vars
}

function Ensure-PuttyTools {
    param([string]$Dir)
    New-Item -ItemType Directory -Force -Path $Dir | Out-Null
    $base = 'https://the.earth.li/~sgtatham/putty/latest/w64'
    foreach ($name in @('pscp.exe', 'plink.exe')) {
        $dest = Join-Path $Dir $name
        if (-not (Test-Path $dest)) {
            Write-Host "Descargando $name..."
            Invoke-WebRequest -Uri "$base/$name" -OutFile $dest
        }
    }
}

function Invoke-Remote {
    param(
        [string]$Plink,
        [string]$HostName,
        [int]$Port,
        [string]$User,
        [string]$Password,
        [string]$Command,
        [string]$HostKey
    )
    & $Plink -batch -ssh -P $Port -hostkey $HostKey -pw $Password "${User}@${HostName}" $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Comando remoto falló (exit $LASTEXITCODE): $Command"
    }
}

$config = Read-DeployEnv -Path $envFile
Ensure-PuttyTools -Dir $toolsDir

$hostKey = $config['DEPLOY_SSH_HOSTKEY']
if ([string]::IsNullOrWhiteSpace($hostKey)) {
    $hostKey = 'SHA256:hY3FHVobNY7HffYE9Dv2vv/wnnaypHVytyvto4YOlVI'
}

$hostName = $config['DEPLOY_SSH_HOST']
$port = [int]$config['DEPLOY_SSH_PORT']
$user = $config['DEPLOY_SSH_USER']
$password = $config['DEPLOY_SSH_PASSWORD']
$remoteDir = $config['DEPLOY_REMOTE_DIR'].TrimEnd('/')
$remoteJar = $config['DEPLOY_REMOTE_JAR']
$service = $config['DEPLOY_SYSTEMD_SERVICE']
$backendDir = Join-Path $repoRoot $config['DEPLOY_BACKEND_DIR']
$jarName = $config['DEPLOY_JAR_NAME']
$localJar = Join-Path $backendDir "target\$jarName"
$remotePath = "$remoteDir/$remoteJar"

Write-Host '==> 1/4 Compilando backend (Maven)...'
Push-Location $backendDir
try {
    & .\mvnw.cmd -q -DskipTests package
    if ($LASTEXITCODE -ne 0) {
        throw "Maven falló con código $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

if (-not (Test-Path $localJar)) {
    throw "No se generó el JAR en $localJar"
}

Write-Host "==> 2/4 Subiendo JAR a ${user}@${hostName}:${remotePath} ..."
& $pscp -batch -P $port -hostkey $hostKey -pw $password $localJar "${user}@${hostName}:${remotePath}"
if ($LASTEXITCODE -ne 0) {
    throw "pscp falló con código $LASTEXITCODE"
}

Write-Host "==> 3/4 Reiniciando servicio $service ..."
Invoke-Remote -Plink $plink -HostName $hostName -Port $port -User $user -Password $password -HostKey $hostKey `
    -Command "systemctl restart $service"

Write-Host '==> 4/4 Comprobando estado del servicio...'
Start-Sleep -Seconds 3
Invoke-Remote -Plink $plink -HostName $hostName -Port $port -User $user -Password $password -HostKey $hostKey `
    -Command "systemctl is-active $service && systemctl status $service --no-pager -n 5"

Write-Host ''
Write-Host 'Despliegue completado.' -ForegroundColor Green
Write-Host "JAR activo: $remotePath"
