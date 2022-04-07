# Integrating Large Language Models with Siemens TIA Portal via MCP Protocol

## A Practical Workflow for AI-Assisted PLC Engineering

**Author:** Diego Carmo Dantas
**Contact:** diego.a.blizzard@gmail.com
**Repository:** https://github.com/Degoronha/tia-integration-ai

---

## 1. Context and Problem

Programmable Logic Controllers (PLCs) are the backbone of industrial automation. Engineering these systems using Siemens TIA Portal involves creating and maintaining logic blocks in LAD (Ladder), FBD (Function Block Diagram), and SCL (Structured Control Language), managing tags, configuring hardware, and ensuring compilation integrity.

Despite advances in IDEs, the TIA Portal workflow remains largely manual. Meanwhile, Large Language Models (LLMs) have demonstrated remarkable capabilities in code generation and review. However, bridging LLMs with industrial engineering tools presents unique challenges: proprietary APIs, offline environments, Windows-specific process management, and the need for deterministic tool execution.

This work presents a practical integration between LLMs and Siemens TIA Portal using the Model Context Protocol (MCP), enabling conversational AI-assisted PLC engineering.

---

## 2. Architecture

```
LLM Provider (user-configured)
       |
       | HTTPS / Local Network
       |
   OpenCode (CLI)
   Conversational AI Interface
       |
       | MCP Protocol (stdin/stdout)
       |
   +-----------+     +-------------------+
   | tiav21    |     | tiaolder          |
   | (Czarnak) |     | (bulaofen0036)    |
   | ~25 tools |     | ~189 tools        |
   | V21 fixed |     | Configurable ver. |
   +-----------+     +-------------------+
       |                    |
       | Openness API       | Openness API
       +--------------------+
                |
         TIA Portal V20/V21
    Projects, Blocks, Tags, HW, Network
```

### 2.1 Host and VM Separation

A key architectural decision was separating the environment into two machines:

- **Host Machine:** Physical computer with internet access, running a Node.js HTTP CONNECT proxy and optionally local LLM models.
- **Virtual Machine:** Windows VM with TIA Portal installed, running OpenCode and MCP servers. The VM has no direct internet access — all external API calls are routed through the host's proxy via VMnet1 (host-only network).

### 2.2 HTTP CONNECT Proxy

A lightweight Node.js proxy enables the offline VM to reach cloud LLM APIs:

- File: `proxy.js`
- Port: 3128
- Dependencies: None (pure Node.js)

```javascript
const server = http.createServer();
server.on('connect', (req, clientSocket, head) => {
  const [host, portStr] = req.url.split(':');
  const port = parseInt(portStr) || 443;
  const serverSocket = net.connect(port, host, () => {
    clientSocket.write('HTTP/1.1 200 Connection Established\r\n\r\n');
    serverSocket.write(head);
    serverSocket.pipe(clientSocket);
    clientSocket.pipe(serverSocket);
  });
});
```

---

## 3. MCP Servers

The Model Context Protocol (MCP) is an open standard that allows LLM applications to expose tools through a standardized interface. Two distinct MCP servers are employed:

### 3.1 tiav21 — Czarnak MCP Server

- Repository: https://github.com/Czarnak/tia-portal-mcp
- Version: 1.6.0 (NuGet package)
- Focus: TIA Portal V21 block editing via `update_block_logic`
- Tools: ~25

Categories: Navigation, Block Editing (read/write), Tags (CRUD), Hardware, Network, Diagnostics, Project management.

The `update_block_logic` tool accepts blocks in SIMATIC SD format (`.s7dcl` + `.s7res`), enabling LLMs to generate or modify LAD logic:

```yaml
--- FILE: MyBlock.s7dcl ---
FUNCTION "MyBlock" : Void
    NETWORK
        RUNG wire#powerrail
            Contact( "Sensor_01" )
            Coil( "Actuator_01" )
        END_RUNG
    END_NETWORK
END_FUNCTION
```

**Limitation:** SD import fails for blocks created in TIA versions prior to V20 Update 4.

### 3.2 tiaolder — bulaofen0036 MCP Server

- Provider: bulaofen0036 (TIA Openness MCP)
- Version: 2.2.4
- Focus: Full project generation via `ScaffoldProject`
- Tools: ~189
- TIA Version: Configurable (V16–V21 via version config file; V20–V21 official, V19–V16 community branches)

This server supports **complete project scaffolding** from a JSON specification:

```json
{
  "spec": {
    "projectName": "MyProject",
    "plc": {
      "model": "S7-1200 / S7-1500",
      "blocks": [...],
      "tagTables": [...]
    },
    "hmi": {
      "screens": [...]
    }
  }
}
```

It also supports **block-level editing via SimaticML XML** (Method B), which is more reliable than SD format:

1. `ExportBlock` → generates `.xml` (SimaticML format)
2. Manual or scripted XML modification
3. `ImportBlock` → imports modified XML
4. `CompileAndDiagnosePlc` → validates

---

## 4. Technical Challenges and Solutions

### 4.1 Windows Process Management

**Problem:** OpenCode uses `child_process.spawn()` from Node.js. The path `C:\Program Files\dotnet\dotnet.exe` contains spaces, causing silent failure.

**Solution:** Custom batch wrappers:

```batch
@echo off
"%~dp0tia-mcp\TiaMcpServer.exe"
```

Configured with explicit `cmd.exe /c`:

```json
{
  "command": ["cmd.exe", "/c", "C:\\path\\tia-mcp.cmd"]
}
```

### 4.2 Duplicate Configuration Conflict

**Problem:** OpenCode merges config from multiple locations. An outdated config at `%USERPROFILE%\.opencode\opencode.json` overrode the correct config, causing MCP to show as "failed."

**Solution:** Detect and unify both configuration files.

### 4.3 .NET Runtime Discovery

**Problem:** .NET SDK was installed but not in the system PATH during the OpenCode session.

**Solution:** Use absolute paths in wrapper scripts.

### 4.4 Proxy and NO_PROXY Configuration

**Problem:** Without `NO_PROXY`, local LLM traffic was incorrectly routed through the HTTP proxy.

**Solution:** Configure `NO_PROXY` to bypass the proxy for local network traffic.

### 4.5 MCP Timeout

**Problem:** Complex TIA Portal operations could exceed 60s, exceeding default MCP timeout.

**Solution:** Increase MCP timeout to 120,000ms.

---

## 5. OpenCode Configuration

OpenCode is an open-source CLI that enables conversational interaction with LLMs while providing access to MCP tools. Users can configure any OpenAI-compatible provider:

```json
{
  "provider": {
    "my-provider": {
      "options": {
        "apiKey": "sk-sua-chave",
        "baseURL": "https://api.provider.com/v1"
      }
    }
  },
  "mcp": {
    "tiav21": {
      "type": "local",
      "command": ["cmd.exe", "/c", "C:\\path\\tia-mcp.cmd"],
      "timeout": 120000
    },
    "tiaolder": {
      "type": "local",
      "command": ["cmd.exe", "/c", "C:\\path\\tia-openness.cmd"],
      "timeout": 120000
    }
  }
}
```

Providers (cloud or local) are user-defined — the workflow works with any OpenAI-compatible API endpoint.

---

## 6. Agents

Two agents are defined, each associated with one MCP server:

| Agent | MCP | TIA Version | Focus |
|---|---|---|---|
| `@tiav21` | tiav21 (Czarnak) | V21 fixed | Block editing, tags, hardware |
| `@tiaolder` | tiaolder (bulaofen0036-coder) | V16–V21 (V20–V21 official, V19–V16 community) | Full project scaffold, XML operations |

### Agent Workflow: tiav21

1. `browse_project_tree` → understand structure
2. `get_block_content` → read existing block
3. Modify YAML preserving required format
4. `update_block_logic` with `confirm=true` → write
5. `compile_check` → verify

### Agent Workflow: tiaolder

1. `Bootstrap` → initialize server
2. `GetProjectTree` / `GetSoftwareTree` → discover names
3. Choose method:
   - **Method A (SD):** `ExportAsDocuments` → edit → `ImportFromDocuments`
   - **Method B (XML):** `ExportBlock` → edit XML → `ImportBlock`
4. `CompileAndDiagnosePlc` → validate
5. `SaveProject` → persist

---

## 7. Results

The integrated system enables these engineering tasks through natural language:

1. **Project tree navigation:** "Show me the project structure"
2. **Block reading and editing:** "Read Main block and add a new contact"
3. **Tag management:** "Create a new BOOL tag called Sensor_01"
4. **Hardware configuration:** "Show me the hardware layout"
5. **Cross-reference analysis:** "Where is Motor_01 used?"
6. **Compilation checks:** "Compile and show errors"
7. **Full project generation:** "Scaffold a new S7-1200 or S7-1500 project"
8. **Bulk operations:** "Add comments to all networks in FC500"

---

## 8. Next Steps

The project has been submitted to OpenAI's Codex for Open Source program, which would provide API credits for continued development and 6 months of ChatGPT Pro.

Future improvements include:
- Additional PLC family support
- Automated test generation for PLC logic
- Version control integration
- Community contributions

---

## 9. Credits

| MCP | Author | Repository |
|---|---|---|
| **tiav21** | [Czarnak](https://github.com/Czarnak) | [tia-portal-mcp](https://github.com/Czarnak/tia-portal-mcp) |
| **tiaolder** | [bulaofen0036-coder](https://github.com/bulaofen0036-coder) | [TIA Portal Openness MCP](https://github.com/bulaofen0036-coder/TIA_Portal_Openness_MCP) |

## 10. Repository

All code and documentation are open-source at:

**https://github.com/Degoronha/tia-integration-ai**
