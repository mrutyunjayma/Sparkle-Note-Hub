# For base image
FROM node:20-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable


FROM base AS build
WORKDIR /app
#install depndencies
COPY pnpm-workspace.yaml pnpm-lock.yaml package.json ./
COPY tsconfig.base.json tsconfig.json ./
COPY .npmrc ./
COPY lib/ ./lib/
# Copy to api-server  file 
COPY artifacts/api-server/ ./artifacts/api-server/

#install frozen lockfile
RUN pnpm install --frozen-lockfile 
RUN pnpm --filter @workspace/api-server run build
RUN pnpm deploy --filter @workspace/api-server --prod --legacy /app/deploy

# Production image
FROM node:20-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=8080

# Copy the built api-server package and its dependencies from the build stage
COPY --from=build /app/deploy ./



# Expose the port that the api-server will run on
EXPOSE 8080
# Set the command to run the api-server
CMD ["node", "--enable-source-maps", "dist/index.mjs"]