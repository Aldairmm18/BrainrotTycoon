$base = "C:\Users\Aldair Murillo\.gemini\antigravity\scratch\BrainrotTycoon"

Write-Host "=== Preparando proyecto BrainrotTycoon para Rojo ===" -ForegroundColor Cyan

$serverScripts = @("BrainrotData", "DataStoreManager", "EconomyServer", "GachaServer")
foreach ($name in $serverScripts) {
    $old = "$base\ServerScriptService\$name.lua"
    $new = "$base\ServerScriptService\$name.server.lua"
    if (Test-Path $old) {
        Rename-Item $old $new
        Write-Host "Renombrado: $name.lua -> $name.server.lua" -ForegroundColor Green
    } elseif (Test-Path $new) {
        Write-Host "Ya existe: $name.server.lua" -ForegroundColor Yellow
    }
}

$clientScripts = @("CashDisplay", "GachaUI", "ShopUI")
foreach ($name in $clientScripts) {
    $old = "$base\StarterPlayerScripts\$name.lua"
    $new = "$base\StarterPlayerScripts\$name.client.lua"
    if (Test-Path $old) {
        Rename-Item $old $new
        Write-Host "Renombrado: $name.lua -> $name.client.lua" -ForegroundColor Green
    } elseif (Test-Path $new) {
        Write-Host "Ya existe: $name.client.lua" -ForegroundColor Yellow
    }
}

$remoteEventsPath = "$base\ReplicatedStorage\RemoteEvents"
if (-not (Test-Path $remoteEventsPath)) {
    New-Item -ItemType Directory -Path $remoteEventsPath | Out-Null
    Write-Host "Carpeta creada: ReplicatedStorage/RemoteEvents" -ForegroundColor Green
}

$metaContent = '{"className": "RemoteEvent"}'
foreach ($event in @("UpdateCash", "BuyEgg", "PlaceBrainrot")) {
    $path = "$remoteEventsPath\$event.meta.json"
    if (-not (Test-Path $path)) {
        Set-Content -Path $path -Value $metaContent
        Write-Host "Creado: $event.meta.json" -ForegroundColor Green
    }
}

Write-Host "" 
Write-Host "=== Listo! Corre: .\rojo.exe serve ===" -ForegroundColor Cyan
