$ErrorActionPreference = "Stop"

$ServiceName = "Velociraptor"
$ServerBaseUrl = "http://192.168.56.10:8080"

$DeployDir = "C:\ProgramData\VeloDeploy"
$ExePath = Join-Path $DeployDir "velociraptor.exe"
$ConfigPath = Join-Path $DeployDir "client.config.yaml"

Write-Host "=== Velociraptor deployment started ==="

# 1. Проверяем, установлен ли Velociraptor
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($null -eq $service) {

    Write-Host "Velociraptor service not found. Installing..."

    # 2. Создаём рабочий каталог
    if (-not (Test-Path $DeployDir)) {
        New-Item -ItemType Directory -Path $DeployDir -Force | Out-Null
        Write-Host "Created deployment directory: $DeployDir"
    }

    # 3. Получаем бинарник
    Write-Host "Downloading Velociraptor binary..."
    Invoke-WebRequest `
        "$ServerBaseUrl/velociraptor.exe" `
        -OutFile $ExePath

    # 4. Получаем конфигурацию
    Write-Host "Downloading client configuration..."
    Invoke-WebRequest `
        "$ServerBaseUrl/client.config.yaml" `
        -OutFile $ConfigPath

    # 5. Устанавливаем службу
    Write-Host "Installing Velociraptor service..."

    & $ExePath service install --config $ConfigPath

    if ($LASTEXITCODE -ne 0) {
        throw "Velociraptor service installation failed."
    }

    Write-Host "Velociraptor installed successfully."
}
else {
    Write-Host "Velociraptor is already installed."
}

# 6. Гарантируем, что служба запущена
$service = Get-Service -Name $ServiceName -ErrorAction Stop

if ($service.Status -ne "Running") {
    Write-Host "Velociraptor service is stopped. Starting..."
    Start-Service $ServiceName
}
else {
    Write-Host "Velociraptor service is already running."
}

$service = Get-Service -Name $ServiceName

Write-Host ""
Write-Host "Final service state:"
$service | Format-Table Name, Status

Write-Host "=== Deployment finished ==="
