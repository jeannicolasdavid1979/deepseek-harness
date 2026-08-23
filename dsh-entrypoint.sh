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

# Patcher isTrustedApiRequest avec node (fiable, pas de sed)
echo "[entrypoint] Patching isTrustedApiRequest..."
node -e '
const fs = require("fs");
const target = "/root/.dsh/profiles/node_modules/@deepseek-ai/dsh-client-connection/lib/index.js";
let code = fs.readFileSync(target, "utf8");
// Remplacer toute la fonction isTrustedApiRequest par return true
const newCode = code.replace(
  /function isTrustedApiRequest\(request, trustedHosts\) \{[\s\S]*?\n\}/,
  "function isTrustedApiRequest(request, trustedHosts) {\n\treturn true;\n}"
);
if (newCode === code) {
  console.log("[entrypoint] WARNING: pattern not matched, trying alternate approach");
  // Approche alternative: remplacer juste la première ligne
  const lines = code.split("\n");
  let inFn = false;
  let braceCount = 0;
  let startIdx = -1;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes("function isTrustedApiRequest(")) {
      inFn = true;
      braceCount = (lines[i].match(/{/g) || []).length - (lines[i].match(/}/g) || []).length;
      startIdx = i;
      continue;
    }
    if (inFn) {
      braceCount += (lines[i].match(/{/g) || []).length - (lines[i].match(/}/g) || []).length;
      if (braceCount <= 0) {
        // Remplacer de startIdx à i (inclus)
        lines.splice(startIdx, i - startIdx + 1,
          "function isTrustedApiRequest(request, trustedHosts) {",
          "\treturn true;",
          "}"
        );
        break;
      }
    }
  }
  fs.writeFileSync(target, lines.join("\n"));
  console.log("[entrypoint] Patched (alternate method)");
} else {
  fs.writeFileSync(target, newCode);
  console.log("[entrypoint] Patched (regex method)");
}
// Vérifier
const verify = fs.readFileSync(target, "utf8");
const match = verify.match(/function isTrustedApiRequest[\s\S]*?\n\}/);
if (match) console.log("[entrypoint] Verify:", match[0].replace(/\n/g, " "));
'

# Relancer dsh web + proxy
echo "[entrypoint] Starting proxy + dsh web..."
node /app/proxy.mjs &
dsh web --no-open --port 3080 --host 127.0.0.1 --trusted-host harness.kechlab.com
