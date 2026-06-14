<#
.SYNOPSIS
    Automated Installer for Claude Code + CliGate + Gemini 3.1 Pro setup.
    
.DESCRIPTION
    This script will:
    1. Install Node.js (v24+) via winget if not installed.
    2. Install the 'cligate' proxy globally via npm.
    3. Install '@anthropic-ai/claude-code' globally via npm.
    4. Configure your PowerShell profile permanently so Claude Code always routes to the local proxy.
    5. Start the CliGate proxy server.
#>

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  Claude Code + CliGate Automated Setup Environment" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Install/Verify Node.js
Write-Host "[1/5] Checking Node.js Installation..." -ForegroundColor Yellow
$nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeInstalled) {
    Write-Host "Node.js not found. Installing via winget..." -ForegroundColor Magenta
    winget install OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
    
    Write-Host ""
    Write-Host "=========================================================" -ForegroundColor Red
    Write-Host " Node.js was just installed. You MUST restart PowerShell " -ForegroundColor Red
    Write-Host " to update your PATH before running this script again.   " -ForegroundColor Red
    Write-Host "=========================================================" -ForegroundColor Red
    exit
} else {
    $nodeVer = node -v
    Write-Host "[OK] Node.js is installed ($nodeVer)" -ForegroundColor Green
}

# 2. Install CliGate
Write-Host "`n[2/5] Installing CliGate proxy..." -ForegroundColor Yellow
npm install -g cligate
if ($?) { Write-Host "[OK] CliGate installed successfully." -ForegroundColor Green }

# 3. Install Claude Code
Write-Host "`n[3/5] Installing Claude Code..." -ForegroundColor Yellow
npm install -g @anthropic-ai/claude-code
if ($?) { Write-Host "[OK] Claude Code installed successfully." -ForegroundColor Green }

# 4. Configure PowerShell Profile permanently
Write-Host "`n[4/5] Configuring PowerShell Profile for Persistent Routing..." -ForegroundColor Yellow
$profilePath = $PROFILE
if (-not (Test-Path -Path $profilePath)) {
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
    Write-Host "Created new PowerShell profile at: $profilePath" -ForegroundColor DarkGray
}

$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
$exportLines = @"

# === CLIGATE CLAUDE CODE ROUTING ===
`$env:ANTHROPIC_BASE_URL = "http://localhost:8081"
`$env:ANTHROPIC_API_KEY = "cligate"
# ===================================
"@

if ($profileContent -notmatch "ANTHROPIC_BASE_URL") {
    Add-Content -Path $profilePath -Value $exportLines
    Write-Host "[OK] Added ANTHROPIC_BASE_URL and ANTHROPIC_API_KEY to your `$PROFILE" -ForegroundColor Green
    
    # Apply to current session immediately
    $env:ANTHROPIC_BASE_URL = "http://localhost:8081"
    $env:ANTHROPIC_API_KEY = "cligate"
} else {
    Write-Host "[OK] Routing variables already exist in `$PROFILE" -ForegroundColor Green
}

# 5. Start CliGate
Write-Host "`n[5/5] Checking CliGate Server..." -ForegroundColor Yellow
$portInUse = netstat -ano | Select-String ":8081" | Select-String "LISTENING"
if (-not $portInUse) {
    Write-Host "Starting CliGate in the background..." -ForegroundColor Magenta
    Start-Process -NoNewWindow -FilePath "cligate" -ArgumentList "start"
    Start-Sleep -Seconds 3
    Write-Host "[OK] CliGate server started." -ForegroundColor Green
} else {
    Write-Host "[OK] CliGate server is already running." -ForegroundColor Green
}

# Final Instructions
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETE! [YAY]" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. If this is your first time using CliGate, you must authenticate:"
Write-Host "   Run: " -NoNewline; Write-Host "cligate login" -ForegroundColor Cyan
Write-Host "2. Once logged in, you can launch Claude Code with the Gemini model:"
Write-Host "   Run: " -NoNewline; Write-Host "claude --model gemini-pro-agent" -ForegroundColor Cyan
Write-Host ""
