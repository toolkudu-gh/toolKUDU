FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy server and web build
COPY server.js ./
COPY web ./web

# Expose port
EXPOSE 8080

# Start server
CMD ["npm", "start"]
