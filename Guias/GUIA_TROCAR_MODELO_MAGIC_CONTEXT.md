# Guia: Como Trocar o Modelo do Historian e do Dreamer (Magic Context)

Este guia explica como alterar o modelo de IA usado em background pelo **Magic Context** (`historian` e `dreamer`) no OpenCode Portable.

---

## 1. Onde Fica a Configuração (Fonte da Verdade)

Sempre edite o arquivo da pasta portátil:

- **Caminho relativo:** `config\cortexkit\magic-context.jsonc`

> ⚠️ **NUNCA edite** diretamente `%USERPROFILE%\.config\cortexkit\magic-context.jsonc`. O `opencode.bat` sobrescreve esse arquivo a cada inicialização usando `config\cortexkit\magic-context.jsonc`.

---

## 2. Como Trocar o Modelo

Abra `config\cortexkit\magic-context.jsonc` e altere o campo `"model"` (formato `"provider_id/model_id"`) dentro de `historian.opencode` e `dreamer.opencode`:

```jsonc
{
  "$schema": "https://raw.githubusercontent.com/cortexkit/magic-context/master/assets/magic-context.schema.json",
  "language": "pt",
  "auto_update": false,
  "allow_home_project": true,
  "historian_timeout_ms": 600000,
  "historian": {
    "opencode": {
      "model": "opencode/gpt-5-nano",
      "fallback_models": []
    },
    "maxTokens": 8192
  },
  "embedding": {
    "provider": "off"
  },
  "dreamer": {
    "opencode": {
      "model": "opencode/gpt-5-nano",
      "fallback_models": []
    },
    "maxTokens": 8192
  }
}
```

### Exemplos de modelos compatíveis:
- **Modelos gratuitos nativos do OpenCode (`opencode`):**
  - `"opencode/gpt-5-nano"`
  - `"opencode/mimo-v2-omni-free"`
  - `"opencode/big-pickle"`
- **Modelo local configurado no `config\opencode\opencode.json`:**
  - `"lmstudio/local-model"` (ou o ID configurado no seu provider local)

---

## 3. Aplicar a Mudança

Após salvar `config\cortexkit\magic-context.jsonc`:
1. Feche o OpenCode caso esteja aberto.
2. Abra novamente pelo **`opencode.bat`** (ele copiará a nova configuração para `%USERPROFILE%\.config\cortexkit\magic-context.jsonc` automaticamente).
