# Stage 1: Build & install dependencies
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
# ĐÃ FIX TẬN GỐC: Dùng npm install để không bao giờ bị gãy do thiếu package-lock.json
RUN npm install --only=production

# Stage 2: Runtime Environment
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .

EXPOSE 8080
CMD ["npm", "start"]
