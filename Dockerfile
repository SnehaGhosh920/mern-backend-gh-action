# ============================================================
# TaskFlow Backend - Production Docker Image
# ============================================================

FROM node:24-alpine AS dependencies

WORKDIR /app

# Copy package manifests first for layer caching.
COPY package*.json ./

# Use the lock file when available.
# --omit=dev replaces the old --only=production syntax.
RUN if [ -f package-lock.json ]; then \
      npm ci --omit=dev; \
    else \
      npm install --omit=dev; \
    fi


FROM node:24-alpine AS production

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5000

# Copy production dependencies.
COPY --from=dependencies /app/node_modules ./node_modules

# Copy package metadata and application source.
COPY package*.json ./
COPY . .

EXPOSE 5000

# Node's official image already provides a non-root "node" user.
USER node

# Node 24 provides global fetch.
HEALTHCHECK \
    --interval=30s \
    --timeout=5s \
    --start-period=20s \
    --retries=3 \
    CMD node -e "fetch('http://127.0.0.1:5000/api/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

CMD ["node", "server.js"]

