FROM node:22-slim

WORKDIR /app

# Installer le package + socat (pour forwarder 0.0.0.0:3000 → 127.0.0.1:3080)
RUN npm install -g @deepseek-ai/dsh && \
    apt-get update && apt-get install -y --no-install-recommends socat && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 3000

# dsh écoute sur 127.0.0.1:3080 (sécurité), socat forward vers 0.0.0.0:3000
CMD socat TCP-LISTEN:3000,fork,reuseaddr TCP:127.0.0.1:3080 & dsh web --no-open --port 3080 --host 127.0.0.1
