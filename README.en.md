# tia-integration-ai

> Integration between Artificial Intelligence and Siemens TIA Portal via MCP (Model Context Protocol)

This project enables automation engineers to use **Large Language Models (LLMs)** to interact with Siemens **TIA Portal** — generating, reviewing, and editing PLC logic (LAD, FBD, SCL) with AI assistance.

## Architecture

```
┌──────────────────────────────────┐
│         LLM Provider             │
│      (user-configured)           │
└──────────┬───────────────────────┘
           │ HTTPS
┌──────────▼───────────────────────┐
│        OpenCode (CLI)            │
│  Conversational AI interface     │
└──┬───────────────┬───────────────┘
   │ @tiav21       │ @tiaolder
   │ MCP           │ MCP
┌──▼─────────────┐ ┌▼─────────────────┐
│ tiav21         │ │ tiaolder          │
│ (Czarnak)      │ │ (bulaofen0036)    │
│ ~25 tools      │ │ ~189 tools        │
│ V21 fixed      │ │ Configurable ver. │
└──┬─────────────┘ └──┬───────────────┘
   │ Openness API     │ Openness API
┌──▼──────────────────▼────────────────┐
│    TIA Portal V20/V21            │
│  Projects, blocks, tags, HW, network │
└──────────────────────────────────────┘
```

### Components

| Component | Description |
|---|---|
| **OpenCode** | Conversational CLI connecting LLMs to tools via MCP |
| **tiav21 (MCP)** | Czarnak server focused on V21 — block editing, tags, hardware (~25 tools) |
| **tiaolder (MCP)** | bulaofen0036 server with configurable version — full project generation (~189 tools) |
| **Openness API** | Siemens API for programmatic TIA Portal automation |
| **HTTP Proxy** | CONNECT proxy for offline VM to access cloud APIs |

## Agents

| Agent | MCP | TIA Version | Focus |
|---|---|---|---|
| `@tiav21` | `tiav21` (Czarnak) | V21 (fixed) | SCL/LAD block editing, tags, hardware |
| `@tiaolder` | `tiaolder` (bulaofen0036-coder) | Configurable (V16–V21, see branches) | Older version support (V16–V19), project scaffold |

See [AGENTS.md](AGENTS.md) for complete details.

## Features

- TIA Portal project tree navigation via AI
- Read and edit LAD/FBD/SCL blocks
- Tag creation and management
- Hardware configuration reading
- Compilation and cross-reference checks
- AI-assisted PLC code generation
- Full project scaffold with configurable version

## AI Providers

The workflow works with any OpenAI-compatible provider (cloud or local). Configuration is done via `opencode.json`:

```json
{
  "provider": {
    "my-provider": {
      "options": {
        "apiKey": "sk-your-key",
        "baseURL": "https://api.provider.com/v1"
      }
    }
  }
}
```

See [docs/CONFIGURACAO.md](docs/CONFIGURACAO.md) for the full setup guide.

## Documentation

- [Agents](AGENTS.md) — @tiav21 and @tiaolder agent documentation
- [Setup Guide](docs/CONFIGURACAO.md) — Full environment setup
- [VM Proxy](docs/PROXY.md) — How to set up a proxy for an offline VM

## Project Structure

```
tia-integration-ai/
├── AGENTS.md               # Agent documentation
├── LICENSE                  # MIT License
├── opencode.example.json    # Example OpenCode configuration
├── proxy.js                 # HTTP CONNECT proxy server
├── README.md                # This file (Portuguese)
├── README.en.md             # This file (English)
├── scripts/
│   ├── tia-mcp.cmd          # tiav21 MCP wrapper (Czarnak)
│   ├── tia-openness.cmd     # tiaolder MCP wrapper (bulaofen0036)
│   └── tiaolder-version.txt # TIA version for @tiaolder
└── docs/
    ├── CONFIGURACAO.md      # Full setup guide (Portuguese)
    └── PROXY.md             # HTTP proxy guide
```

## Credits

| MCP | Author | Repository |
|---|---|---|
| **tiav21** | [Czarnak](https://github.com/Czarnak) | [tia-portal-mcp](https://github.com/Czarnak/tia-portal-mcp) |
| **tiaolder** | [bulaofen0036-coder](https://github.com/bulaofen0036-coder) | [TIA Portal Openness MCP](https://github.com/bulaofen0036-coder/TIA_Portal_Openness_MCP) |

## License

MIT — see [LICENSE](LICENSE).
