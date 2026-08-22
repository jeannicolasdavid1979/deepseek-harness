FROM node:22-slim AS builder

WORKDIR /app

# Installer pnpm 11.7.0 manuellement (évite corepack + Node 24 incompatibilité)
RUN npm install -g pnpm@11.7.0

# Copier les fichiers de dépendances
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY patches/ ./patches/

# Installer les dépendances (frozen lockfile pour reproductibilité)
RUN pnpm install --frozen-lockfile

# Copier le reste du code
COPY . .

# Build du projet
RUN pnpm run build

# --- Stage de production ---
FROM node:22-slim

WORKDIR /app

# Installer pnpm en production
RUN npm install -g pnpm@11.7.0

# Copier les fichiers de dépendances
COPY --from=builder /app/package.json /app/pnpm-lock.yaml /app/pnpm-workspace.yaml ./
COPY --from=builder /app/patches/ ./patches/
COPY --from=builder /app/apps/ ./apps/
COPY --from=builder /app/packages/ ./packages/
COPY --from=builder /app/vendor/ ./vendor/
COPY --from=builder /app/native/ ./native/
COPY --from=builder /app/tsdown.config.ts ./
COPY --from=builder /app/tsconfig.json ./
COPY --from=builder /app/tsconfig.base.json ./
COPY --from=builder /app/tsconfig.host.json ./
COPY --from=builder /app/tsconfig.client.json ./

# Installer seulement les dépendances de production
RUN pnpm install --frozen-lockfile --prod

# Exposer le port de la Web UI
EXPOSE 3080

# Lancer le serveur Web
CMD ["pnpm", "dsh", "web", "--no-open"]
