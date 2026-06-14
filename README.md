# CliGate & Claude Code Fix

This repository contains scripts and documentation to stabilize and run **Claude Code** powered by **Gemini 3.1 Pro** via the **CliGate** local proxy on Windows.

## 🔍 The Root Problem
By default, Claude Code sends highly complex, Anthropic-specific tool-calling payloads. When these requests are routed to a different provider like Google's Gemini (e.g., `gemini-3.1-pro-high`), the raw model rejects them with an `INVALID_ARGUMENT` error because the schemas do not match what Gemini expects.

To solve this, requests **must** be routed to the translation alias `gemini-pro-agent`. This special endpoint inside CliGate automatically intercepts Anthropic's agent payloads, translates them into Gemini-compatible schemas, and routes them to the high-tier model seamlessly.

## 📋 Requirements
- **OS:** Windows (PowerShell recommended)
- **Node.js:** v24 or higher
- **CliGate:** v1.3.1+ (install via `npm install -g cligate`)
- **Claude Code:** (install via `npm install -g @anthropic-ai/claude-code`)
- **CliGate Account Login:** You MUST be logged in. Run `cligate login` in your terminal before using.

## 🔗 Important Links
- [CliGate GitHub Repository](https://github.com/codeking-ai/cligate)
- [CliGate Local Dashboard](http://localhost:8081) *(Requires CliGate to be running)*
- [Node.js Official Downloads](https://nodejs.org/)

## 🛠️ Usage
To automatically verify prerequisites, start the proxy, and launch Claude Code with the correct settings, simply execute the included launcher script from PowerShell:

```powershell
.\claude-launcher.ps1
```

---

## 🤖 AI Assistant Prompt
*If you are an AI Agent (like Claude, Cursor, or ChatGPT) asked to use or troubleshoot this repository, **read and obey the following instructions**:*

```text
## Local AI Architecture & Proxy Configuration
The user's local development environment routes AI CLI tools (like Claude Code) through a local proxy called **CliGate**. 

1. **Proxy Endpoint:** 
   The local proxy runs at `http://localhost:8081`. 
   - Environment variables required for Claude Code:
     `ANTHROPIC_BASE_URL="http://localhost:8081"`
     `ANTHROPIC_API_KEY="cligate"`

2. **Model Aliasing (CRITICAL):**
   - The user has an "Antigravity" account which routes to Google's Gemini models.
   - Claude Code sends Anthropic-specific tool-calling payloads. The raw Gemini models (e.g., `gemini-3.1-pro-high`) will reject these with an `INVALID_ARGUMENT` error.
   - To bypass this, requests MUST be routed to the translation alias: `gemini-pro-agent`.
   - Always launch Claude Code using: `claude --model gemini-pro-agent`.

3. **Node.js Requirements:**
   - The `cligate` service requires Node.js v24 or higher. Do not suggest downgrading Node.js.

4. **Troubleshooting Steps:**
   - If Claude Code returns `All accounts and API keys exhausted`, it usually means the model requested was incorrect (e.g., requesting the raw model instead of the `-agent` alias) or the `cligate` server is down.
   - If the proxy fails to start with `EADDRINUSE`, find the orphan node process on port 8081 using `netstat -ano | findstr :8081` and forcefully kill it before restarting the proxy.
   - To launch Claude automatically with all fixes applied, run `.\claude-launcher.ps1`.
```
