# Progress: go-backend

Update this file whenever a milestone item changes state. Evidence = command output, test name or commit.

| Milestone | Status | Date |
|---|---|---|
| M0 Template | ✅ Done | 2026-10-30 |
| M1 Diagnosis sync | ⏳ Not started | |
| M2 Model releases | ⏳ Not started | |
| M3 Advice proxy | ⏳ Not started | |
| M4 Hardening | ⏳ Not started | |
| M5 Integration and docs | ⏳ Not started | |

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
- Captured times in the future (beyond 5 minutes of skew) are rejected with 422; phones with wrong clocks will hit this. Revisit in M1 if it shows up.

## Next: M1 Diagnosis sync
- [ ] `POST /api/v1/diagnoses:sync` (≤ 500 items, per-item result)
- [ ] `GET /api/v1/devices/{device_id}/diagnoses` with cursor pagination
- [ ] Integration test: same batch twice → all `duplicate`, no new rows
