FROM node:22-slim

WORKDIR /app

# DeepSeek Harness via npx (package npm publié, pas besoin de build from source)
EXPOSE 3080

CMD ["npx", "@deepseek-ai/dsh", "web", "--no-open"]
