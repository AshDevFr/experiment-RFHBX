# Mordor's Edge

> *"One does not simply walk into Mordor… but you can `docker compose up`.*"

Mordor's Edge is a Lord of the Rings–themed demo application built for **deployment testing and disaster recovery training**. It simulates the War of the Ring as a live system: fellowships quest through Middle-earth, the Eye of Sauron monitors threat levels in real time, and background workers drive the simulation forward — all while the infrastructure stays deliberately fragile so you can practice breaking and recovering it.

The entire application — all seven phases — was **built by a team of AI agents** using the [HiveLabs](https://4sh.dev/posts/2026/building-hivelabs/) multi-agent platform. Phases 1–7 shipped in 5 days (2026-03-17 to 2026-03-21).

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Rails 8.1 (API mode) |
| Database | PostgreSQL 16 |
| Cache / Queues | Redis 7 |
| Background Jobs | Sidekiq + Shoryuken (SQS via ElasticMQ) |
| Real-time | ActionCable (WebSocket) |
| Authentication | OIDC / JWT (configurable; dev bypass available) |
| Frontend | React 19 + TypeScript + Vite |
| UI Components | Mantine |
| Routing | TanStack Router |
| API Docs | OpenAPI 3.1 via Rswag + Scalar UI |
| GraphQL | graphql-ruby 2.5 + GraphiQL playground |
| Local infra | Docker Compose |
| CI | GitHub Actions |

---

## Features

- **Fellowship Tracker** — create and manage fellowships on their quest through Middle-earth
- **Quest Dashboard** — real-time quest progress driven by background jobs
- **Threat Monitor (Eye of Sauron)** — live threat-level feed via ActionCable
- **Palantir Queue** — SQS-based event pipeline (ElasticMQ locally, real SQS in production)
- **REST API** — full CRUD with OpenAPI docs and Scalar UI at `/api/docs`
- **GraphQL API** — full query/mutation API with GraphiQL playground at `/graphiql`
- **OIDC Authentication** — JWT-based auth with configurable provider; dev bypass for local work

---

## Local Development

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/)
- Git

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/AshDevFr/experiment-RFHBX.git
cd experiment-RFHBX

# 2. Create your .env file
cp .env.example .env

# 3. (Optional) Enable dev auth bypass to skip OIDC in development
# Edit .env and set:
#   DEV_AUTH_BYPASS=true

# 4. Start all services
docker compose up
```

This starts:
- **postgres** on port `5432`
- **redis** on port `6379`
- **elasticmq** (local SQS) on port `9324`, management UI on `9325`
- **backend** (Rails API) on port `3000`
- **sidekiq** (background job worker)
- **frontend** (React/Vite) on port `5173`

To also run the Shoryuken SQS consumer:

```bash
docker compose up shoryuken
```

### Seed Data

```bash
docker compose exec backend rails db:seed
```

This populates the database with LOTR-canon fellowships, characters, and quest data.

### Environment Variables

See [`.env.example`](.env.example) for all available configuration options.

Key variables:

| Variable | Default | Description |
|---|---|---|
| `DATABASE_USER` | `postgres` | PostgreSQL username |
| `DATABASE_PASSWORD` | `password` | PostgreSQL password |
| `REDIS_URL` | `redis://redis:6379/0` | Redis connection URL |
| `DEV_AUTH_BYPASS` | `false` | Set `true` to skip OIDC in development |
| `OIDC_ISSUER_URL` | *(empty)* | OIDC provider URL (Keycloak, Auth0, Dex, etc.) |
| `OIDC_CLIENT_ID` | *(empty)* | OIDC client ID |
| `OIDC_AUDIENCE` | *(empty)* | Expected JWT audience |

---

## API Documentation

Once the backend is running:

- **REST API (Scalar UI):** http://localhost:3000/api/docs
- **GraphQL Playground (GraphiQL):** http://localhost:3000/graphiql

---

## E2E Test Report

The latest Playwright E2E test report from the `main` branch is automatically published to GitHub Pages after each successful CI run:

- **Latest Report:** https://AshDevFr.github.io/experiment-RFHBX/

---

## Built by AI Agents

Mordor's Edge was entirely designed and built by the **HiveLabs** multi-agent team — a coordinated crew of specialised AI agents that plan, implement, review, and ship software collaboratively.

Read the full story: [Building HiveLabs: A Multi-Agent Software Team](https://4sh.dev/posts/2026/building-hivelabs/)

### The Team

| Agent | Role |
|---|---|
| **Lead** | Chief of staff — routes requests, manages the user relationship, orchestrates the team |
| **PM** | Senior product manager — refines feature requests into structured stories and tracks project status |
| **Tech Lead** | Technical lead — triages dev requests and routes to the right developer based on complexity |
| **Senior Developer** | Senior engineer — handles complex, architectural, and escalated implementation work |
| **Developer** | Software engineer — implements features, bug fixes, tests, and PRs from a fork |
| **Reviewer** | Senior engineer — reviews PRs for correctness, quality, and security; merges approved PRs |
| **Designer** | UI/UX designer — creates interface designs and reviews implementations for design quality |
| **Lorekeeper** | Knowledge curator — maintains the shared team knowledge base and keeps memories current |

### How It Works

The HiveLabs platform gives each agent **scoped capabilities** — a developer can open PRs but never merge them; a reviewer can merge but not write to `main` directly. Agents coordinate through a **shared ledger** (append-only structured log), and every action is written to an **audit trail** so the full decision history is inspectable.

The Lead orchestrates the team: it receives requests, delegates to the right sub-agent, tracks progress through the ledger, and reports back. Sub-agents work autonomously on their assigned task and request follow-up actions (like "reviewer, please merge PR #N") when they're done.

---

## Project Structure

```
experiment-RFHBX/
├── backend/          # Rails 8.1 API application
├── frontend/         # React 19 + TypeScript + Vite application
├── docker-compose.yml          # Local development stack
├── docker-compose.deploy.yml   # Production deployment stack
├── elasticmq.conf              # ElasticMQ queue configuration
└── .env.example                # Environment variable reference
```

---

## License

This project is a demonstration application. See the repository for license details.
