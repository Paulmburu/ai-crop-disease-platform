package modelrelease_test

import (
	"context"
	"io"
	"strings"
	"testing"
	"time"

	app "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/modelrelease"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

type clock struct{}

func (clock) Now() time.Time { return time.Date(2026, 10, 30, 12, 0, 0, 0, time.UTC) }

// fakeStore pretends every version except "missing" has a file.
type fakeStore struct{}

func (fakeStore) Describe(_ context.Context, v string) (string, int64, error) {
	if v == "missing" {
		return "", 0, shared.NotFound("artifact_not_found", "no file")
	}
	return strings.Repeat("b", 64), 1234, nil
}

type nopFile struct{ *strings.Reader }

func (nopFile) Close() error { return nil }

// Open serves a different file for "swapped", as if it was overwritten after publishing.
func (f fakeStore) Open(ctx context.Context, v string) (app.Artifact, error) {
	sum, size, err := f.Describe(ctx, v)
	if v == "swapped" {
		sum = strings.Repeat("d", 64)
	}
	return app.Artifact{Content: nopFile{strings.NewReader("tflite")}, SizeBytes: size, Sha256: sum}, err
}

var _ io.ReadSeekCloser = nopFile{}

func in(v string) app.PublishInput {
	return app.PublishInput{Version: v, ClassLabels: []string{"a", "b"}, ConfidenceThreshold: 0.5, InputShape: []int{1, 224, 224, 3}}
}

func TestPublishLatestWithdraw(t *testing.T) {
	ctx := context.Background()
	svc := app.NewService(app.NewMemoryRepository(), fakeStore{}, clock{})
	if _, err := svc.Latest(ctx); err == nil {
		t.Fatal("no release yet must be not found")
	}
	r1, err := svc.Publish(ctx, in("v1"))
	if err != nil || r1.Sha256() != strings.Repeat("b", 64) || r1.SizeBytes() != 1234 {
		t.Fatalf("publish v1: %v %+v", err, r1)
	}
	if _, err := svc.Publish(ctx, in("v2")); err != nil {
		t.Fatal(err)
	}
	if l, _ := svc.Latest(ctx); l.Version() != "v2" {
		t.Fatalf("latest should be v2, got %s", l.Version())
	}
	if err := svc.Withdraw(ctx, "v2"); err != nil {
		t.Fatal(err)
	}
	if l, _ := svc.Latest(ctx); l.Version() != "v1" {
		t.Fatalf("after withdrawing v2 latest should be v1, got %s", l.Version())
	}
	if _, _, err := svc.OpenArtifact(ctx, "v2"); err == nil {
		t.Fatal("withdrawn release must not be downloadable")
	}
}

func TestPublishErrors(t *testing.T) {
	ctx := context.Background()
	svc := app.NewService(app.NewMemoryRepository(), fakeStore{}, clock{})
	for _, tt := range []struct {
		version string
		kind    shared.Kind
	}{{"../x", shared.KindInvalid}, {"missing", shared.KindNotFound}} {
		_, err := svc.Publish(ctx, in(tt.version))
		if de, ok := shared.As(err); !ok || de.Kind != tt.kind {
			t.Errorf("%s: want kind %d, got %v", tt.version, tt.kind, err)
		}
	}
	_, _ = svc.Publish(ctx, in("v1"))
	if _, err := svc.Publish(ctx, in("v1")); err == nil {
		t.Error("duplicate version must conflict")
	}
	if created, err := svc.PublishIfAbsent(ctx, in("v1")); err != nil || created {
		t.Errorf("PublishIfAbsent on existing: created=%v err=%v", created, err)
	}
}

func TestOpenArtifactRejectsReplacedFile(t *testing.T) {
	ctx := context.Background()
	svc := app.NewService(app.NewMemoryRepository(), fakeStore{}, clock{})
	for _, v := range []string{"v1", "swapped"} {
		if _, err := svc.Publish(ctx, in(v)); err != nil {
			t.Fatal(err)
		}
	}
	if _, a, err := svc.OpenArtifact(ctx, "v1"); err != nil || a.Content == nil {
		t.Fatalf("v1: %v", err)
	}
	if _, _, err := svc.OpenArtifact(ctx, "swapped"); err == nil || !strings.Contains(err.Error(), "artifact_checksum_mismatch") {
		t.Fatalf("want checksum mismatch, got %v", err)
	}
}
