package diagnosis_test

import (
	"context"
	"testing"
	"time"

	app "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/diagnosis"
	domain "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/diagnosis"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

type fixedClock struct{ t time.Time }

func (c fixedClock) Now() time.Time { return c.t }

var now = time.Date(2026, 10, 30, 12, 0, 0, 0, time.UTC)

func input() domain.NewInput {
	return domain.NewInput{
		ID: "6f1c2b9e-3d4a-4f5b-9c8d-7e6f5a4b3c2d", DeviceID: "device-1",
		ClassLabel: "Potato___Late_blight", Confidence: 0.93, ConfidenceThreshold: 0.5,
		ModelVersion: "v1", CapturedAt: now.Add(-time.Hour),
	}
}

func TestRecordIsIdempotent(t *testing.T) {
	repo := app.NewMemoryRepository()
	svc := app.NewService(repo, fixedClock{now})
	ctx := context.Background()

	first, err := svc.Record(ctx, input())
	if err != nil || !first.Created {
		t.Fatalf("first record: created=%v err=%v", first.Created, err)
	}
	// The phone retries the same sync with slightly different data: the stored record wins.
	again := input()
	again.Confidence = 0.1
	second, err := svc.Record(ctx, again)
	if err != nil || second.Created {
		t.Fatalf("second record: created=%v err=%v", second.Created, err)
	}
	if repo.Len() != 1 || second.Diagnosis.Confidence() != 0.93 {
		t.Fatalf("want 1 stored record with original confidence, got %d / %v", repo.Len(), second.Diagnosis.Confidence())
	}
}

func TestRecordRejectsInvalidInputWithoutSaving(t *testing.T) {
	repo := app.NewMemoryRepository()
	in := input()
	in.Confidence = 3
	_, err := app.NewService(repo, fixedClock{now}).Record(context.Background(), in)
	if de, ok := shared.As(err); !ok || de.Kind != shared.KindInvalid {
		t.Fatalf("want invalid error, got %v", err)
	}
	if repo.Len() != 0 {
		t.Fatal("invalid diagnosis must not be stored")
	}
}

func TestGetUnknownIsNotFound(t *testing.T) {
	_, err := app.NewService(app.NewMemoryRepository(), fixedClock{now}).Get(context.Background(), "nope")
	if de, ok := shared.As(err); !ok || de.Kind != shared.KindNotFound {
		t.Fatalf("want not found, got %v", err)
	}
}
