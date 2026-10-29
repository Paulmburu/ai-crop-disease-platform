# Progress: go-backend

Update this file whenever a milestone item changes state. Evidence = command output, test name or commit.

| Milestone | Status | Date |
|---|---|---|
| M0 Template | ✅ Done | 2026-10-30 |
| M1 Diagnosis sync | ✅ Done | 2026-10-30 |
| M2 Model releases | ✅ Done | 2026-10-30 |
| M3 Prediction + advice gateway | ✅ Done | 2026-10-30 |
| M4 Hardening | ⏳ Not started | |
| M5 Integration and docs | 🟡 Compose + API contract done; CI pending | |

## M0: Template ✅

| Item | Evidence |
|---|---|
| Layered layout, module `github.com/Paulmburu/ai-crop-disease-platform/go-backend` | `internal/{domain,application,infrastructure,interfaces}` |
| Dependency rule enforced | `internal/architecture_test.go` passes |
| Diagnosis aggregate + invariants (D1, D2) | `internal/domain/diagnosis/diagnosis_test.go`: 9 invariant cases, status rule, health rule |
| Idempotent `Record` use case | `internal/application/diagnosis/service_test.go`: `TestRecordIsIdempotent` |
| PostgreSQL repository + goose migration | `diagnosis_repository_integration_test.go` passes against postgres:17 (`make test-integration`) |
| HTTP: routes, middleware, shared error shape | `internal/interfaces/http/router_test.go`: 401, 400, 413, 422, 404, request-id echo, 201→200 |
| Config, slog JSON logs, graceful shutdown | Shutdown log line `"shutting down","drain":"10s"` seen on `docker compose stop` |
| Lint | `go vet ./...` and staticcheck: clean |
| Docker | 22.2 MB distroless image; compose `postgres` + `go-backend` both `(healthy)` |
| Live check | POST same diagnosis twice → 201 then 200, `select count(*)` = 1; wrong key → 401 with `request_id` |

**Notes and decisions**
- Compose PostgreSQL is published on host port **5433**: a locally installed PostgreSQL already uses 5432.
- `api healthcheck` subcommand exists because the distroless image has no shell or curl.
- Captured times in the future (beyond 5 minutes of skew) were rejected with 422; raised to 24 h in M1.

## M1: Diagnosis sync ✅

| Item | Evidence |
|---|---|
| `POST /api/v1/diagnoses:sync` (≤ 500, per-item outcome) | `router_test.go` `TestSyncAndHistory`; live: 100 items → `created:100`, same batch again → `duplicate:100`, 100 rows |
| History with cursor pagination | `TestSaveManyAndPagination`: 250 rows walked in pages of 40, no gaps or repeats |

## M2: Model releases ✅

| Item | Evidence |
|---|---|
| Aggregate, repository, migration `00002` | domain + application tests; `TestModelReleaseRepository` (integration) |
| Startup seeder from `MODELS_DIR` | live log `model release published from models dir version=v1` |
| Latest + ETag/304, Range download | `TestModelReleaseLifecycle`; live: 304 on `If-None-Match`, Range → 206, downloaded sha256 = `83bb8785…` = file |
| Admin key, withdraw | `TestModelReleaseLifecycle` (app key → 401, withdraw → 404 `release_withdrawn`) |
| Replaced file refused | `TestOpenArtifactRejectsReplacedFile` (409 `artifact_checksum_mismatch`) |

## M3: Prediction + advice gateway ✅

| Item | Evidence |
|---|---|
| Upstream adapters (timeout, 1 retry on dial, request-id, error mapping) | `upstream_test.go` |
| HTTP proxies + `/ready` upstream status | `router_gateway_test.go` `TestProxies` |
| Live | `/ready` all true; PlantVillage late-blight leaf → `Potato___Late_blight` 0.765; `/advice` cited answer (grounded, 7 sources, ~19.5 s); RAG stopped → 503 `advice_unavailable`, `/ready` `rag_service:false` |

**Decisions**
- Integration tests use a separate `crop_test` DB: they TRUNCATE, and once wiped the demo data and blocked the v1 seed.
- PlantDoc field photos often come back `uncertain` (54.8% field accuracy); use PlantVillage-style leaves on stage.

## Next
- M4 hardening (post-talk), CI workflow, rewrite `docs/PHASE_4_GO_BACKEND_GATEWAY.md` from code.
- Upstream 4xx with a list `detail` is flattened to a string; keep the list once the app shows field errors.
