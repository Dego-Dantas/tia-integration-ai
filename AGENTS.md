# Agents

Este projeto utiliza o sistema de **agents** do OpenCode para expor dois MCP servers distintos de integração com TIA Portal. Cada agent oferece um conjunto diferente de ferramentas e capacidades.

## @tiav21

MCP server **Czarnak** focado no TIA Portal V21.

| Propriedade | Valor |
|---|---|
| **MCP** | `tiav21` |
| **Servidor** | Czarnak — [tia-portal-mcp](https://github.com/Czarnak/tia-portal-mcp) |
| **Versão TIA** | V21 (fixo) |
| **Ferramentas** | ~25 |
| **Comando** | `tia-mcp.cmd` → `TiaMcpServer.exe` |

### Ferramentas

| Categoria | Tools |
|---|---|
| Navegação | `browse_project_tree` |
| Blocos | `get_block_content`, `update_block_logic` (write) |
| Tags | `list_tag_tables`, `create_tag`, `update_tag`, `delete_tag` |
| Hardware | `read_hardware_config`, `search_equipment_catalog` |
| Rede | `add_network_device`, `configure_network_device` |
| Diagnóstico | `read_cross_references`, `compile_check` |
| Projeto | `open_project`, `save_project`, `close_project` |

> Operações de escrita exigem `confirm=true` explícito.

### Uso

```
@tiav21 browse o projeto tia e me mostre a arvore
@tiav21 crie uma tag chamada "Sensor_01" do tipo BOOL
@tiav21 atualize a logica do bloco "Main" com este novo SCL
```

---

## @tiaolder

MCP server **bulaofen0036** com versão configurável do TIA Portal.

| Propriedade | Valor |
|---|---|
| **MCP** | `tiaolder` |
| **Servidor** | bulaofen0036 — TIA Openness MCP |
| **Versão TIA** | Configurável via `tiaolder-version.txt`: V20–V21 oficial (master); V19, V18, V17, V16 em branches comunitários |
| **Ferramentas** | ~189 |
| **Comando** | `tia-openness.cmd` |

### Configuração de Versão

O arquivo `tiaolder-version.txt` define qual versão do TIA o agent usará:

```
20  →  V20 (padrão)
21  →  V21
19  →  V19 (branch comunitário)
18  →  V18 (branch comunitário)
17  →  V17 (branch comunitário)
16  →  V16 (branch comunitário)
```

### Destaques

- Geração completa de projetos via `ScaffoldProject`
- Ampla cobertura da Openness API (~189 tools)
- Suporte a múltiplas versões do TIA Portal sem reconfigurar o servidor

### Uso

```
@tiaolder crie um projeto novo com um CLP S7-1200 ou S7-1500
@tiaolder adicione um bloco FB "ControleMotor" ao projeto
```

---

## Créditos

- **tiav21** — Desenvolvido por [Czarnak](https://github.com/Czarnak/tia-portal-mcp)
- **tiaolder** — Desenvolvido por bulaofen0036-coder — [TIA Portal Openness MCP](https://github.com/bulaofen0036-coder/TIA_Portal_Openness_MCP)

## Exemplo de Configuração (opencode.json)

```json
{
  "mcp": {
    "tiav21": {
      "type": "local",
      "command": ["cmd.exe", "/c", "C:\\TIA\\opencode-portable\\tia-mcp.cmd"],
      "enabled": true,
      "timeout": 120000
    },
    "tiaolder": {
      "type": "local",
      "command": ["cmd.exe", "/c", "C:\\TIA\\opencode-portable\\tia-openness.cmd"],
      "enabled": true,
      "timeout": 120000
    }
  }
}
```
