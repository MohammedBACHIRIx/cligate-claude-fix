"use strict";

/**
 * ONLYOFFICE AI Helper Custom Provider for CliGate Bridge
 * 
 * This provider routes ONLYOFFICE AI helper requests through the local CliGate proxy (port 8081).
 * It enables using CliGate's pooled models (such as gemini-pro-agent or gpt-4o) directly inside ONLYOFFICE.
 */
class Provider extends AI.Provider {
    constructor() {
        // Super parameters: Name, Base URL, API Key, Addon/Version
        // - Base URL is http://localhost:8081
        // - Addon is v1 (which gets appended to form the full endpoint: http://localhost:8081/v1)
        super("CliGate Bridge", "http://localhost:8081", "cligate", "v1");
    }
}
