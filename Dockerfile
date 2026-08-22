FROM node:22-slim

WORKDIR /app

# Installer le package pendant le build (une seule fois, pas à chaque démarrage)
RUN npm install -g @deepseek-ai/dsh

EXPOSE 3000

# dsh écoute sur 3000 pour matcher le port Coolify par défaut
CMD ["dsh", "web", "--no-open", "--port", "3000"]
