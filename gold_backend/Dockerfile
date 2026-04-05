# Stage 1: Build the Node application
FROM node:20-alpine AS builder

WORKDIR /app

# Install openssl which is critically required by Prisma ORM
RUN apk add --no-cache openssl

# Copy package configurations and install ALL dependencies (including dev)
COPY package.json package-lock.json* ./
RUN npm install

# Copy source code and Prisma schema
COPY . .

# Generate the Prisma database client
RUN npx prisma generate

# Compile TypeScript into native Javascript inside the 'dist/' folder
RUN npm run build

# Stage 2: Production Execution (Lighter image with no dev-dependencies)
FROM node:20-alpine

WORKDIR /app

# OpenSSL is still required in the production layer for Prisma to query the DB
RUN apk add --no-cache openssl

# Copy only exactly what is needed for production
COPY --from=builder /app/package.json ./
COPY --from=builder /app/package-lock.json* ./

# Ignore devDependencies like typescript entirely to save enormous RAM/Space
RUN npm install --omit=dev

# Copy the built code and generated schema hooks
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
# Copying existing environment variables (ensure these exist locally before committing, or remove this line and inject via Coolify UI)
COPY --from=builder /app/.env ./.env

# Tell Coolify to route traffic to port 4000
EXPOSE 4000

# Start the Node HTTP Express Server
CMD ["npm", "run", "start"]
