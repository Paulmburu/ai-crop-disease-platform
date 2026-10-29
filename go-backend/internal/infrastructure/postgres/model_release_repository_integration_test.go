//go:build integration

package postgres_test

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/modelrelease"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/infrastructure/postgres"
)

func TestModelReleaseRepository(t *testing.T) {
	url := os.Getenv("TEST_DATABASE_URL")
	if url == "" {
		t.Skip("TEST_DATABASE_URL not set")
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
	if _, err := pool.Exec(ctx, "TRUNCATE model_releases"); err != nil {
		t.Fatal(err)
	}
	repo := postgres.NewModelReleaseRepository(pool)
	base := time.Now().UTC().Truncate(time.Microsecond)

	for i, v := range []string{"v1", "v2"} {
		r, err := modelrelease.New(modelrelease.Input{
			Version: v, Sha256: strings.Repeat("c", 64), SizeBytes: 10, ClassLabels: []string{"a", "b"},
			ConfidenceThreshold: 0.5, InputShape: []int{1, 224, 224, 3},
		}, base.Add(time.Duration(i)*time.Minute))
		if err != nil {
			t.Fatal(err)
		}
		if err := repo.Save(ctx, r); err != nil {
			t.Fatal(err)
		}
		if err := repo.Save(ctx, r); err == nil {
			t.Fatal("duplicate version must conflict")
		} else if de, ok := shared.As(err); !ok || de.Kind != shared.KindConflict {
			t.Fatalf("want conflict, got %v", err)
		}
	}
	latest, err := repo.Latest(ctx)
	if err != nil || latest.Version() != "v2" || len(latest.InputShape()) != 4 || latest.ClassLabels()[1] != "b" {
		t.Fatalf("latest: %+v %v", latest, err)
	}
	if err := repo.Withdraw(ctx, "v2", base); err != nil {
		t.Fatal(err)
	}
	if latest, _ := repo.Latest(ctx); latest.Version() != "v1" {
		t.Fatalf("after withdraw: %s", latest.Version())
	}
	if r, _ := repo.FindByVersion(ctx, "v2"); !r.Withdrawn() {
		t.Fatal("v2 should be withdrawn")
	}
	if err := repo.Withdraw(ctx, "nope", base); err == nil {
		t.Fatal("withdrawing unknown version must be not found")
	}
}
