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

## Endpoints

Go is the app's **single entry point**: it proxies predictions to `python-ml-service` and
advice to `rag-service`, and serves the `.tflite` model itself.

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/health` | none | Liveness |
| GET | `/ready` | none | `{"database","ml_service","rag_service"}` booleans; 503 only when the DB is down |
| POST | `/api/v1/diagnoses` | `X-API-Key` | Record one diagnosis: **201** new, **200** already synced (idempotent) |
| POST | `/api/v1/diagnoses:sync` | `X-API-Key` | Up to 500 diagnoses; per-item `created` / `duplicate` / `invalid` |
| GET | `/api/v1/diagnoses/{id}` | `X-API-Key` | Fetch one diagnosis |
| GET | `/api/v1/devices/{device_id}/diagnoses?limit=&cursor=` | `X-API-Key` | History, newest first, `next_cursor` |
| GET | `/api/v1/model-releases/latest` | `X-API-Key` | Current model metadata; `ETag` = sha256, 304 on `If-None-Match` |
| GET | `/api/v1/model-releases/{version}/artifact` | `X-API-Key` | The `.tflite` file (Range/resume supported, `X-Checksum-Sha256`) |
| POST | `/api/v1/predictions` | `X-API-Key` | Multipart `file` → ML service (online fallback) |
| POST | `/api/v1/advice` | `X-API-Key` | `{question, class_name}` → RAG service; answer with sources |
| POST | `/api/v1/model-releases` | admin key | Publish a version whose file is in `MODELS_DIR` |
| DELETE | `/api/v1/model-releases/{version}` | admin key | Withdraw; "latest" falls back to the previous one |

On startup every `crop_disease_<v>.tflite` + `.json` pair in `MODELS_DIR` (written by
`ml-training/scripts/export_tflite.py`) is published if not already. sha256 and size are always
computed from the file; a file replaced after publishing is refused (409 `artifact_checksum_mismatch`):
publish a new version instead.

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
the offline app relies on. `captured_at` must not be more than 24 h in the future (phones with wrong clocks).

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
| `ADMIN_API_KEYS` | (empty) | keys for publish/withdraw; empty disables those routes |
| `MODELS_DIR` | `models` | folder with `crop_disease_<v>.tflite` + `.json` |
| `ML_SERVICE_URL` | `http://localhost:8000` | python-ml-service |
| `RAG_SERVICE_URL` | `http://localhost:8001` | rag-service |
| `PREDICT_TIMEOUT` | `10s` | upstream timeout for predictions |
| `ADVICE_TIMEOUT` | `60s` | upstream timeout for advice (a cold local LLM is slow) |

See `.env.example`.

## Use from a phone

Run everything with `docker compose up -d --build` from the repo root, then point the app at:

| Where the app runs | Base URL |
|---|---|
| Android emulator | `http://10.0.2.2:8080` |
| iOS simulator | `http://localhost:8080` |
| Real phone (same Wi-Fi) | `http://<laptop LAN IP>:8080` (`ipconfig getifaddr en0`); allow incoming connections in the macOS firewall |

Plain HTTP is blocked by default on phones: Android needs `android:usesCleartextTraffic="true"`
(or a network security config for the LAN IP) and iOS needs an ATS exception
(`NSAllowsLocalNetworking`). Local demo only; use HTTPS anywhere else.

## Tests

| Command | What | Needs |
|---|---|---|
| `make test` | domain, application, HTTP and architecture tests | nothing |
| `make test-integration` | + PostgreSQL repository tests, in a separate `crop_test` database (they TRUNCATE) | `make db-up` |
| `make lint` | `go vet` + staticcheck | nothing |

## Adding a feature
Follow the checklist in [`AGENTS.md`](AGENTS.md#adding-a-use-case-end-to-end-checklist):
domain → application → infrastructure → interfaces → wire in `main.go` → update `docs/PROGRESS.md`.
