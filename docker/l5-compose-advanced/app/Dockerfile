# syntax=docker/dockerfile:1
# App image for the compose example. Two targets:
#   test     runs `npm test` (used by the compose `test` profile)
#   runtime  the production image (default, last stage)
FROM node:26.12.1-alpine3.24 AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci

FROM deps AS test
COPY server.js test.js ./
USER node
CMD ["npm", "test"]

FROM deps AS prod-deps
RUN npm prune --omit=dev

FROM node:26.12.1-alpine3.24 AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node package.json server.js ./
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:3000/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]
CMD ["node", "server.js"]
