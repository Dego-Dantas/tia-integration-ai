# tia-integration-ai (v2.0)

> Integration between Artificial Intelligence and Siemens TIA Portal via MCP (Model Context Protocol), OpenCode Portable v2, and Magic Context.

[![Português](https://img.shields.io/badge/lang-Português-green.svg)](README.md)
[![English](https://img.shields.io/badge/lang-English-blue.svg)](README.en.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

This project provides a **portable OpenCode (v2+)** setup pre-configured to interact with **Siemens TIA Portal (V20 / V21)** — generating, reading, and editing PLC logic (LAD, FBD, SCL), tags, data blocks, hardware, and HMI screens with AI assistance.

---

## What's Included in v2.0

1. **OpenCode Portable (`opencode.bat`):** Runs OpenCode v2 completely self-contained inside its folder (via `XDG_*` variables). If `opencode.exe` is missing on first launch (e.g. after cloning from Git), `opencode.bat` downloads it automatically.
2. **Unified `TIA-PORTAL` MCP ([bulaofen0036-coder/TIA_Portal_Openness_MCP](https://github.com/bulaofen0036-coder/TIA_Portal_Openness_MCP)):** Single comprehensive MCP server (~222 tools with `--profile full`) with dynamic switching between **TIA Portal V20** and **V21** via `tiaolder-version.txt`.
3. **Magic Context (`@cortexkit/opencode-magic-context`):** Background context compaction (`historian` + `dreamer`) and persistent project memory (`ctx_search`, `ctx_expand`, `ctx_memory`, `ctx_note`, `ctx_reduce`).
4. **Auto-Updater (`atualizar.bat` / `update-all.ps1`) ⚠️ *(For testing — may break)*:** Experimental script that updates `opencode.exe`, the `Magic Context` plugin, and the `bulaofen0036` MCP release while preserving user configs and removing old versions.

> [!WARNING]
> **Notice Regarding the Auto-Updater (`atualizar.bat` / `update-all.ps1`):**
> The automatic updater is included **for testing purposes and may break** if upstream release formats (GitHub/npm) or OpenCode schemas change. Always back up your folder before updating.

---

## How to Run

1. **Select your TIA Portal version:** edit `tiaolder-version.txt` with `20` (default) or `21`.
2. **(Optional) If running inside an offline VM:** run `proxy\iniciar-proxy.bat` on the Host machine to provide internet over port `3128`.
3. **Start OpenCode Portable:** double-click **`opencode.bat`**.

---

## Documentation

- [Agents & Tools](AGENTS.md) — `@tiaolder` (`TIA-PORTAL` MCP) and `Magic Context` reference
- [Setup Guide](docs/CONFIGURACAO.md) — Full environment setup (Portuguese)
- [VM Proxy](docs/PROXY.md) — HTTP CONNECT proxy guide (Portuguese)

## Credits

| Component | Author / Repository |
|---|---|
| **TIA Portal Openness MCP** | [bulaofen0036-coder/TIA_Portal_Openness_MCP](https://github.com/bulaofen0036-coder/TIA_Portal_Openness_MCP) |
| **Magic Context** | [cortexkit/magic-context](https://github.com/cortexkit/magic-context) |
| **OpenCode** | [opencode.ai](https://opencode.ai) |

## License

MIT — see [LICENSE](LICENSE).
