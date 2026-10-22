# tia-integration-ai (v2.0)

> Integração entre Inteligência Artificial e Siemens TIA Portal via protocolo MCP (Model Context Protocol), OpenCode Portable v2 e Magic Context.

[![Português](https://img.shields.io/badge/lang-Português-green.svg)](README.md)
[![English](https://img.shields.io/badge/lang-English-blue.svg)](README.en.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Este projeto fornece uma estrutura **portátil do OpenCode (v2+)** pré-configurada para interagir com o **Siemens TIA Portal (V20 / V21)** — gerando, lendo e editando lógica de CLPs (LAD, FBD, SCL), tags, blocos de dados, hardware e telas HMI com assistência de IA.

---

## O que inclui na v2.0

1. **OpenCode Portable (`opencode.bat`):** Executa o OpenCode v2 de forma 100% autocontida na pasta (via variáveis `XDG_*`), sem poluir pastas globais do Windows. Se o `opencode.exe` ainda não estiver na pasta no primeiro uso, o próprio `opencode.bat` baixa automaticamente.
2. **MCP Unificado `TIA-PORTAL` ([bulaofen0036-coder/TIA_Portal_Openness_MCP](https://github.com/bulaofen0036-coder/TIA_Portal_Openness_MCP)):** Servidor único (~222 tools com `--profile full`) e seleção dinâmica entre **TIA Portal V20** e **V21** via `tiaolder-version.txt`.
3. **Magic Context (`@cortexkit/opencode-magic-context`):** Compactação automática de contexto em background (`historian` + `dreamer`) e memória persistente de projeto (`ctx_search`, `ctx_expand`, `ctx_memory`, `ctx_note`, `ctx_reduce`).
4. **Atualizador Automático (`atualizar.bat` / `update-all.ps1`) ⚠️ *(Para teste — pode quebrar)*:** Script experimental que atualiza o `opencode.exe`, o plugin `Magic Context` e a release do MCP `bulaofen0036` preservando suas configurações e limpando versões antigas.

> [!WARNING]
> **Aviso sobre o Atualizador Automático (`atualizar.bat` / `update-all.ps1`):**
> O atualizador automático foi incluído **para fins de teste e pode quebrar** caso ocorram mudanças no formato das releases upstream (GitHub/npm) ou no schema do OpenCode. Faça backup da sua pasta antes de atualizar.

---

## Arquitetura

```
┌──────────────────────────────────────────┐
│               LLM Provider               │
│       (Nuvem ou Local / LMStudio)        │
└────────────────────┬─────────────────────┘
                     │
┌────────────────────▼─────────────────────┐
│         OpenCode Portable (v2+)          │
│  ├── Plugin: Magic Context (Memória/Ctx) │
│  └── Agent: @tiaolder (MCP TIA-PORTAL)   │
└────────────────────┬─────────────────────┘
                     │ Openness API (V20 / V21)
┌────────────────────▼─────────────────────┐
│         Siemens TIA Portal V20/V21       │
│    Projetos, blocos, tags, HW, HMI       │
└──────────────────────────────────────────┘
```

### Componentes

| Componente | Descrição |
|---|---|
| **OpenCode Portable** | CLI conversacional de IA rodando isolada na própria pasta via `opencode.bat` |
| **TIA-PORTAL (MCP)** | Servidor [bulaofen0036-coder](https://github.com/bulaofen0036-coder/TIA_Portal_Openness_MCP) com versão configurável (V20/V21) e ~222 tools |
| **Magic Context** | Plugin `@cortexkit/opencode-magic-context` para gestão de histórico e memória de projeto |
| **Proxy HTTP (`proxy/proxy.js`)** | Proxy CONNECT leve em Node.js para permitir que uma VM isolada acesse a internet pelo Host |
| **Auto-Updater (`update-all.ps1`)** | *(Experimental / Para teste)* Atualiza OpenCode, Magic Context e TIA MCP sem perder configs |

---

## Como Rodar

1. **Escolha a versão do TIA Portal:** edite `tiaolder-version.txt` com `20` (padrão) ou `21`.
2. **(Opcional) Se estiver em uma VM offline:** inicie `proxy\iniciar-proxy.bat` na máquina Host para liberar internet via porta `3128`.
3. **Inicie o OpenCode Portable:** dê dois cliques em **`opencode.bat`**.
   - *(Se você clonou o repositório do Git sem o `opencode.exe`, o `opencode.bat` chamará automaticamente o `update-all.ps1` no primeiro uso para baixar o binário e o plugin).*

---

## Estrutura do Projeto

```
tia-integration-ai/
├── opencode.bat                        # Launcher portátil (configura XDG_*, proxy e abre o OpenCode)
├── atualizar.bat                       # [TESTE] Atalho para atualizar OpenCode, Magic Context e MCP
├── update-all.ps1                      # [TESTE] Script PowerShell de atualização automática
├── tia-openness.cmd                    # Wrapper que seleciona o runtime V20 ou V21 do MCP
├── tiaolder-version.txt                # Versão ativa do TIA Portal ("20" ou "21")
├── config/
│   ├── opencode/opencode.json          # Configuração do OpenCode v2 (SEMPRE salvar em UTF-8 sem BOM)
│   └── cortexkit/magic-context.jsonc   # Configuração dos modelos Historian/Dreamer do Magic Context
├── .opencode/
│   ├── agents/tiaolder.md              # Definição do agent @tiaolder
│   └── skills/tia-portal-scl/SKILL.md  # Skill base para TIA Portal
├── tia-openness-mcp/                   # Binários do MCP bulaofen0036 (runtime/v20 e runtime/v21)
├── proxy/
│   ├── proxy.js                        # Servidor proxy HTTP CONNECT para VM
│   └── iniciar-proxy.bat               # Inicializador do proxy no Host
├── Guias/
│   ├── MAGIC_CONTEXT_AGENTE.txt        # Instruções do Magic Context para o agente
│   └── GUIA_TROCAR_MODELO_MAGIC_CONTEXT.md # Como alterar o modelo do Historian/Dreamer
└── docs/
    ├── CONFIGURACAO.md                 # Guia completo de configuração
    └── PROXY.md                        # Guia do proxy HTTP para VM
```

---

## Documentação

- [Agents e Ferramentas](AGENTS.md) — Documentação do agent `@tiaolder` (`TIA-PORTAL`) e do `Magic Context`
- [Guia de Configuração](docs/CONFIGURACAO.md) — Setup completo do ambiente, providers e Magic Context
- [Trocar Modelo do Magic Context](Guias/GUIA_TROCAR_MODELO_MAGIC_CONTEXT.md) — Como mudar o modelo do `historian` e `dreamer`
- [Proxy para VM](docs/PROXY.md) — Como usar o proxy HTTP CONNECT entre VM e Host

## Créditos

| Componente | Autor / Repositório |
|---|---|
| **TIA Portal Openness MCP** | [bulaofen0036-coder/TIA_Portal_Openness_MCP](https://github.com/bulaofen0036-coder/TIA_Portal_Openness_MCP) |
| **Magic Context** | [cortexkit/magic-context](https://github.com/cortexkit/magic-context) |
| **OpenCode** | [opencode.ai](https://opencode.ai) |

## Licença

MIT — veja [LICENSE](LICENSE).
