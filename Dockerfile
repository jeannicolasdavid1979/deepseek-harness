FROM node:22-slim

WORKDIR /app

# Installer le package
RUN npm install -g @deepseek-ai/dsh

EXPOSE 3000

# Créer un proxy HTTP en Node.js qui préserve les headers
# DSH bloque 0.0.0.0 (sécurité RCE), on lance sur 127.0.0.1:3080
# Le proxy forward 0.0.0.0:3000 -> 127.0.0.1:3080 en passant le bon Host
RUN cat > /app/proxy.mjs << 'PROXYEOF'
import { createServer, request as httpRequest } from 'node:http'

const TARGET = { host: '127.0.0.1', port: 3080 }

const server = createServer((req, res) => {
  const proxyReq = httpRequest({
    host: TARGET.host,
    port: TARGET.port,
    method: req.method,
    path: req.url,
    headers: { ...req.headers, host: 'harness.kechlab.com' },
  }, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers)
    proxyRes.pipe(res)
  })
  proxyReq.on('error', (e) => {
    res.writeHead(502)
    res.end('Bad Gateway: ' + e.message)
  })
  req.pipe(proxyReq)
})

server.listen(3000, '0.0.0.0', () => console.log('[proxy] listening on 0.0.0.0:3000 -> 127.0.0.1:3080'))
PROXYEOF

CMD node /app/proxy.mjs & dsh web --no-open --port 3080 --host 127.0.0.1 --trusted-host harness.kechlab.com
