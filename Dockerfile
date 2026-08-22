FROM node:22-slim AS builder

WORKDIR /app

# Installer git (nécessaire pour le build script qui appelle git rev-parse HEAD)
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*

# Installer pnpm 11.7.0 manuellement (évite corepack + Node 24 incompatibilité)
RUN npm install -g pnpm@11.7.0

# Copier tout le code source (nécessaire pour les postinstall scripts)
COPY . .

# Initialiser git (le build script a besoin de git rev-parse HEAD)
RUN git init && git add -A && git commit -m "build" --allow-empty

# Installer les dépendances
RUN pnpm install --frozen-lockfile

# Build du projet
RUN pnpm run build

# --- Stage de production ---
FROM node:22-slim

WORKDIR /app

# Installer pnpm en production
RUN npm install -g pnpm@11.7.0

# Copier les fichiers construits et nécessaires
COPY --from=builder /app/ ./

# Exposer le port de la Web UI
EXPOSE 3080

# Lancer le serveur Web
CMD ["pnpm", "dsh", "web", "--no-open"]
