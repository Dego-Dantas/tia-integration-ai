# Proxy HTTP CONNECT (`proxy/proxy.js`)

Servidor proxy HTTP CONNECT puro em Node.js (sem dependências) para permitir que uma **VM isolada** acesse a internet através do Host na porta **3128**.

---

## Iniciar o Proxy no Host

Dê dois cliques em **`proxy\iniciar-proxy.bat`** ou execute no PowerShell:

```powershell
node proxy/proxy.js 3128
```

Deixe a janela aberta. Enquanto ela estiver rodando, a VM terá acesso à internet.

### Iniciar Oculto (sem janela)

```powershell
Start-Process -WindowStyle Hidden -FilePath "node" -ArgumentList '"C:\caminho\para\proxy\proxy.js" 3128'
```

### Iniciar Automaticamente no Login do Windows

Crie um atalho para `proxy\iniciar-proxy.bat` dentro de `shell:startup` (`%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\`).

---

## Verificar se Está Rodando

```powershell
Get-NetTCPConnection -LocalPort 3128 | Select-Object LocalPort, State, OwningProcess
```

Resposta esperada: `3128 Listen`.

## Parar o Proxy

Feche a janela do terminal do proxy ou execute:

```powershell
Get-NetTCPConnection -LocalPort 3128 | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
```

---

## Como a VM Usa o Proxy

O `opencode.bat` e o `update-all.ps1` detectam automaticamente se o proxy em `192.168.79.1:3128` está ativo e definem:

```cmd
set HTTP_PROXY=http://192.168.79.1:3128
set HTTPS_PROXY=http://192.168.79.1:3128
set NO_PROXY=localhost,127.0.0.1,192.168.79.1
```

> Caso o IP do seu Host na rede virtual seja diferente de `192.168.79.1`, ajuste o IP no `opencode.bat` e no `update-all.ps1`.
> `NO_PROXY` com o IP do Host é essencial para que chamadas a modelos locais (ex: LMStudio na porta `1234`) vão direto para o Host sem passar pelo proxy.

---

## Troubleshooting

| Problema | Causa | Solução |
|---|---|---|
| `node` não encontrado | Node.js não instalado no Host | Instale o Node.js e verifique com `where node` |
| Porta 3128 ocupada | Outra instância do proxy já está rodando | Verifique com `netstat -ano \| findstr :3128` |
| VM não conecta ao proxy | Firewall do Host bloqueando a porta 3128 | Libere a porta TCP `3128` no Firewall do Windows no Host |
| LMStudio inacessível na VM | Escutando apenas em `127.0.0.1` | Configure o LMStudio para escutar em `0.0.0.0:1234` |
