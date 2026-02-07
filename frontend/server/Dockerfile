FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci --omit=dev

# Copy server and web build
COPY server.js ./
COPY web ./web

# Expose port
EXPOSE 8080

# Start server
CMD ["node", "server.js"]
