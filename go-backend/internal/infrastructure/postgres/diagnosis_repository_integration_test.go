//go:build integration

// Run with: make db-up && make test-integration
package postgres_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/diagnosis"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/infrastructure/postgres"
)

func TestDiagnosisRepository(t *testing.T) {
	url := os.Getenv("DATABASE_URL")
	if url == "" {
		t.Skip("DATABASE_URL not set")
	}
	ctx := context.Background()
	pool, err := postgres.Connect(ctx, url)
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	if err := postgres.Migrate(ctx, pool); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Exec(ctx, "TRUNCATE diagnoses"); err != nil {
		t.Fatal(err)
	}
	repo := postgres.NewDiagnosisRepository(pool)

	now := time.Now().UTC().Truncate(time.Microsecond) // Postgres stores microseconds
	d, err := diagnosis.NewDiagnosis(diagnosis.NewInput{
		ID: "6f1c2b9e-3d4a-4f5b-9c8d-7e6f5a4b3c2d", DeviceID: "device-1", ClassLabel: "Potato___Late_blight",
		Confidence: 0.93, ConfidenceThreshold: 0.5, ModelVersion: "v1", CapturedAt: now.Add(-time.Hour),
	}, now)
	if err != nil {
		t.Fatal(err)
	}

	created, err := repo.Save(ctx, d)
	if err != nil || !created {
		t.Fatalf("first save: created=%v err=%v", created, err)
	}
	created, err = repo.Save(ctx, d)
	if err != nil || created {
		t.Fatalf("second save must be a no-op: created=%v err=%v", created, err)
	}

	got, err := repo.FindByID(ctx, d.ID())
	if err != nil {
		t.Fatal(err)
	}
	if got.ClassLabel() != d.ClassLabel() || got.Confidence() != d.Confidence() ||
		!got.CapturedAt().Equal(d.CapturedAt()) || got.Status() != diagnosis.StatusOK {
		t.Fatalf("round trip mismatch: %+v", got)
	}

	_, err = repo.FindByID(ctx, "00000000-0000-0000-0000-000000000000")
	if de, ok := shared.As(err); !ok || de.Kind != shared.KindNotFound {
		t.Fatalf("want not found, got %v", err)
	}
}
