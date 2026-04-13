# Stage 1: Build & Compile
FROM node:20-alpine AS builder

WORKDIR /app

# Install build dependencies for Prisma and Bash for build scripts
RUN apk add --no-cache openssl g++ make python3 bash

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

# Generate Client and Build
RUN npx prisma generate
RUN npm run build

# Stage 2: Production Execution
FROM node:20-alpine AS runner

WORKDIR /app

# Ensure OpenSSL, libc6-compat and Bash are available for scripts/Prisma
RUN apk add --no-cache openssl libc6-compat bash

# Set Production Environment
ENV NODE_ENV=production
ENV PORT=4000

# Copy necessary files from builder
COPY --from=builder /app/package.json ./
COPY --from=builder /app/package-lock.json* ./
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/src ./src
COPY --from=builder /app/firebase-service-account.json* ./

# Install ONLY production dependencies
RUN npm install --omit=dev

# RE-GENERATE Prisma client in the final environment to ensure binaries match
RUN npx prisma generate

# Expose Port
EXPOSE 4000

# Permissions for start script
RUN chmod +x scripts/start.sh

# Run the automated production entrypoint
CMD ["bash", "scripts/start.sh"]
