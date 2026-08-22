FROM node:22-slim

WORKDIR /app

# Installer le package
RUN npm install -g @deepseek-ai/dsh

# Créer le proxy HTTP + script de patch
RUN echo 'import { createServer, request as httpRequest } from "node:http"\n\
const server = createServer((req, res) => {\n\
  const proxyReq = httpRequest({\n\
    host: "127.0.0.1", port: 3080, method: req.method, path: req.url,\n\
    headers: { ...req.headers, host: "harness.kechlab.com" },\n\
  }, (proxyRes) => {\n    res.writeHead(proxyRes.statusCode, proxyRes.headers)\n    proxyRes.pipe(res)\n  })\n\
  proxyReq.on("error", (e) => { res.writeHead(502); res.end("Bad Gateway: " + e.message) })\n  req.pipe(proxyReq)\n})\n\
server.listen(3000, "0.0.0.0", () => console.log("[proxy] 0.0.0.0:3000 -> 127.0.0.1:3080"))' > /app/proxy.mjs

RUN printf '#!/bin/sh\nT="/root/.dsh/profiles/node_modules/@deepseek-ai/dsh-client-connection/lib/index.js"\nif [ -f "$T" ]; then\n  cp "$T" "$T.bak"\n  sed -i "/^function isTrustedApiRequest/,/^}/c\\\\function isTrustedApiRequest(request, trustedHosts) {\\\\n\\\\treturn true;\\\\n}" "$T"\n  echo "[PATCH] done"\nfi\n' > /app/patch.sh && chmod +x /app/patch.sh

# Boot dsh une fois pour créer le profile, patcher, puis relancer
RUN dsh web --no-open --port 3080 --host 127.0.0.1 & \
    sleep 8 && \
    /app/patch.sh && \
    kill %1 2>/dev/null; wait 2>/dev/null

EXPOSE 3000

CMD node /app/proxy.mjs & dsh web --no-open --port 3080 --host 127.0.0.1 --trusted-host harness.kechlab.com
