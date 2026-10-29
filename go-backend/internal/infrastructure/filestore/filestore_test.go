package filestore_test

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"os"
	"path/filepath"
	"testing"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/infrastructure/filestore"
)

func TestDescribeOpenAndDiscover(t *testing.T) {
	dir := t.TempDir()
	content := []byte("fake tflite bytes")
	must(t, os.WriteFile(filepath.Join(dir, "crop_disease_v1.tflite"), content, 0o644))
	must(t, os.WriteFile(filepath.Join(dir, "crop_disease_v1.json"),
		[]byte(`{"model_version":"v1","input_shape":[1,224,224,3],"class_names":["a","b","c"],"confidence_threshold":0.5}`), 0o644))
	must(t, os.WriteFile(filepath.Join(dir, "crop_disease_v2.json"), []byte(`{}`), 0o644)) // no .tflite: skipped

	s := filestore.New(dir)
	sum, size, err := s.Describe(context.Background(), "v1")
	want := sha256.Sum256(content)
	if err != nil || sum != hex.EncodeToString(want[:]) || size != int64(len(content)) {
		t.Fatalf("describe: %s %d %v", sum, size, err)
	}
	a, err := s.Open(context.Background(), "v1")
	if err != nil {
		t.Fatal(err)
	}
	got, _ := io.ReadAll(a.Content)
	_ = a.Content.Close()
	if string(got) != string(content) {
		t.Fatal("content mismatch")
	}

	found, err := s.Discover()
	if err != nil || len(found) != 1 || found[0].Version != "v1" || len(found[0].ClassLabels) != 3 {
		t.Fatalf("discover: %+v %v", found, err)
	}
}

func TestRejectsUnsafeAndMissingVersions(t *testing.T) {
	s := filestore.New(t.TempDir())
	if _, _, err := s.Describe(context.Background(), "../../etc/passwd"); err == nil {
		t.Fatal("path traversal must be rejected")
	}
	_, _, err := s.Describe(context.Background(), "v9")
	if de, ok := shared.As(err); !ok || de.Kind != shared.KindNotFound {
		t.Fatalf("want not found, got %v", err)
	}
}

func must(t *testing.T, err error) {
	t.Helper()
	if err != nil {
		t.Fatal(err)
	}
}
