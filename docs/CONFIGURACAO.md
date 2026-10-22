# Guia de Configuração — OpenCode Portable v2 + TIA Portal MCP + Magic Context

Este guia descreve como configurar e utilizar o ambiente portátil do **OpenCode (v2+)** integrado ao **Siemens TIA Portal** via **MCP (`bulaofen0036-coder/TIA_Portal_Openness_MCP`)** e **Magic Context**.

---

## Arquitetura de Referência

```
VM (Windows) ─── Rede Local / VMnet1 ─── Host (Windows)
     │                                        │
     ├── Proxy HTTP/HTTPS (porta 3128) ───────┼──► Internet (APIs Cloud, npm, GitHub)
     └── API Local (porta 1234) ──────────────┴──► LMStudio / llama.cpp (Opcional)
```

- **VM (ou PC com TIA Portal)**: Executa o TIA Portal (V20/V21) e a pasta portátil do projeto.
- **Host**: Executa o `proxy/proxy.js` (caso a VM não tenha internet direta) e, opcionalmente, modelos locais (LMStudio / `llama.cpp`).

---

## Pré-requisitos

### Na máquina com TIA Portal (VM ou PC local)
- Windows 10/11 (x64)
- Siemens TIA Portal V20 e/ou V21 instalado com **TIA Portal Openness**
- Usuário do Windows adicionado ao grupo local `Siemens TIA Openness` (reiniciar sessão após adicionar)
- **.NET Framework 4.8 Runtime** (para TIA Portal V20)
- **.NET 8.0 Runtime** (para TIA Portal V21)

### No Host (apenas se usar VM offline ou modelo local)
- Node.js (para rodar `proxy/proxy.js`)
- *(Opcional)* LMStudio ou servidor compatível com OpenAI na porta `1234`

---

## Passo a Passo

### 1. Selecionar a Versão do TIA Portal

Edite o arquivo `tiaolder-version.txt` na raiz do projeto com o número da versão desejada:

```text
20  →  TIA Portal V20 (padrão)
21  →  TIA Portal V21
```

O wrapper `tia-openness.cmd` lê esse arquivo automaticamente e inicia o executável correspondente (`runtime\v20\TiaMcpServer.exe` ou `runtime\v21\TiaMcpServer.exe`) com `--profile full`.

### 2. Iniciar o Proxy no Host (se estiver em VM sem internet direta)

No Host, execute `proxy\iniciar-proxy.bat` ou via terminal:

```powershell
node proxy/proxy.js 3128
```

> O `opencode.bat` testa automaticamente se `192.168.79.1:3128` está ativo. Se estiver acessível, configura `HTTP_PROXY` e `HTTPS_PROXY`; caso contrário, usa a conexão direta da máquina.

### 3. Configurar Providers de IA (`config/opencode/opencode.json`)

O arquivo `config/opencode/opencode.json` usa o schema do **OpenCode v2** (`providers`, `mcp.servers`, `plugins`):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "Guias/MAGIC_CONTEXT_AGENTE.txt"
  ],
  "providers": {
    "lmstudio": {
      "name": "LMStudio Local (Host)",
      "package": "@opencode/ai/providers/openai-compatible",
      "settings": {
        "baseURL": "http://192.168.79.1:1234/v1",
        "apiKey": "sk-local"
      },
      "models": {
        "local-model": {
          "name": "Modelo Local (LMStudio / llama.cpp)",
          "capabilities": {
            "tools": true,
            "input": ["text"],
            "output": ["text"]
          },
          "limit": {
            "context": 131072,
            "output": 32768
          }
        }
      }
    }
  },
  "mcp": {
    "servers": {
      "TIA-PORTAL": {
        "type": "local",
        "command": [
          "cmd.exe",
          "/c",
          ".\\tia-openness.cmd"
        ],
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

> **IMPORTANTE — Sempre salvar `opencode.json` em UTF-8 SEM BOM:**
> O parser do plugin Magic Context não aceita UTF-8 com BOM (*Byte Order Mark*). Se o `opencode.json` tiver BOM, o plugin não consegue ler `compaction.auto: false` e se desativa no boot.

### 4. Configurar o Magic Context (`config/cortexkit/magic-context.jsonc`)

O arquivo `config/cortexkit/magic-context.jsonc` define qual modelo será usado em background pelo **`historian`** (resumo de turnos antigos) e pelo **`dreamer`** (memória do projeto). Por padrão, vem configurado com um modelo gratuito nativo do OpenCode (`opencode/gpt-5-nano`), funcionando sem configuração adicional.

Para alterar para outro modelo (local ou nuvem), consulte [Guias/GUIA_TROCAR_MODELO_MAGIC_CONTEXT.md](../Guias/GUIA_TROCAR_MODELO_MAGIC_CONTEXT.md).

### 5. Executar o OpenCode Portable

Dê dois cliques em **`opencode.bat`**.

- No primeiro uso (caso tenha clonado apenas o código-fonte do Git sem o `opencode.exe`), o `opencode.bat` executará automaticamente o `update-all.ps1` para baixar o `opencode.exe`.
- Todas as pastas de estado (`config/`, `data/`, `state/`, `cache/`) ficam contidas dentro da própria pasta portátil.

---

## Atualizador Automático (`atualizar.bat` / `update-all.ps1`)

> [!WARNING]
> **Recurso para Teste (Experimental — Pode Quebrar):**
> O script de atualização automática (`update-all.ps1` / `atualizar.bat`) foi criado **para testes** e pode quebrar caso o formato dos pacotes no npm ou das releases no GitHub mude. Faça backup da pasta antes de rodar.

Para atualizar o **OpenCode v2**, o **Magic Context** e o **MCP TIA-PORTAL (bulaofen0036)** sem perder suas configurações e removendo arquivos antigos (*zero leftovers*):

```powershell
# Atualizar tudo (ou dar duplo clique em atualizar.bat):
.\atualizar.bat

# Apenas verificar se existem versões novas disponíveis:
powershell -ExecutionPolicy Bypass -File .\update-all.ps1 -CheckOnly

# Atualizar apenas um componente ('opencode', 'magic-context' ou 'tia-mcp'):
powershell -ExecutionPolicy Bypass -File .\update-all.ps1 -Component tia-mcp
```

---

## Troubleshooting

| Problema | Solução |
|---|---|
| Ferramentas `ctx_*` do Magic Context não aparecem | Verifique se `config/opencode/opencode.json` está salvo em **UTF-8 sem BOM** e com `"compaction": { "auto": false }` |
| MCP `TIA-PORTAL` falha ao iniciar | Confirme a versão em `tiaolder-version.txt` (`20` ou `21`) e verifique se o usuário está no grupo `Siemens TIA Openness` (`whoami /groups \| findstr Openness`) |
| Erro de conexão na VM ao atualizar ou usar nuvem | Verifique se `proxy/iniciar-proxy.bat` está rodando no Host e se a porta `3128` está liberada no firewall |
| Modelo local (LMStudio) inacessível pela VM | No LMStudio do Host, ative *Bind to all interfaces (`0.0.0.0:1234`)* e certifique-se de que o IP do Host está no `NO_PROXY` |
