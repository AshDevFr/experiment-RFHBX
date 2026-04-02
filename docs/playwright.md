# Playwright E2E Smoke Tests

End-to-end smoke tests for Mordor's Edge using [Playwright](https://playwright.dev/).

## Prerequisites

- **Docker** and **Docker Compose** (v2+) for the containerised workflow
- **Node.js 18+** if running Playwright locally outside Docker

## Running Tests

### Docker Compose (recommended)

This is the same approach used in CI. It spins up the full stack (Postgres, Redis, ElasticMQ, backend, Sidekiq, frontend) and runs Playwright inside a container.

```bash
docker compose -f docker-compose.e2e.yml up --build --abort-on-container-exit
```

Tear down afterwards:

```bash
docker compose -f docker-compose.e2e.yml down -v
```

### Local (standalone)

If you already have the backend and frontend running locally:

```bash
cd e2e
npm install
npx playwright install --with-deps chromium
npx playwright test
```

Or use the npm script shorthand:

```bash
cd e2e
npm run test:e2e
```

To run tests in headed mode (browser visible):

```bash
cd e2e
npm run test:e2e:headed
```

## Viewing Test Reports

After a test run, Playwright generates an HTML report.

### Local

```bash
cd e2e
npm run test:e2e:report
```

This opens the report in your default browser.

### CI

When tests fail in CI, the HTML report is uploaded as a GitHub Actions artifact named `playwright-report` (retained for 14 days). Download it from the workflow run's **Artifacts** section, then open `index.html` in a browser.

## Environment Variables

| Variable | Used by | Default | Description |
|---|---|---|---|
| `BASE_URL` | Playwright config | `http://localhost:5173` | Frontend URL that Playwright navigates to. Overridden to `http://frontend:5173` inside Docker Compose. |
| `API_BASE_URL` | `health.spec.ts`, `wait-for-services.sh` | `http://localhost:3000` | Backend API URL used for the health-check test and the service-readiness script. Overridden to `http://backend:3000` inside Docker Compose. |
| `CI` | Playwright config | _(unset)_ | When truthy, enables `forbidOnly`, sets 2 retries, and uses non-interactive HTML reporter. Set automatically in GitHub Actions and in the Docker Compose `playwright` service. |
| `DEV_AUTH_BYPASS` | Backend + Frontend | `"false"` | Enables the dev-login bypass button so E2E tests can authenticate without a real OIDC provider. Set to `"true"` in `docker-compose.e2e.yml` for both `backend` and `frontend` services. **Never enable in production.** |
| `VITE_DEV_AUTH_BYPASS` | Frontend (Vite) | `"false"` | Frontend-side equivalent of `DEV_AUTH_BYPASS`. Controls visibility of the dev-login button in the React app. Set to `"true"` in `docker-compose.e2e.yml`. |
| `VITE_API_BASE_URL` | Frontend (Vite) | — | Tells the frontend where to find the backend API. Set to `http://backend:3000` in Docker Compose so the frontend container can reach the backend via Docker DNS. |

## Project Structure

```
e2e/
  Dockerfile              # Playwright container image (pinned v1.50.0)
  package.json            # E2E dependencies and npm scripts
  playwright.config.ts    # Playwright configuration
  wait-for-services.sh    # Entrypoint script — waits for backend + frontend before running tests
  fixtures/
    auth.fixture.ts       # Custom fixture for dev-bypass authentication
  pages/
    base.page.ts          # Base page object with shared helpers
    home.page.ts          # Home page POM
    login.page.ts         # Login page POM (dev-login flow)
    fellowship.page.ts    # Characters list POM
    quests.page.ts        # Quests list POM
  tests/
    health.spec.ts        # API health-check smoke test
    home.spec.ts          # Home page render + JS error check
    fellowship.spec.ts    # Characters list (requires auth)
    quests.spec.ts        # Quests list (requires auth)
```

## CI Workflow

The E2E tests run via `.github/workflows/e2e.yml` on every push to `main` and on pull requests targeting `main`. The workflow:

1. Builds all Docker images
2. Starts infrastructure (Postgres, Redis, ElasticMQ) and waits for health checks
3. Starts application services (backend, Sidekiq, frontend)
4. Runs Playwright tests inside the `playwright` container
5. Uploads the HTML report as an artifact on failure
6. Tears down all containers
