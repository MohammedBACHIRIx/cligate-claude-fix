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

# TUI Helper Functions
function Write-Header {
    param([string]$Title)
    Clear-Host
    $w = 60
    $pad = [Math]::Max(0, [Math]::Floor(($w - 2 - $Title.Length) / 2))
    $padR = [Math]::Max(0, $w - 2 - $Title.Length - $pad)
    Write-Host "+$('-'*($w-2))+" -ForegroundColor Cyan
    Write-Host "|$(' '*$pad)$Title$(' '*$padR)|" -ForegroundColor White -BackgroundColor DarkCyan
    Write-Host "+$('-'*($w-2))+" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Status, [string]$Message)
    switch ($Status) {
        "OK"   { Write-Host "[  OK  ] " -NoNewline -ForegroundColor Green }
        "WARN" { Write-Host "[ WARN ] " -NoNewline -ForegroundColor Yellow }
        "FAIL" { Write-Host "[ FAIL ] " -NoNewline -ForegroundColor Red }
        "INFO" { Write-Host "[ INFO ] " -NoNewline -ForegroundColor Cyan }
    }
    Write-Host $Message -ForegroundColor White
}

function Check-Port {
    param([int]$Port)
    $listeners = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
    return [bool]($listeners | Where-Object { $_.Port -eq $Port })
}

# ====================================================================

Write-Header "Claude Code + CliGate Setup Environment"

# 1. Install/Verify Node.js
Write-Host "`n-- [1/5] Checking Node.js Installation --" -ForegroundColor Cyan
$nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeInstalled) {
    Write-Step "INFO" "Node.js not found. Installing via winget..."
    winget install OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
    
    Write-Host ""
    Write-Host "+---------------------------------------------------------+" -ForegroundColor Red
    Write-Host "| Node.js was just installed. You MUST restart PowerShell |" -ForegroundColor Red
    Write-Host "| to update your PATH before running this script again.   |" -ForegroundColor Red
    Write-Host "+---------------------------------------------------------+" -ForegroundColor Red
    exit
} else {
    try {
        $nodeVer = node -v 2>&1
        $nodeVersionStr = [string]$nodeVer -replace '(?s)\r?\n.*',''
        Write-Step "OK" "Node.js is installed ($nodeVersionStr)"
    } catch {
        Write-Step "WARN" "Node.js is installed but could not retrieve version."
    }
}

# 2. Install CliGate
Write-Host "`n-- [2/5] Installing CliGate proxy --" -ForegroundColor Cyan
$cligateInstalled = $false
if (-not (Get-Command cligate -ErrorAction SilentlyContinue)) {
    Write-Step "INFO" "Installing cligate globally via npm..."
    npm install -g cligate > $null 2>&1
    if ($LASTEXITCODE -eq 0) { 
        Write-Step "OK" "CliGate installed successfully." 
        $cligateInstalled = $true
    } else {
        Write-Step "FAIL" "Failed to install CliGate."
    }
} else {
    Write-Step "OK" "CliGate is already installed."
    $cligateInstalled = $true
}

if ($cligateInstalled) {
    try {
        $npmRoot = (npm root -g).Trim()
        $targetFile = Join-Path $npmRoot "cligate\src\routes\chat-route.js"
        $patchFile = Join-Path $PSScriptRoot "patches\chat-route.js"
        
        if (Test-Path $targetFile) {
            Write-Step "INFO" "Applying Antigravity chat routing patch to: $targetFile"
            Copy-Item -Path $patchFile -Destination $targetFile -Force
            Write-Step "OK" "Patch applied successfully."
        } else {
            Write-Step "WARN" "Could not find cligate chat-route.js to patch at: $targetFile"
        }
    } catch {
        Write-Step "WARN" "Failed to apply completions patch: $_"
    }
}

# 3. Install Claude Code
Write-Host "`n-- [3/5] Installing Claude Code --" -ForegroundColor Cyan
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Step "INFO" "Installing @anthropic-ai/claude-code globally..."
    npm install -g @anthropic-ai/claude-code > $null 2>&1
    if ($LASTEXITCODE -eq 0) { 
        Write-Step "OK" "Claude Code installed successfully." 
    } else {
        Write-Step "FAIL" "Failed to install Claude Code."
    }
} else {
    Write-Step "OK" "Claude Code is already installed."
}

# 4. Configure PowerShell Profile permanently
Write-Host "`n-- [4/5] Configuring PowerShell Profile for Persistent Routing --" -ForegroundColor Cyan
$profilePath = $PROFILE
if (-not (Test-Path -Path $profilePath)) {
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
    Write-Step "INFO" "Created new PowerShell profile at: $profilePath"
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
    Write-Step "OK" "Added ANTHROPIC_BASE_URL & ANTHROPIC_API_KEY to`n         your profile ($profilePath)"
    
    # Apply to current session immediately
    $env:ANTHROPIC_BASE_URL = "http://localhost:8081"
    $env:ANTHROPIC_API_KEY = "cligate"
} else {
    Write-Step "OK" "Routing variables already exist in profile."
}

# 5. Start CliGate
Write-Host "`n-- [5/5] Checking CliGate Server --" -ForegroundColor Cyan
if (-not (Check-Port 8081)) {
    Write-Step "INFO" "Starting CliGate in the background..."
    Start-Process -WindowStyle Hidden -FilePath "cmd.exe" -ArgumentList "/c cligate start"
    
    # Fast polling with spinner
    $timeout = 50
    $started = $false
    $spinners = @("-", "\", "|", "/")
    $i = 0
    while ($timeout -gt 0) {
        if (Check-Port 8081) {
            $started = $true
            Write-Host "`r$([string]::new(' ', 60))`r" -NoNewline
            break
        }
        $s = $spinners[$i % 4]
        Write-Host "`r[  $s   ] Waiting for server on port 8081..." -NoNewline -ForegroundColor Yellow
        $i++
        Start-Sleep -Milliseconds 100
        $timeout--
    }
    
    if ($started) {
        Write-Step "OK" "CliGate server started and ready."
        
        # Ensure routingMode is set to app-assigned in cligate settings
        $settingsPath = Join-Path [System.Environment]::GetFolderPath('UserProfile') ".cligate\settings.json"
        Start-Sleep -Seconds 1
        if (Test-Path $settingsPath) {
            try {
                $settingsContent = Get-Content $settingsPath -Raw
                if ($settingsContent -match '"routingMode":\s*"automatic"') {
                    $settingsContent = $settingsContent -replace '"routingMode":\s*"automatic"', '"routingMode": "app-assigned"'
                    Set-Content -Path $settingsPath -Value $settingsContent
                    Write-Step "OK" "Configured settings.json to use app-assigned routing."
                }
            } catch {
                Write-Step "WARN" "Failed to update settings.json: $_"
            }
        }
    } else {
        Write-Host "`r$([string]::new(' ', 60))`r" -NoNewline
        Write-Step "FAIL" "CliGate server did not bind port 8081 in time."
    }
} else {
    Write-Step "OK" "CliGate server is already running."
    
    # Ensure routingMode is set to app-assigned in cligate settings
    $settingsPath = Join-Path [System.Environment]::GetFolderPath('UserProfile') ".cligate\settings.json"
    if (Test-Path $settingsPath) {
        try {
            $settingsContent = Get-Content $settingsPath -Raw
            if ($settingsContent -match '"routingMode":\s*"automatic"') {
                $settingsContent = $settingsContent -replace '"routingMode":\s*"automatic"', '"routingMode": "app-assigned"'
                Set-Content -Path $settingsPath -Value $settingsContent
                Write-Step "OK" "Configured settings.json to use app-assigned routing."
            }
        } catch {
            Write-Step "WARN" "Failed to update settings.json: $_"
        }
    }
}

# Final Instructions
Write-Host "`n"
Write-Header "SETUP COMPLETE!"
Write-Host "IMPORTANT NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. If this is your first time using CliGate, you must authenticate:"
Write-Host "   Run: " -NoNewline; Write-Host "cligate accounts add" -ForegroundColor Cyan
Write-Host "2. Once logged in, you can launch Claude Code with the Gemini model:"
Write-Host "   Run: " -NoNewline; Write-Host "claude --model gemini-pro-agent" -ForegroundColor Cyan
Write-Host ""
