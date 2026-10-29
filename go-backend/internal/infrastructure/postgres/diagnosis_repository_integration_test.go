//go:build integration

// Run with: make db-up && make test-integration
package postgres_test

import (
	"context"
	"fmt"
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

func TestSaveManyAndPagination(t *testing.T) {
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
	now := time.Now().UTC().Truncate(time.Microsecond)

	var ds []*diagnosis.Diagnosis
	for i := 1; i <= 250; i++ {
		d, err := diagnosis.NewDiagnosis(diagnosis.NewInput{
			ID: fmt.Sprintf("00000000-0000-4000-8000-%012d", i), DeviceID: "device-p", ClassLabel: "Potato___healthy",
			Confidence: 0.9, ConfidenceThreshold: 0.5, ModelVersion: "v1",
			CapturedAt: now.Add(-time.Duration(i%13) * time.Minute), // repeated timestamps: tie-break on id
		}, now)
		if err != nil {
			t.Fatal(err)
		}
		ds = append(ds, d)
	}
	created, err := repo.SaveMany(ctx, ds)
	if err != nil || len(created) != 250 {
		t.Fatalf("first SaveMany: %d created, err %v", len(created), err)
	}
	created, err = repo.SaveMany(ctx, ds)
	if err != nil || len(created) != 0 {
		t.Fatalf("second SaveMany must create nothing: %d, err %v", len(created), err)
	}

	seen := map[string]bool{}
	var cursor *diagnosis.Cursor
	for {
		page, err := repo.ListByDevice(ctx, "device-p", cursor, 40)
		if err != nil {
			t.Fatal(err)
		}
		for _, d := range page {
			if seen[d.ID()] {
				t.Fatalf("repeated %s", d.ID())
			}
			seen[d.ID()] = true
		}
		if len(page) < 40 {
			break
		}
		c := diagnosis.CursorOf(page[len(page)-1])
		cursor = &c
	}
	if len(seen) != 250 {
		t.Fatalf("walked %d of 250", len(seen))
	}
}
