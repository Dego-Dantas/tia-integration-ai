# Agents & Ferramentas

Este projeto utiliza o **OpenCode Portable (v2+)** com um único servidor MCP unificado para o TIA Portal (**`TIA-PORTAL`**, baseado no projeto [bulaofen0036-coder/TIA_Portal_Openness_MCP](https://github.com/bulaofen0036-coder/TIA_Portal_Openness_MCP)) e o plugin **Magic Context** (`@cortexkit/opencode-magic-context`) para gestão automática de contexto e memória.

---

## @tiaolder (MCP `TIA-PORTAL`)

Servidor MCP **bulaofen0036-coder** com versão configurável do TIA Portal.

| Propriedade | Valor |
|---|---|
| **Servidor MCP** | `TIA-PORTAL` ([bulaofen0036-coder/TIA_Portal_Openness_MCP](https://github.com/bulaofen0036-coder/TIA_Portal_Openness_MCP)) |
| **Versão TIA** | Configurável via `tiaolder-version.txt` (`20` ou `21` no pacote padrão) |
| **Ferramentas** | ~222 (`--profile full`) |
| **Comando** | `tia-openness.cmd` |
| **Definição do Agent** | `.opencode/agents/tiaolder.md` |

### Seleção de Versão do TIA Portal

O arquivo `tiaolder-version.txt` na raiz define qual runtime o `tia-openness.cmd` executará:

```text
20  →  TIA Portal V20 (runtime\v20\TiaMcpServer.exe — .NET Framework 4.8)
21  →  TIA Portal V21 (runtime\v21\TiaMcpServer.exe — .NET 8.0 Windows)
```

### Principais Ferramentas (`TIA-PORTAL_*`)

| Categoria | Ferramentas Principais |
|---|---|
| **Bootstrap / Sessão** | `Bootstrap`, `Doctor`, `GetState`, `Connect`, `ConnectIsolated` |
| **Projeto** | `CreateProject`, `OpenProject`, `SaveProject`, `CloseProject`, `GetProjectTree`, `ScaffoldProject` |
| **Blocos (LAD/SCL/DB)** | `GetBlocks`, `GetSoftwareTree`, `DescribeBlockLogic`, `ExportBlock`, `ImportBlock`, `ExportAsDocuments`, `ImportFromDocuments`, `PlcBuildAndImport`, `CreatePlcBlockGroup`, `MoveBlockToGroup`, `DeletePlcBlock` |
| **Tags e UDTs** | `GetPlcTagTables`, `ExportTagTable`, `ImportTagTable`, `GetPlcTypes`, `DeletePlcTagTable`, `DeletePlcType` |
| **Compilação** | `CompileAndDiagnosePlc`, `CompileSoftware`, `CompileAndDiagnoseHmi` |
| **Hardware e Rede** | `AddDevice`, `GetDevices`, `GetProjectTopology`, `CreateSubnet`, `ConnectToSubnet` |
| **HMI (WinCC Unified)** | `EnsureUnifiedHmiScreen`, `EnsureUnifiedHmiTag`, `ApplyUnifiedHmiScreenDesignJson` |
| **Online (Leitura S7)** | `GetPlcRunStateS7`, `ReadPlcLiveValuesS7`, `MonitorWatchTableLiveS7` |
| **Versionamento (VCI)** | `CreateVersionControlWorkspace`, `ConnectProjectToWorkspace`, `GetVersionControlStatus`, `SyncVersionControlWorkspace` |
| **Descoberta de Tools** | `FindTools`, `CallTool` |

### Fluxo Recomendado de Uso

1. `Bootstrap` → verifica o estado atual do servidor MCP.
2. `Connect` (ou `ConnectIsolated` se o TIA Portal já estiver aberto com um projeto na interface gráfica).
3. `GetProjectTree` → obtém os nomes exatos dos dispositivos (`PLC_xxx`, `HMI_RT_xxx`).
4. `GetSoftwareTree` / `DescribeBlockLogic` / `ExportAsDocuments` / `ExportBlock` → leitura e edição.
5. `CompileAndDiagnosePlc` + `SaveProject` → compilação, diagnóstico e salvamento.

### Exemplos no Chat do OpenCode

```text
@tiaolder conecte ao projeto aberto no TIA Portal e mostre a árvore do projeto
@tiaolder descreva a lógica do bloco Main (OB1) usando DescribeBlockLogic
@tiaolder crie um projeto novo com um S7-1500 usando ScaffoldProject
```

---

## Magic Context (`@cortexkit/opencode-magic-context`)

Plugin que gerencia o histórico da conversa (`<session-history>`) e a memória persistente do projeto (`<project-memory>`) em segundo plano, substituindo a compactação nativa do OpenCode (`compaction.auto: false`).

### Ferramentas Expostas ao Agente (`ctx_*`)

| Ferramenta | Descrição |
|---|---|
| `ctx_search` | Busca na memória do projeto e no histórico de turnos anteriores já compactados |
| `ctx_expand` | Recupera o conteúdo original completo de um compartimento `<session-history>` |
| `ctx_memory` | Grava fatos duráveis sobre o projeto (`PROJECT_RULES`, `ARCHITECTURE`, `CONSTRAINTS`, `CONFIG_VALUES`, `NAMING`) |
| `ctx_note` | Registra lembretes temporários de trabalho |
| `ctx_reduce` | Marca saídas grandes de ferramentas já utilizadas como descartáveis para liberar contexto |

### Comandos no TUI

- `/ctx-status` — Mostra o status do `historian`, `dreamer`, uso de contexto e compartimentos ativos.
- `/ctx-wrapup` — Força a compactação imediata da sessão atual.

---

## Configuração (`config/opencode/opencode.json`)

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "Guias/MAGIC_CONTEXT_AGENTE.txt"
  ],
  "mcp": {
    "servers": {
      "TIA-PORTAL": {
        "type": "local",
        "command": ["cmd.exe", "/c", ".\\tia-openness.cmd"],
        "timeout": 120000
      }
    }
  },
  "compaction": {
    "auto": false
  },
  "plugins": [
    "@cortexkit/opencode-magic-context@0.49.16"
  ]
}
```
