# Proxy HTTP CONNECT

Servidor proxy HTTP CONNECT puro em Node.js (sem dependências) para permitir que uma **VM offline** acesse a internet via o host.

## Iniciar o Proxy

```powershell
node proxy.js 3128
```

Deixe a janela aberta. Enquanto ela estiver rodando, a VM tem acesso à internet.

### Iniciar Oculto (sem janela)

```powershell
Start-Process -WindowStyle Hidden -FilePath "node" -ArgumentList '"C:\caminho\proxy.js" 3128'
```

### Iniciar Automaticamente no Login

Coloque um atalho em:
```
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\
```

## Verificar se Está Rodando

```powershell
Get-NetTCPConnection -LocalPort 3128 | Select-Object LocalPort, State
```

Resposta esperada: `3128 Listen`

## Parar o Proxy

```powershell
Get-Process -Name "node" | Stop-Process -Force
```

## Testar Conectividade

### Do Host

```powershell
$env:HTTPS_PROXY='http://localhost:3128'
Invoke-RestMethod -Uri 'https://api.seu-provedor.com/v1/models' -Headers @{Authorization="Bearer $env:API_KEY"}
```

### Da VM

```cmd
curl http://host:3128
```

## Variáveis de Ambiente na VM

```cmd
set HTTP_PROXY=http://host:3128
set HTTPS_PROXY=http://host:3128
set NO_PROXY=localhost,127.0.0.1,host
```

> `NO_PROXY` com o IP do host é importante para tráfego local (provedores locais) não passar pelo proxy.

## Acesso a Modelos Locais

Provedores locais rodando no host ficam acessíveis pela VM via rede VMnet1. Certifique-se de configurar o provedor para escutar em `0.0.0.0:1234`.

## Troubleshooting

| Problema | Causa | Solução |
|---|---|---|
| `node` não encontrado | Node.js não instalado | `where node` |
| Porta 3128 ocupada | Outro processo | `netstat -ano | findstr :3128` e matar o PID |
| VM não conecta | Firewall bloqueando | Liberar porta 3128 no firewall do host |
| Provedor local inacessível | Escutando só localhost | Configurar bind em `0.0.0.0` |

## Código Fonte

```javascript
const http = require('http');
const https = require('https');
const net = require('net');

const PORT = parseInt(process.argv[2]) || 3128;
const server = http.createServer();

server.on('connect', (req, clientSocket, head) => {
  const [host, portStr] = req.url.split(':');
  const port = parseInt(portStr) || 443;
  const serverSocket = net.connect(port, host, () => {
    clientSocket.write('HTTP/1.1 200 Connection Established\r\n\r\n');
    serverSocket.write(head);
    serverSocket.pipe(clientSocket);
    clientSocket.pipe(serverSocket);
  });
  serverSocket.on('error', () => {
    try { clientSocket.write('HTTP/1.1 502 Bad Gateway\r\n\r\n'); clientSocket.end(); } catch (_) {}
  });
  clientSocket.on('error', () => serverSocket.destroy());
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Proxy rodando em 0.0.0.0:${PORT}`);
});
```
