<#
.SYNOPSIS
    cc1101_tcp - Fleet Deployment Script (OTA)
    
.DESCRIPTION
    Adapted from All-Seeing Eye project.
    1. Compilation: Builds the firmware using `arduino-cli`.
    2. Discovery: Reads targets from `known_hosts.txt`.
    3. Deployment: Checks status and uploads via `espota`.

.NOTES
    - Requires: Python 3, Arduino CLI, ESP32 Core (espota.exe).
    - Paths below are matching the ASE environment for user CJ.
#>

$ErrorActionPreference = "Stop"

# --- CONFIGURATION ---
$CliPath    = "C:\Users\CJ\AppData\Local\Programs\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe"
$EspOtaPath = "C:\Users\CJ\AppData\Local\Arduino15\packages\esp32\hardware\esp32\3.3.3\tools\espota.exe"
# FQBN for ESP32-S3 N16R8 (Matches ASE)
$Fqbn       = "esp32:esp32:esp32s3:CDCOnBoot=cdc,FlashSize=16M,PSRAM=opi,USBMode=hwcdc,FlashMode=qio,PartitionScheme=app3M_fat9M_16MB"

# Directories
$SketchDir  = "$PSScriptRoot\cc1101_tcp"
$BuildDir   = "$PSScriptRoot\build"
$LibPath    = "$PSScriptRoot\libraries"
$HostsFile  = "$PSScriptRoot\known_hosts.txt"

# OTA Retry Behavior
$RetryDelaySeconds = 10

# Outputs
$BinPath    = "$BuildDir\cc1101_tcp.ino.bin"
$CompileLog = "$BuildDir\compile.log"

# --- EXECUTION ---

# 0. Clean up old artifacts
Write-Host "[0/3] Cleaning up old logs..." -ForegroundColor Cyan
if (Test-Path $CompileLog) { Remove-Item $CompileLog -Force }
if (Test-Path $BuildDir) {
    Get-ChildItem -Path $BuildDir -Filter "upload_*.log" | Remove-Item -Force -ErrorAction SilentlyContinue
}
if (-not (Test-Path $BuildDir)) { New-Item -ItemType Directory -Path $BuildDir | Out-Null }

# 1. Compile Firmware
Write-Host "[1/3] Compiling Firmware..." -ForegroundColor Cyan
Write-Host "      FQBN: $Fqbn" -ForegroundColor Gray
Write-Host "      Sketch: $SketchDir" -ForegroundColor Gray

$CompileArgs = @(
    "compile",
    "--fqbn", $Fqbn,
    "--output-dir", $BuildDir,
    "--libraries", $LibPath,
    $SketchDir
)

# Run Arduino CLI
& $CliPath $CompileArgs | Out-File $CompileLog -Encoding utf8

if ($LASTEXITCODE -ne 0) {
    Write-Error "Compilation Failed! Check $CompileLog for details."
    Get-Content $CompileLog | Select-Object -Last 20
    exit 1
}
Write-Host "      Success." -ForegroundColor Green

# 2. Load Hosts
if (-not (Test-Path $HostsFile)) {
    Write-Warning "No known_hosts.txt found. Creating template."
    "192.168.1.100 # Example Node" | Out-File $HostsFile -Encoding utf8
    Write-Warning "Created template known_hosts.txt. Please populate it."
    exit 0
}

$Hosts = Get-Content $HostsFile | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+' } | ForEach-Object { $_.Split('#')[0].Trim() }

if ($Hosts.Count -eq 0) {
    Write-Warning "No valid IP addresses found in known_hosts.txt"
    exit 0
}

# 3. Deploy to Fleet
foreach ($Ip in $Hosts) {
    Write-Host "[2/3] Deploying to $Ip..." -ForegroundColor Cyan
    
    $LogFile = "$BuildDir\upload_$Ip.log"
    
    # Run ESPOTA
    # Note: Using standard port 3232, no auth
    $OtaArgs = @(
        "-i", $Ip,
        "-p", "3232",
        "-f", $BinPath
    )

    try {
        & $EspOtaPath $OtaArgs | Out-File $LogFile -Encoding utf8
        if ($LASTEXITCODE -eq 0) {
            Write-Host "      SUCCESS: $Ip" -ForegroundColor Green
        } else {
            Write-Error "      FAILED: $Ip (See $LogFile)"
        }
    } catch {
        Write-Error "      ERROR: Could not run espota for $Ip"
    }
}

Write-Host "[3/3] Fleet Deployment Complete." -ForegroundColor Cyan
