# AGENTS.md: working on go-backend

Instructions for AI coding agents and human contributors. Read this before changing code.
Product context: `docs/PRD.md`. Plan: `docs/ROADMAP.md`. Status: `docs/PROGRESS.md`.

## Architecture: the dependency rule

```
interfaces/http  ─►  application  ─►  domain   ◄─ (implements ports) ─  infrastructure
cmd/api/main.go wires concrete types together (composition root)
```

| Layer | Path | May import | Must NOT import |
|---|---|---|---|
| Domain | `internal/domain/...` | stdlib only (`errors`, `time`, `strings`, …) | anything in `internal/` outside domain, `net/http`, `database/sql`, pgx, chi |
| Application | `internal/application/...` | domain, stdlib `context` | infrastructure, interfaces, pgx, chi, `net/http` |
| Infrastructure | `internal/infrastructure/...` | domain, application ports, pgx, goose, … | interfaces |
| Interfaces | `internal/interfaces/http/...` | application, domain (types/errors), chi | infrastructure |
| Composition | `cmd/api` | everything | (only place allowed to) |

`internal/architecture_test.go` enforces the domain and application rules. Do not weaken it.

## Where code goes

| You are adding… | Put it in |
|---|---|
| A business rule / validation | the aggregate or value object in `internal/domain/<context>/` |
| A use case ("record diagnosis", "publish release") | `internal/application/<context>/` as a struct with an `Execute`-style method |
| An interface the use case needs (repo, clock, upstream) | domain (repositories) or application (other ports) |
| SQL, HTTP clients, env parsing | `internal/infrastructure/` |
| Routes, request/response JSON, status codes | `internal/interfaces/http/` |
| A schema change | new file in `migrations/` (`NNNN_description.sql`, goose format) — never edit an applied one |

## Adding a use case end to end (checklist)
1. Domain: entity/value objects + constructor enforcing invariants + table-driven tests.
2. Repository interface in the domain package (only the methods the use case needs).
3. Application: use case with dependencies passed as interfaces; tests with an in-memory fake.
4. Infrastructure: Postgres implementation + migration + `//go:build integration` test.
5. Interfaces: handler + DTOs + route; `httptest` tests for success and every error status.
6. Wire it in `cmd/api/main.go`.
7. Update `docs/PROGRESS.md` (and `PRD.md` if behaviour changed).

## Conventions
- **Errors:** domain returns `shared.Error` kinds (`KindInvalid`, `KindNotFound`, `KindConflict`).
  Only `interfaces/http/errors.go` maps kinds to HTTP status. Never return HTTP codes from below that layer.
- **Error JSON:** always `{"error": "<code>", "detail": "...", "request_id": "..."}`; same as the Python services.
- **Context:** every repository and use-case method takes `ctx context.Context` first.
- **Time:** never call `time.Now()` in domain/application; inject a `Clock`.
- **IDs:** diagnosis ids are client-generated UUIDs (idempotency). Validate format in the domain.
- **Logging:** `log/slog` only, injected; include `request_id`. No `fmt.Println`, no global loggers.
- **Config:** environment variables only, parsed once in `infrastructure/config`, validated at startup.
- **Dependencies:** prefer stdlib. Adding a module needs a reason in the PR description.
- **Naming:** packages are singular nouns (`diagnosis`, `postgres`); no `utils`, `common`, `helpers`.

## Tests
| Kind | Command | Needs |
|---|---|---|
| Unit (domain, application, http) | `make test` | nothing |
| Integration (repositories) | `make db-up && make test-integration` | Docker |
| Lint | `make lint` | nothing (runs `go vet` + staticcheck via `go run`) |

Rules: table-driven tests; no sleeps; no real network in unit tests (`httptest`); every bug fix
gets a regression test.

## Do / don't
- ✅ Keep handlers thin: decode → call use case → encode.
- ✅ Make re-sending the same request safe (idempotency) for anything the phone syncs.
- ❌ Don't put SQL or HTTP types in domain/application.
- ❌ Don't add an ORM, DI container, or web framework beyond chi.
- ❌ Don't log secrets or full request bodies.
- ❌ Don't commit `.env`.

## Definition of done
Tests and lint pass · architecture test passes · docs updated (`PROGRESS.md` always) ·
new endpoints listed in `README.md`.
