# go-backend

The platform's Go backend: **diagnosis sync**, **model releases** and **advice** for the
offline-first crop disease app. The phone diagnoses on-device; this service only adds value when
the network is available, and is never on the diagnosis path.

Built with **DDD and a clean layered architecture**: Go 1.26, chi, PostgreSQL (pgx), goose
migrations, `log/slog`.

| Doc | What it covers |
|---|---|
| [`docs/PRD.md`](docs/PRD.md) | Problem, users, bounded contexts, requirements |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Milestones M0–M5 with acceptance criteria |
| [`docs/PROGRESS.md`](docs/PROGRESS.md) | What is done, with evidence |
| [`AGENTS.md`](AGENTS.md) | Rules for contributors and AI agents: layers, conventions, tests |

## Architecture

```mermaid
flowchart LR
    subgraph interfaces["interfaces/http"]
        R["router + middleware<br/>request-id · log · recover · API key"] --> H["handlers + DTOs<br/>(only place with status codes)"]
    end
    subgraph application["application"]
        U["use cases<br/>Record / Get diagnosis"]
    end
    subgraph domain["domain (pure Go)"]
        D["Diagnosis aggregate<br/>invariants · Repository port"]
    end
    subgraph infrastructure["infrastructure"]
        P["postgres repository<br/>+ migrations"]
        C["config · slog logger"]
    end
    H --> U --> D
    P -. implements .-> D
    M["cmd/api/main.go<br/>composition root"] --> R & U & P & C
```

Dependencies point inward only; `internal/architecture_test.go` fails the build if they don't.

```
cmd/api/                 main.go: wiring, graceful shutdown, `api healthcheck`
internal/domain/         shared errors · diagnosis aggregate + Repository interface
internal/application/    diagnosis use cases (+ in-memory repository for tests)
internal/infrastructure/ config · observability (slog) · postgres (pool, migrations, repository)
internal/interfaces/http router · middleware · handlers
migrations/              goose SQL files, embedded in the binary
docs/                    PRD · ROADMAP · PROGRESS
```

## Endpoints (milestone M0)

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/health` | none | Liveness |
| GET | `/ready` | none | 200 when PostgreSQL answers, else 503 |
| POST | `/api/v1/diagnoses` | `X-API-Key` | Record a diagnosis from the phone: **201** new, **200** already synced (idempotent) |
| GET | `/api/v1/diagnoses/{id}` | `X-API-Key` | Fetch one diagnosis |

Errors always look like the Python services':
`{"error": "invalid_confidence", "detail": "...", "request_id": "..."}`.
Send `X-Request-ID` to trace a call; it is echoed back and logged.

## Quick start

```bash
cd go-backend
make db-up                 # PostgreSQL 17 from the root docker-compose.yml (host port 5433)
make run                   # API on :8080, migrates the DB on startup
```

```bash
curl localhost:8080/ready
curl -X POST localhost:8080/api/v1/diagnoses -H 'X-API-Key: dev-key' -H 'Content-Type: application/json' -d '{
  "id": "0b8a1c2d-3e4f-4a5b-8c6d-7e8f9a0b1c2d", "device_id": "device-1",
  "class_label": "Potato___Late_blight", "confidence": 0.93, "confidence_threshold": 0.5,
  "model_version": "v1", "captured_at": "2026-10-29T20:00:00Z"}'
```

Run the same POST again: **200** instead of 201, and still one row. That is the idempotent sync
the offline app relies on. `captured_at` must not be in the future (5-minute clock-skew allowance).

Everything in Docker: `make docker` (22 MB distroless image, health-checked).

## Configuration

| Variable | Default | Notes |
|---|---|---|
| `DATABASE_URL` | (required) | e.g. `postgres://crop:crop@localhost:5433/crop?sslmode=disable` |
| `API_KEYS` | (required) | comma-separated keys accepted in `X-API-Key` |
| `HTTP_ADDR` | `:8080` | |
| `LOG_LEVEL` | `info` | `debug`, `info`, `warn`, `error` |
| `REQUEST_TIMEOUT` | `15s` | per request under `/api/v1` |
| `SHUTDOWN_TIMEOUT` | `10s` | drain time on SIGTERM |
| `MAX_BODY_BYTES` | `1048576` | larger bodies get 413 |

See `.env.example`.

## Tests

| Command | What | Needs |
|---|---|---|
| `make test` | domain, application, HTTP and architecture tests | nothing |
| `make test-integration` | + PostgreSQL repository tests | `make db-up` |
| `make lint` | `go vet` + staticcheck | nothing |

## Adding a feature
Follow the checklist in [`AGENTS.md`](AGENTS.md#adding-a-use-case-end-to-end-checklist):
domain → application → infrastructure → interfaces → wire in `main.go` → update `docs/PROGRESS.md`.
