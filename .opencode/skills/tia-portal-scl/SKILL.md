---
name: tia-portal-scl
description: Programação Siemens TIA Portal V20/V21 — SCL, LAD, blocos OB/FB/FC/DB, UDTs, tags, hardware e HMI Unified via MCP TIA-PORTAL
license: MIT
compatibility: opencode
metadata:
  domain: industrial-automation
  plc-family: siemens-s7
  ide: tia-portal-v20-v21
---

## O que faz

Especialista em desenvolvimento e automação para CLPs Siemens S7-1200/1500 e IHM WinCC Unified no TIA Portal (V20 e V21) utilizando o servidor MCP `TIA-PORTAL` (`bulaofen0036-coder/TIA_Portal_Openness_MCP` v2.7.5).

## Quando usar

Use este skill sempre que estiver:
- Criando ou modificando blocos SCL/LAD (OB, FB, FC, Global DB, Instance DB, UDT) no TIA Portal
- Gerando projetos completos via `ScaffoldProject` ou `PlcBuildAndImport`
- Estruturando tabelas de tags, topologia de hardware/PROFINET ou telas WinCC Unified

## Regras fundamentais

1. Sintaxe IEC 61131-3 compatível com Siemens TIA Portal (SCL / LAD / FBD).
2. MLCIDs em exports SimaticSD/XML no formato `MLC_xxx` — sem espaços, acentos ou caracteres especiais, com entrada correspondente em `MultiLingualTexts`.
3. O único agent TIA do pacote é o `@tiaolder` (servidor MCP `TIA-PORTAL`).
4. Prefixo `TIA-PORTAL_` em todas as tools MCP; em caso de dúvida sobre nome ou assinatura de uma ferramenta, use `TIA-PORTAL_FindTools("palavras")` e depois `TIA-PORTAL_CallTool`.
5. Sempre valide imports com `dryRun=true` quando disponível e execute `CompileAndDiagnosePlc` após alterações.

## Documentação de referência no pacote

No delivery ativo (`tia-openness-mcp\TIA_MCP_Delivery_v2.7.5_20261014\docs\`):
- `scl-instruction-library.md` — biblioteca de instruções SCL
- `lad-instruction-library.md` — biblioteca de instruções LAD
- Guias oficiais de CLI, HMI Unified, geração de projeto e VCI/Git
