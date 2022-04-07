# tia-integration-ai

> Integração entre Inteligência Artificial e Siemens TIA Portal via protocolo MCP (Model Context Protocol)

Este projeto permite que engenheiros de automação utilizem **modelos de linguagem (LLMs)** para interagir com o **TIA Portal** da Siemens — gerando, revisando e editando lógica de CLPs (LAD, FBD, SCL) com assistência de IA.

## Arquitetura

```
┌──────────────────────────────────┐
│         LLM Provider             │
│     (configurado pelo usuário)    │
└──────────┬───────────────────────┘
           │ HTTPS
┌──────────▼───────────────────────┐
│        OpenCode (CLI)            │
│  Interface conversacional com IA │
└──┬───────────────┬───────────────┘
   │ @tiav21       │ @tiaolder
   │ MCP           │ MCP
┌──▼─────────────┐ ┌▼─────────────────┐
│ tiav21         │ │ tiaolder          │
│ (Czarnak)      │ │ (bulaofen0036)    │
│ ~25 tools      │ │ ~189 tools        │
│ V21 fixo       │ │ Versão config.    │
└──┬─────────────┘ └──┬───────────────┘
   │ Openness API     │ Openness API
┌──▼──────────────────▼────────────────┐
│               TIA Portal V20/V21         │
│  Projetos, blocos, tags, HW, rede    │
└──────────────────────────────────────┘
```

### Componentes

| Componente | Descrição |
|---|---|
| **OpenCode** | CLI conversacional que conecta LLMs a ferramentas via MCP |
| **tiav21 (MCP)** | Servidor Czarnak focado em V21 — edição de blocos, tags, hardware (~25 tools) |
| **tiaolder (MCP)** | Servidor bulaofen0036 com versão configurável — geração completa de projetos (~189 tools) |
| **Openness API** | API da Siemens para automação programática do TIA Portal |
| **Proxy HTTP** | Proxy CONNECT para VM offline acessar APIs de nuvem |

## Agents

| Agent | MCP | Versão TIA | Foco |
|---|---|---|---|
| `@tiav21` | `tiav21` (Czarnak) | V21 (fixo) | Edição de blocos SCL/LAD, tags, hardware |
| `@tiaolder` | `tiaolder` (bulaofen0036-coder) | Configurável (V16–V21, ver branches) | Suporte a versões antigas (V16–V19), geração de projetos |

Consulte [AGENTS.md](AGENTS.md) para detalhes completos.

## Funcionalidades

- Navegação na árvore de projetos TIA Portal via IA
- Leitura e edição de blocos LAD/FBD/SCL
- Criação e gerenciamento de tags
- Leitura de configuração de hardware
- Compilação e verificação cruzada
- Geração de código de CLP assistida por IA
- Geração de projetos completos com versão configurável

## Provedores de IA

O workflow funciona com qualquer provedor compatível com a API OpenAI (nuvem ou local). A configuração é feita via `opencode.json`:

```json
{
  "provider": {
    "meu-provedor": {
      "options": {
        "apiKey": "sk-sua-chave",
        "baseURL": "https://api.provedor.com/v1"
      }
    }
  }
}
```

Consulte [docs/CONFIGURACAO.md](docs/CONFIGURACAO.md) para o guia completo.

## Documentação

- [Agents](AGENTS.md) — Documentação dos agents @tiav21 e @tiaolder
- [Guia de Configuração](docs/CONFIGURACAO.md) — Setup completo do ambiente
- [Proxy para VM](docs/PROXY.md) — Como configurar proxy para VM offline

## Estrutura do Projeto

```
tia-integration-ai/
├── AGENTS.md               # Documentação dos agents
├── LICENSE                  # Licença MIT
├── opencode.example.json    # Configuração exemplo do OpenCode
├── proxy.js                 # Servidor proxy HTTP CONNECT
├── README.md                # Este arquivo
├── scripts/
│   ├── tia-mcp.cmd          # Wrapper do MCP tiav21 (Czarnak)
│   ├── tia-openness.cmd     # Wrapper do MCP tiaolder (bulaofen0036)
│   └── tiaolder-version.txt # Versão do TIA para @tiaolder
└── docs/
    ├── CONFIGURACAO.md      # Guia de configuração completo
    └── PROXY.md             # Guia do proxy HTTP
```

## Créditos

| MCP | Autor | Repositório |
|---|---|---|
| **tiav21** | [Czarnak](https://github.com/Czarnak) | [tia-portal-mcp](https://github.com/Czarnak/tia-portal-mcp) |
| **tiaolder** | [bulaofen0036-coder](https://github.com/bulaofen0036-coder) | [TIA Portal Openness MCP](https://github.com/bulaofen0036-coder/TIA_Portal_Openness_MCP) |

## Licença

MIT — veja [LICENSE](LICENSE).
