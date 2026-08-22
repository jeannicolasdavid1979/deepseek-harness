FROM node:22-slim

WORKDIR /app

# Installer le package pendant le build (une seule fois, pas à chaque démarrage)
RUN npm install -g @deepseek-ai/dsh

EXPOSE 3080

CMD ["dsh", "web", "--no-open"]
