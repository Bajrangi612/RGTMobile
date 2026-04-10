#!/bin/bash

# --- Obsidian Elite Production Entrypoint ---
# This script ensures the database is synchronized and configurations 
# are seeded before starting the application.

echo "🚀 Starting Royal Gold Backend Recovery..."

# 1. Apply Database Migrations (Idempotent)
echo "📂 Applying database migrations..."
npx prisma migrate deploy

# 2. Seed Global Settings & Admin
echo "🌱 Seeding global configurations..."
npx prisma db seed || echo "⚠️  Seeding skipped or failed (non-critical)"

# 3. Heal Dirty Data (Purge empty strings/NULLs)
echo "🛡️  Healing database integrity..."
npx tsx src/repair-data.ts || echo "⚠️  Data healing skipped or failed (non-critical)"

# 4. Start the Production Server
echo "🔥 Igniting Obsidian Elite Terminal..."
node dist/index.js
