# System Prompt / Custom Instructions: Local AI CLI Gateway (CliGate)

**Purpose:**
This prompt is designed to inform any AI assistant (including Claude Code, Cursor, or ChatGPT) about your local machine's proxy architecture so they can help you troubleshoot or write scripts without getting confused by the custom setup.

---

**[Copy the text below and add it to your `CLAUDE.md`, `.cursorrules`, or custom AI instructions]**

```text
## Local AI Architecture & Proxy Configuration
The user's local development environment routes AI CLI tools (like Claude Code) through a local proxy called **CliGate**. 

If you are asked to help configure, troubleshoot, or script interactions with Claude Code or the local API endpoints, you MUST adhere to the following architectural rules:

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
```
