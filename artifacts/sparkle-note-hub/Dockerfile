# use node:20-alpine as base image
FROM node:20-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

# stage 1: build stage
FROM base AS build
WORKDIR /app

COPY pnpm-workspace.yaml pnpm-lock.yaml package.json ./
COPY tsconfig.base.json tsconfig.json ./
COPY .npmrc ./
COPY lib/ ./lib/
COPY artifacts/sparkle-note-hub/ ./artifacts/sparkle-note-hub/
RUN pnpm install --frozen-lockfile
RUN PORT=3000 BASE_PATH=/ pnpm --filter @workspace/sparkle-note-hub run build

# stage 2: production stage
FROM nginx:alpine AS runtime
COPY --from=build /app/artifacts/sparkle-note-hub/dist/public/ /usr/share/nginx/html/
COPY artifacts/sparkle-note-hub/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]