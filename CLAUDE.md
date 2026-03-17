# Mordor's Edge - Project Guidelines

## Project Overview

Demo Rails + React application for deployment testing and disaster recovery training. LOTR-themed. See [PRD.md](PRD.md) for full requirements.

## Project Structure

```
mordors-edge/
  backend/          # Rails API application
  frontend/         # React + Vite SPA
  docker-compose.yml
  .github/workflows/
```

## Development Workflow

### Branch Strategy
- Always fetch and rebase from `main` before creating a new branch
- Branch naming: `<phase>/<short-description>` (e.g., `phase-1/rails-setup`, `phase-2/rest-api`)
- All work happens on feature branches; never commit directly to `main`

### Test-Driven Development (TDD)
- **Write the failing test first**, then implement until it passes
- Run only the relevant test(s) during development, not the full suite
- Run the full test suite before considering a phase complete
- Backend: RSpec (`cd backend && bundle exec rspec spec/path/to/spec.rb`)
- Frontend: Vitest (`cd frontend && npx vitest run src/path/to/test.ts`)

### Pre-Push Verification
- All commits must be tested before pushing
- A pre-push git hook runs the test suite automatically
- Never skip hooks with `--no-verify`

#### Installing the Pre-Push Hook

The project ships a pre-push hook in `.githooks/pre-push`. To activate it, configure
Git to use the `.githooks` directory:

```bash
git config core.hooksPath .githooks
```

This only needs to be done once per clone. The hook runs RSpec (backend) and
Biome + Vitest (frontend) before every push. If either suite fails, the push
is aborted so broken code never reaches the remote.

### Git Discipline
- Fetch latest `main` before starting any new branch:
  ```bash
  git fetch origin
  git checkout -b <branch-name> origin/main
  ```
- Write clear, descriptive commit messages
- Keep commits focused and atomic

## Tech Stack Quick Reference

### Backend
- **Ruby** 4.0 / **Rails** 8.1 (API mode)
- **PostgreSQL** for database
- **Redis** for caching and Sidekiq
- **RSpec** for testing
- **Sidekiq** for background jobs
- **Shoryuken** for SQS-backed jobs
- **ElasticMQ** for local SQS emulation
- **rswag** for OpenAPI spec generation
- **graphql-ruby** for GraphQL API

### Frontend
- **Node.js** 24 LTS / **npm**
- **React** 19.2 + **TypeScript**
- **Vite** 8 (build tool)
- **Biome.js** 2.x (linting/formatting)
- **Mantine** 8.3 (UI components)
- **Zustand** 5 (state management)
- **TanStack Router** 1.x (routing)
- **Axios** (HTTP client)
- **Zod** (schema validation)
- **es-toolkit** (utilities)
- **Vitest** (testing)

## Common Commands

### Local Development
```bash
# Start all services
docker compose up

# Start specific service
docker compose up backend frontend

# Run backend tests
docker compose exec backend bundle exec rspec

# Run frontend tests
docker compose exec frontend npx vitest run

# Run a specific backend test
docker compose exec backend bundle exec rspec spec/requests/health_spec.rb

# Run frontend linting
docker compose exec frontend npx biome check .

# Rails console
docker compose exec backend bin/rails console

# Database operations
docker compose exec backend bin/rails db:migrate
docker compose exec backend bin/rails db:seed
```

### CI
- CI runs automatically on push/PR to `main`
- Backend tests use a PostgreSQL service container
- Frontend runs Biome check + Vitest

## API Routes

- REST API: `/api/v1/...`
- GraphQL: `/api/graphql`
- OpenAPI spec: `/api/docs.json`
- Scalar UI: `/api/docs`
- Health check: `/api/health`
- Sidekiq Web: `/admin/sidekiq`

## Code Style

### Backend
- Follow Rails conventions
- Use `frozen_string_literal: true` in all Ruby files
- Prefer service objects for business logic
- Keep controllers thin

### Frontend
- Biome.js handles formatting and linting; run `npx biome check --write .` to auto-fix
- Use functional components with hooks
- Colocate tests next to source files (`Component.tsx` / `Component.test.tsx`)
- Use Zod schemas to validate all API responses

## Docker Services

| Service | Port | Description |
|---------|------|-------------|
| backend | 3000 | Rails API server |
| frontend | 5173 | Vite dev server |
| postgres | 5432 | PostgreSQL database |
| redis | 6379 | Redis (Sidekiq, ActionCable) |
| elasticmq | 9324 | Local SQS emulator |

## Implementation Order

Follow the phases in [PRD.md](PRD.md) sequentially:
1. **Phase 1** - Project foundation (Rails, React, Docker, CI)
2. **Phase 2** - Data model, REST API, OpenAPI/Scalar
3. **Phase 3** - GraphQL API
4. **Phase 4** - Background jobs (Sidekiq, Shoryuken)
5. **Phase 5** - Real-time (WebSocket/SSE)
6. **Phase 6** - Authentication (OIDC)
7. **Phase 7** - Frontend features

Each phase should have passing tests and CI green before moving to the next.
