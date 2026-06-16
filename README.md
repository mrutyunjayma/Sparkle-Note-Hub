# Sparkle Note

Sparkle Note is a pnpm monorepo for a full-stack note-taking app. It includes a React frontend, an Express API, shared TypeScript libraries, Docker deployment artifacts, and Terraform infrastructure for AWS.

## What It Includes

- A note dashboard for creating, editing, searching, filtering, and pinning notes
- A REST API backed by MongoDB
- Shared generated API client and Zod schema packages
- Docker images for the frontend and API
- Terraform modules for VPC, EKS, ECR, IAM, IRSA, and secrets management

## Monorepo Structure

```text
.
├── artifacts/
│   ├── sparkle-note-hub/   # React + Vite frontend
│   ├── api-server/         # Express API server
│   └── mockup-sandbox/     # UI sandbox/prototype area
├── lib/
│   ├── api-client-react/   # Generated React API client
│   ├── api-spec/           # OpenAPI spec and codegen config
│   ├── api-zod/            # Generated Zod schemas/types
│   ├── db/                 # Shared database package
│   └── mongodb/            # MongoDB connection utilities
├── scripts/                # Workspace helper scripts
└── terraform/infra/        # AWS infrastructure
```

## Tech Stack

- Frontend: React 19, Vite, TypeScript, TanStack Query, Wouter, Tailwind CSS, Radix UI, Framer Motion
- Backend: Express 5, TypeScript, MongoDB, Pino
- Tooling: pnpm workspaces, TypeScript project references, esbuild
- Infrastructure: Docker, Nginx, Terraform, AWS

## Prerequisites

- Node.js 20+
- pnpm
- MongoDB 7+ locally, or Docker

## Getting Started

### 1. Install dependencies

```bash
pnpm install
```

### 2. Start MongoDB

If you have MongoDB installed locally:

```bash
./scripts/start-mongodb.sh
```

Or use Docker Compose:

```bash
docker compose up mongodb -d
```

### 3. Run the API server

```bash
PORT=8080 MONGODB_URI=mongodb://127.0.0.1:27017 pnpm --filter @workspace/api-server dev
```

The API automatically seeds sample notes when the `notes` collection is empty.

### 4. Run the frontend

In a second terminal:

```bash
pnpm --filter @workspace/sparkle-note-hub dev
```

By default, the frontend runs on port `5173` and the API runs on port `8080`.

## Docker Compose

To run the full stack with MongoDB, API, and frontend:

```bash
docker compose up --build
```

Services:

- Frontend: `http://localhost:3000`
- API: `http://localhost:8080`
- MongoDB: `mongodb://localhost:27017`

## Useful Commands

```bash
pnpm build
pnpm typecheck
pnpm --filter @workspace/api-server build
pnpm --filter @workspace/sparkle-note-hub build
```

## Environment Variables

### API server

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `PORT` | Yes | none | Port the API server listens on |
| `MONGODB_URI` | No | `mongodb://127.0.0.1:27017` | MongoDB connection string |
| `MONGODB_DB_NAME` | No | `sparkle_note_hub` | MongoDB database name |
| `NODE_ENV` | No | app-defined | Runtime environment |

### Frontend

The frontend build currently relies on its Vite configuration and Docker build settings. If you plan to point it at a different API origin, check [artifacts/sparkle-note-hub/vite.config.ts](/home/mj/Sparkle-Note/artifacts/sparkle-note-hub/vite.config.ts).

## API Overview

Base path: `/api`

Main endpoints:

- `GET /healthz`
- `GET /notes`
- `POST /notes`
- `GET /notes/:id`
- `PUT /notes/:id`
- `DELETE /notes/:id`
- `PATCH /notes/:id/pin`
- `GET /notes/stats`
- `GET /notes/tags`
- `GET /notes/recent`

The OpenAPI definition lives in [lib/api-spec/openapi.yaml](/home/mj/Sparkle-Note/lib/api-spec/openapi.yaml).

## Deployment Notes

- The frontend Docker image builds the Vite app and serves it with Nginx.
- The API Docker image builds the Express server and runs the compiled output with Node.js.
- Terraform under [terraform/infra](/home/mj/Sparkle-Note/terraform/infra) provisions the AWS infrastructure needed for containerized deployment.

## Workspace Notes

- This repo uses `pnpm` only. The root `preinstall` script blocks `npm` and `yarn`.
- The workspace enforces a minimum npm package release age in `pnpm-workspace.yaml` as a supply-chain safety measure.
- There is a UI sandbox under `artifacts/mockup-sandbox` for experimentation separate from the main app.
