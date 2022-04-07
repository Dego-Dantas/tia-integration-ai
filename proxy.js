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

server.on('request', (req, res) => {
  const parsed = new URL(req.url);
  const isHttps = parsed.protocol === 'https:';
  const mod = isHttps ? https : http;
  const opts = {
    hostname: parsed.hostname,
    port: parsed.port || (isHttps ? 443 : 80),
    path: parsed.pathname + parsed.search,
    method: req.method,
    headers: req.headers,
  };
  delete opts.headers['proxy-connection'];
  delete opts.headers['proxy-authorization'];
  const proxyReq = mod.request(opts, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });
  proxyReq.on('error', () => {
    try { res.writeHead(502); res.end('Proxy error'); } catch (_) {}
  });
  req.pipe(proxyReq);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Proxy rodando em 0.0.0.0:${PORT}`);
});
