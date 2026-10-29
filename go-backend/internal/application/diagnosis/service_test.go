package diagnosis_test

import (
	"context"
	"fmt"
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

func item(id string, minutesAgo int) domain.NewInput {
	in := input()
	in.ID = id
	in.CapturedAt = now.Add(-time.Duration(minutesAgo) * time.Minute)
	return in
}

func uuid(n int) string { return fmt.Sprintf("00000000-0000-4000-8000-%012d", n) }

func TestSyncReportsEachItemAndIsIdempotent(t *testing.T) {
	repo := app.NewMemoryRepository()
	svc := app.NewService(repo, fixedClock{now})
	bad := item(uuid(3), 1)
	bad.Confidence = 7
	batch := []domain.NewInput{item(uuid(1), 1), item(uuid(2), 2), bad, item(uuid(1), 1)}

	res, err := svc.Sync(context.Background(), batch)
	if err != nil {
		t.Fatal(err)
	}
	want := []app.Outcome{app.OutcomeCreated, app.OutcomeCreated, app.OutcomeInvalid, app.OutcomeDuplicate}
	for i, r := range res {
		if r.Outcome != want[i] {
			t.Errorf("item %d: want %s, got %s", i, want[i], r.Outcome)
		}
	}
	if res[2].Error == nil || res[2].Error.Code != "invalid_confidence" {
		t.Errorf("invalid item must carry its error, got %+v", res[2].Error)
	}

	again, _ := svc.Sync(context.Background(), batch)
	for i, r := range again {
		if i != 2 && r.Outcome != app.OutcomeDuplicate {
			t.Errorf("resync item %d: want duplicate, got %s", i, r.Outcome)
		}
	}
	if repo.Len() != 2 {
		t.Fatalf("want 2 stored, got %d", repo.Len())
	}
}

func TestSyncBatchLimits(t *testing.T) {
	svc := app.NewService(app.NewMemoryRepository(), fixedClock{now})
	if _, err := svc.Sync(context.Background(), nil); err == nil {
		t.Error("empty batch must be rejected")
	}
	big := make([]domain.NewInput, app.MaxSyncBatch+1)
	if _, err := svc.Sync(context.Background(), big); err == nil {
		t.Error("oversized batch must be rejected")
	}
}

func TestListPagesNewestFirstWithoutGapsOrRepeats(t *testing.T) {
	repo := app.NewMemoryRepository()
	svc := app.NewService(repo, fixedClock{now})
	var batch []domain.NewInput
	for i := 1; i <= 25; i++ {
		batch = append(batch, item(uuid(i), i%7)) // repeated timestamps exercise the id tie-break
	}
	if _, err := svc.Sync(context.Background(), batch); err != nil {
		t.Fatal(err)
	}
	seen := map[string]bool{}
	var cursor *domain.Cursor
	var last time.Time
	for pages := 0; ; pages++ {
		page, err := svc.List(context.Background(), "device-1", cursor, 10)
		if err != nil {
			t.Fatal(err)
		}
		for _, d := range page.Items {
			if seen[d.ID()] {
				t.Fatalf("repeated %s", d.ID())
			}
			if !last.IsZero() && d.CapturedAt().After(last) {
				t.Fatal("not newest first")
			}
			seen[d.ID()], last = true, d.CapturedAt()
		}
		if page.Next == nil {
			break
		}
		cursor = page.Next
	}
	if len(seen) != 25 {
		t.Fatalf("want 25, got %d", len(seen))
	}
}
