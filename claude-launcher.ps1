param(
    [string]$Model = "gemini-pro-agent"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   CliGate & Claude Code Launcher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Check Node.js Version
$nodeVersion = node -v
if (-not $?) {
    Write-Host "Node.js is not installed. Please install Node.js v24 or higher." -ForegroundColor Red
    exit 1
}

$majorVersion = [int]($nodeVersion -replace '^v', '' -replace '\..*$', '')
if ($majorVersion -lt 24) {
    Write-Host "Warning: Your Node.js version ($nodeVersion) is below v24. CliGate recommends v24+." -ForegroundColor Yellow
} else {
    Write-Host "[OK] Node.js version $nodeVersion is compatible." -ForegroundColor Green
}

# 2. Check if CliGate is installed
if (-not (Get-Command cligate -ErrorAction SilentlyContinue)) {
    Write-Host "Installing cligate globally..." -ForegroundColor Yellow
    npm install -g cligate
} else {
    Write-Host "[OK] CliGate is installed." -ForegroundColor Green
}

# 3. Check if CliGate is already running on port 8081
$portInUse = netstat -ano | Select-String ":8081" | Select-String "LISTENING"
if ($portInUse) {
    Write-Host "[OK] CliGate is already running on port 8081." -ForegroundColor Green
} else {
    Write-Host "Starting CliGate in the background..." -ForegroundColor Yellow
    Start-Process -NoNewWindow -FilePath "cligate" -ArgumentList "start"
    
    # Wait for the server to start
    Start-Sleep -Seconds 3
    
    $checkPort = netstat -ano | Select-String ":8081" | Select-String "LISTENING"
    if ($checkPort) {
        Write-Host "[OK] CliGate started successfully." -ForegroundColor Green
    } else {
        Write-Host "Failed to start CliGate! Check if another process is blocking it." -ForegroundColor Red
        exit 1
    }
}

# 4. Set Environment Variables for Claude Code
$env:ANTHROPIC_BASE_URL = "http://localhost:8081"
$env:ANTHROPIC_API_KEY = "cligate"
Write-Host "[OK] Environment variables configured for local proxy." -ForegroundColor Green

# 5. Launch Claude Code
Write-Host "Launching Claude Code with model: $Model" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
claude --model $Model
