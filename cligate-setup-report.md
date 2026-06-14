# CliGate & Claude Code Setup Report

## Overview
This report documents the troubleshooting process and final configuration required to successfully run **Claude Code** powered by **Gemini 3.1 Pro** using the **CliGate** local proxy.

---

## 1. Initial Setup & Issues Encountered

### Issue A: Node.js Version Incompatibility
- **Symptom:** `cligate` failed to start initially.
- **Root Cause:** The `cligate` package (v1.3.1) requires Node.js `v24` or higher, but the system was running `v20.19.6` / `v22.22.3`.
- **Resolution:** Upgraded Node.js using `winget upgrade OpenJS.NodeJS.LTS`.

### Issue B: Proxy Server State and Port Conflicts
- **Symptom:** Claude Code hung on `Retrying in 0s attempt 2/10`.
- **Root Cause:** The `cligate` server processes were running in a broken state (Node process zombie on port 8081) and were not gracefully closed when the background tasks were stopped.
- **Resolution:** Used `Stop-Process` to forcefully terminate lingering `node` processes on port 8081 and performed a clean restart of the proxy.

### Issue C: Claude Code Model Compatibility
- **Symptom:** Claude Code received a `500 API Error: All accounts and API keys exhausted`.
- **Root Cause:**
  1. Claude Code defaults to Anthropic-specific tool-calling schemas.
  2. When requesting the raw model ID `gemini-3.1-pro-high`, the upstream Antigravity API rejected the payload with an `INVALID_ARGUMENT` error because the raw model does not natively map Anthropic's agent schemas.
  3. When requesting `gemini-2.5-pro`, the API returned `MODEL_CAPACITY_EXHAUSTED`.
- **Resolution:** Discovered and utilized the `gemini-pro-agent` model alias. This specific endpoint inside the proxy is designed to seamlessly translate Claude Code's complex agentic requests into a format that Gemini 3.1 Pro (High) can understand.

---

## 2. Final Configuration

To ensure stable operation, three configuration steps are required for a successful session:

1. **Proxy Must Be Running:**
   `cligate start` must be active and listening on port `8081`.
2. **Environment Variables:**
   Claude Code must be redirected from Anthropic's servers to the local proxy:
   - `ANTHROPIC_BASE_URL="http://localhost:8081"`
   - `ANTHROPIC_API_KEY="cligate"`
3. **Correct Model Alias:**
   Claude Code must be launched using the agent-optimized Gemini alias:
   - `claude --model gemini-pro-agent`

---

## 3. Permanent Solution (Launcher Script)

To automate the entire workflow and prevent these issues from recurring after a system restart, a comprehensive launcher script (`claude-launcher.ps1`) was created. 

### Script Capabilities:
- Validates that Node.js meets the version requirement.
- Verifies that `cligate` is installed globally.
- Checks if port `8081` is listening. If not, it safely starts `cligate` in the background.
- Injects the necessary proxy environment variables into the current PowerShell session.
- Automatically launches `claude` with the `gemini-pro-agent` flag.

**Usage:**
```powershell
.\claude-launcher.ps1
```
