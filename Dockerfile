FROM node:22-slim

WORKDIR /app

# Installer le package pendant le build (une seule fois, pas à chaque démarrage)
RUN npm install -g @deepseek-ai/dsh

EXPOSE 3000

# dsh écoute sur 0.0.0.0:3000 pour être accessible depuis Traefik/Coolify
CMD ["dsh", "web", "--no-open", "--port", "3000", "--host", "0.0.0.0"]
