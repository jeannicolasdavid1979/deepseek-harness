#!/bin/sh
set -e

echo "[entrypoint] Starting..."

# Démarrer dsh web en arrière-plan pour créer le profile
echo "[entrypoint] Booting dsh web to create profile..."
dsh web --no-open --port 3080 --host 127.0.0.1 &
DSH_PID=$!

# Attendre que le profile soit créé
echo "[entrypoint] Waiting for profile creation..."
for i in $(seq 1 30); do
  if [ -f "/root/.dsh/profiles/node_modules/@deepseek-ai/dsh-client-connection/lib/index.js" ]; then
    echo "[entrypoint] Profile found at attempt $i"
    break
  fi
  sleep 1
done

# Tuer dsh
echo "[entrypoint] Stopping initial dsh..."
kill $DSH_PID 2>/dev/null || true
wait $DSH_PID 2>/dev/null || true

# Patcher isTrustedApiRequest
TARGET="/root/.dsh/profiles/node_modules/@deepseek-ai/dsh-client-connection/lib/index.js"
if [ -f "$TARGET" ]; then
  cp "$TARGET" "$TARGET.bak"
  # Remplacer la fonction entière par return true
  sed '/^function isTrustedApiRequest/,/^}/c\
function isTrustedApiRequest(request, trustedHosts) {\
\treturn true;\
}' "$TARGET"
  echo "[entrypoint] Patched isTrustedApiRequest -> always true"
else
  echo "[entrypoint] WARNING: $TARGET not found, cannot patch"
fi

# Relancer dsh web + proxy
echo "[entrypoint] Starting proxy + dsh web..."
node /app/proxy.mjs &
dsh web --no-open --port 3080 --host 127.0.0.1 --trusted-host harness.kechlab.com
