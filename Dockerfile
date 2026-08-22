FROM node:22-slim AS builder

WORKDIR /app

# Installer pnpm 11.7.0 manuellement (évite corepack + Node 24 incompatibilité)
RUN npm install -g pnpm@11.7.0

# Copier tout le code source (nécessaire pour les postinstall scripts)
COPY . .

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

# Installer seulement les dépendances de production
RUN pnpm install --frozen-lockfile --prod

# Exposer le port de la Web UI
EXPOSE 3080

# Lancer le serveur Web
CMD ["pnpm", "dsh", "web", "--no-open"]
