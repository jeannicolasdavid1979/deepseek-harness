FROM node:22-slim

WORKDIR /app

# Installer le package DSH
RUN npm install -g @deepseek-ai/dsh

# Créer le proxy HTTP (port externe 3000 -> interne 3080)
RUN echo 'import { createServer, request as httpRequest } from "node:http";\n\
\n\
const server = createServer((req, res) => {\n\
  const proxyReq = httpRequest({\n\
    host: "127.0.0.1", port: 3080, method: req.method, path: req.url,\n\
    headers: { ...req.headers, host: "127.0.0.1:3080" },\n\
  }, (proxyRes) => {\n\
    res.writeHead(proxyRes.statusCode, proxyRes.headers);\n\
    proxyRes.pipe(res);\n\
  });\n\
  proxyReq.on("error", (e) => { res.writeHead(502); res.end("Bad Gateway: " + e.message); });\n\
  req.pipe(proxyReq);\n\
});\n\
\n\
server.listen(3000, "0.0.0.0", () => console.log("[proxy] 0.0.0.0:3000 -> 127.0.0.1:3080"));' > /app/proxy.mjs

# Créer le script d'entrée
COPY dsh-entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 3000

CMD ["/app/entrypoint.sh"]
