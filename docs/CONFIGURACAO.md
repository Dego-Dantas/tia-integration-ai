# Guia de Configuração — OpenCode + TIA Portal MCP

Este guia descreve como configurar o ambiente de integração entre OpenCode (CLI com IA) e Siemens TIA Portal usando o protocolo MCP com dois servidores distintos.

## Arquitetura de Referência

```
VM (Windows) ─── VMnet1 ─── Host (Windows)
     │                            │
     │  proxy HTTP/HTTPS          │ Wi-Fi → Internet
     └── http://host:3128 ────────┘
```

- **VM**: Máquina virtual com TIA Portal, OpenCode e servidores MCP
- **Host**: Máquina física com proxy Node.js e modelos locais

## Pré-requisitos

### VM
- Windows 10/11
- .NET SDK 8.0.421+
- .NET Framework 4.8 Runtime
- TIA Portal V20+ instalado com Openness API
- Usuário no grupo `Siemens TIA Openness`

### Host
- Node.js
- VMware com adaptador VMnet1 ativo

## Servidores MCP

Este projeto utiliza **dois servidores MCP** com propósitos distintos:

### tiav21 (Czarnak — ~25 tools)

Focado no TIA Portal V21. Usado para edição de blocos SCL/LAD, tags, hardware e navegação.

**Comando:** `scripts/tia-mcp.cmd`
```batch
@echo off
"%~dp0..\tia-mcp\TiaMcpServer.exe"
```

### tiaolder (bulaofen0036 — ~189 tools)

Versão configurável (V16–V21, ver branches do repositório). Usado para geração completa de projetos.

**Comando:** `scripts/tia-openness.cmd`
```batch
@echo off
set /p TIA_VER=<"%~dp0tiaolder-version.txt"
"%~dp0..\tia-openness-mcp\TIA_MCP_Delivery_v2.2.4_20260615\tools\tiaportal-mcp\src\TiaMcpServer\bin-v20\Release\net48\TiaMcpServer.exe" --tia-major-version %TIA_VER% %*
```

A versão do TIA é definida em `scripts/tiaolder-version.txt`:

```
20  →  V20 (padrão)
21  →  V21
19  →  V19 (branch comunitário)
18  →  V18 (branch comunitário)
17  →  V17 (branch comunitário)
16  →  V16 (branch comunitário)
```

## Configuração Passo a Passo

### 1. Proxy no Host

Inicie o proxy HTTP CONNECT no host para dar acesso à internet para a VM:

```powershell
node proxy.js 3128
```

Para iniciar automaticamente no login, coloque um atalho em `shell:startup`.

### 2. Copiar Arquivos para a VM

Copie a pasta do projeto para a VM em `C:\TIA\opencode-portable\`.

Ajuste os caminhos nos wrappers em `scripts/` para refletir a localização dos executáveis MCP na sua máquina.

### 3. Configurar Variáveis de Ambiente

Na VM, antes de iniciar o OpenCode:

```cmd
set HTTP_PROXY=http://host:3128
set HTTPS_PROXY=http://host:3128
set NO_PROXY=localhost,127.0.0.1,host
set API_KEY=sk-sua-chave
```

> `NO_PROXY` com o IP do host é essencial para que o tráfego de provedores locais (porta 1234) vá direto para o host sem passar pelo proxy.

### 4. Configurar opencode.json

Copie o arquivo de exemplo e edite com suas credenciais:

```bash
cp opencode.example.json opencode.json
```

O arquivo deve conter ambos os MCPs e os providers desejados:

```json
{
  "provider": {
    "meu-provedor-nuvem": {
      "options": {
        "apiKey": "sk-sua-chave",
        "baseURL": "https://api.provedor.com/v1"
      }
    },
    "meu-provedor-local": {
      "api": "openai",
      "options": {
        "baseURL": "http://host:1234/v1",
        "apiKey": "sk-local"
      }
    }
  },
  "mcp": {
    "tiav21": {
      "type": "local",
      "command": ["cmd.exe", "/c", "C:\\caminho\\scripts\\tia-mcp.cmd"],
      "enabled": true,
      "timeout": 120000
    },
    "tiaolder": {
      "type": "local",
      "command": ["cmd.exe", "/c", "C:\\caminho\\scripts\\tia-openness.cmd"],
      "enabled": true,
      "timeout": 120000
    }
  }
}
```

> **Importante:** Se houver um arquivo `%USERPROFILE%\.opencode\opencode.json` na VM, ele pode conflitar com a config da pasta portátil. Certifique-se de que ambos tenham as mesmas entradas MCP.

## Uso dos Agents

Com a configuração pronta, dentro do OpenCode:

```
@tiav21 browse o projeto tia e me mostre a arvore
@tiav21 crie uma tag "Sensor_01" do tipo BOOL
@tiav21 atualize a logica do bloco "Main" com este SCL

@tiaolder crie um projeto novo com um CLP S7-1200 ou S7-1500
@tiaolder adicione um bloco FB "ControleMotor" ao projeto
```

Consulte [AGENTS.md](../AGENTS.md) para a lista completa de ferramentas de cada agent.

## Comandos de Diagnóstico

### Testar worker tiav21

```cmd
echo {"method":"browse_project_tree","projectPath":null} | "C:\caminho\tia-mcp\openness-worker\TiaMcpServer.OpennessWorker.exe"
```

### Testar servidor MCP completo (tiav21)

```cmd
echo {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}} | dotnet "C:\caminho\tia-mcp\TiaMcpServer.dll"
```

### Verificar proxy

```powershell
Get-NetTCPConnection -LocalPort 3128
```

### Testar conectividade da VM

```powershell
Invoke-RestMethod -Uri 'https://api.seu-provedor.com/v1/models' -Headers @{Authorization="Bearer $env:API_KEY"}
```

## Acesso a Modelos Locais

Provedores locais rodando no **host** ficam acessíveis pela VM via rede VMnet1.

**Requisito:** Configurar o provedor local para escutar em `0.0.0.0:1234`.

Para testar da VM:
```cmd
curl http://host:1234/v1/models
```

## Troubleshooting

| Problema | Solução |
|---|---|
| MCP "failed" ao abrir | Verificar config duplicada em `%USERPROFILE%\.opencode\opencode.json` |
| `-32000: Connection closed` | Servidor MCP crashou ou timeout — aumentar timeout para 120s e verificar se TIA Portal está aberto |
| Conexão fechada | Aumentar timeout para 120s |
| Proxy não conecta | Liberar porta 3128 no firewall do host |
| Worker access denied | Verificar grupo `Siemens TIA Openness` com `whoami /groups \| findstr Openness` |
| `dotnet.exe` não encontrado | Usar `cmd.exe /c` com wrapper (caminho com espaços) |
| Provedor local inacessível na VM | Proxy roteando tráfego local — adicionar IP do host no `NO_PROXY` |

## Segurança

- Chaves de API ficam em texto plano nos arquivos de configuração — mantenha os arquivos seguros e não os compartilhe
- O `.gitignore` já exclui `*.bat`, `*.cmd` e `opencode.json` para evitar vazamento de credenciais
- Para isolamento total, use modelos locais em vez de APIs de nuvem
- O tráfego VM→Host via VMnet1 é rede privada local

## Referências

- [TIA Portal MCP (Czarnak)](https://github.com/Czarnak/tia-portal-mcp)
- [TiaMcpServer NuGet](https://www.nuget.org/packages/TiaMcpServer)
- [OpenCode docs](https://opencode.ai/docs)

