param(
    [string]$Model = "gemini-pro-agent"
)

# TUI Helper Functions
function Write-Header {
    param([string]$Title)
    Clear-Host
    $w = 50
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

Write-Header "CliGate & Claude Code Launcher"

# 1. Check Node.js Version
try {
    $nodeVersion = node -v 2>&1
    if ($LASTEXITCODE -eq 0 -or $nodeVersion -match "^v\d+") {
        $nodeVersionStr = [string]$nodeVersion -replace '(?s)\r?\n.*',''
        $majorVersion = [int]($nodeVersionStr -replace '^v', '' -replace '\..*$', '')
        if ($majorVersion -lt 24) {
            Write-Step "WARN" "Node.js $nodeVersionStr (v24+ recommended)"
        } else {
            Write-Step "OK" "Node.js $nodeVersionStr identified"
        }
    } else {
        throw "Node not found"
    }
} catch {
    Write-Step "FAIL" "Node.js not installed. Please install Node.js v24+"
    exit 1
}

# 2. Check if CliGate is installed
if (-not (Get-Command cligate -ErrorAction SilentlyContinue)) {
    Write-Step "INFO" "Installing cligate globally (this may take a moment)..."
    npm install -g cligate > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Step "OK" "CliGate installed successfully."
    } else {
        Write-Step "FAIL" "npm install cligate failed."
        exit 1
    }
} else {
    Write-Step "OK" "CliGate package is installed."
}

# 3. Check and Start CliGate on port 8081
if (Check-Port 8081) {
    Write-Step "OK" "CliGate server is ready on port 8081."
} else {
    Write-Step "INFO" "Starting CliGate in the background..."
    Start-Process -WindowStyle Hidden -FilePath "cmd.exe" -ArgumentList "/c cligate start"
    
    # Wait for the server to start (Polling up to 5 seconds)
    $timeout = 50 
    $started = $false
    $spinners = @("-", "\", "|", "/")
    $i = 0
    while ($timeout -gt 0) {
        if (Check-Port 8081) {
            $started = $true
            # Clear spinner
            Write-Host "`r$([string]::new(' ', 50))`r" -NoNewline
            break
        }
        $s = $spinners[$i % 4]
        Write-Host "`r[  $s   ] Waiting for server to bind port 8081..." -NoNewline -ForegroundColor Yellow
        $i++
        Start-Sleep -Milliseconds 100
        $timeout--
    }
    
    if ($started) {
        Write-Step "OK" "CliGate server started successfully."
    } else {
        Write-Host "`r$([string]::new(' ', 50))`r" -NoNewline
        Write-Step "FAIL" "Failed to start CliGate! Check if another process is blocking it."
        exit 1
    }
}

# 4. Set Environment Variables for Claude Code
$env:ANTHROPIC_BASE_URL = "http://localhost:8081"
$env:ANTHROPIC_API_KEY = "cligate"
Write-Step "OK" "Environment variables configured (proxy active)."

# 5. Launch Claude Code
Write-Host ""
Write-Header "Launching Claude Code ($Model)"

# Launch Claude Code. This will block execution until Claude exits.
claude --model $Model --dangerously-skip-permissions

# 6. Post-Flight: Graceful Multiple Session Shutdown Logic
Write-Host ""
Write-Step "INFO" "Claude session ended. Checking for other active sessions..."

# Short grace period for processes to exit
Start-Sleep -Milliseconds 500

$otherSessions = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { 
    ($null -ne $_.CommandLine) -and
    ($_.CommandLine -match "claude(\.exe|\.cmd|\.js|\s|$)") -and 
    ($_.Name -match "(node\.exe|claude\.exe)") -and 
    ($_.ProcessId -ne $PID)
})

if ($otherSessions.Count -eq 0) {
    Write-Step "INFO" "No other Claude sessions found. Shutting down CliGate server..."
    
    # Find the exact process bounded to Port 8081 to safely kill only the CliGate server
    $netstat = netstat -ano | Select-String ":8081" | Select-String "LISTENING"
    if ($netstat) {
        $line = ($netstat -split '\r?\n')[0]
        $cligatePID = ($line -split '\s+')[-1]
        
        if ($cligatePID -match "^\d+$" -and $cligatePID -ne "0") {
            Stop-Process -Id $cligatePID -Force -ErrorAction SilentlyContinue
            Write-Step "OK" "CliGate server (PID $cligatePID) shutdown successfully."
        }
    } else {
        Write-Step "WARN" "CliGate server was already stopped."
    }
} else {
    Write-Step "INFO" "$($otherSessions.Count) other Claude session(s) active. Leaving CliGate running."
}
