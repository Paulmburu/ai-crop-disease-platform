# Run from go-backend/. `make help` lists targets.
DATABASE_URL ?= postgres://crop:crop@localhost:5433/crop?sslmode=disable
API_KEYS ?= dev-key
export DATABASE_URL API_KEYS

.PHONY: help run test test-integration lint db-up db-down docker build

help:            ## list targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/\t/'

run:             ## run the API locally (needs `make db-up`)
	go run ./cmd/api

build:           ## build the binary into bin/
	CGO_ENABLED=0 go build -o bin/api ./cmd/api

test:            ## unit tests (no database needed)
	go test ./...

test-integration: ## repository tests against a separate crop_test database (they TRUNCATE tables)
	docker compose -f ../docker-compose.yml exec -T postgres sh -c \
		'psql -U crop -d crop -tc "SELECT 1 FROM pg_database WHERE datname = '"'"'crop_test'"'"'" | grep -q 1 || createdb -U crop crop_test'
	TEST_DATABASE_URL=postgres://crop:crop@localhost:5433/crop_test?sslmode=disable go test -tags integration -count=1 ./...

lint:            ## go vet + staticcheck
	go vet ./...
	go run honnef.co/go/tools/cmd/staticcheck@latest ./...

db-up:           ## start PostgreSQL from the root docker-compose.yml
	docker compose -f ../docker-compose.yml up -d --wait postgres

db-down:         ## stop PostgreSQL
	docker compose -f ../docker-compose.yml stop postgres

docker:          ## build and start go-backend + postgres in Docker
	docker compose -f ../docker-compose.yml up -d --build --wait postgres go-backend
