package modelrelease_test

import (
	"strings"
	"testing"
	"time"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/modelrelease"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

func valid() modelrelease.Input {
	return modelrelease.Input{
		Version: "v1", Sha256: strings.Repeat("a", 64), SizeBytes: 9_000_000,
		ClassLabels:         []string{"Potato___Early_blight", "Potato___Late_blight", "Potato___healthy"},
		ConfidenceThreshold: 0.5, InputShape: []int{1, 224, 224, 3},
	}
}

func TestInvariants(t *testing.T) {
	for _, tt := range []struct {
		name   string
		mutate func(*modelrelease.Input)
		code   string
	}{
		{"path traversal version", func(in *modelrelease.Input) { in.Version = "../etc" }, "invalid_version"},
		{"upper-case version", func(in *modelrelease.Input) { in.Version = "V1" }, "invalid_version"},
		{"short sha", func(in *modelrelease.Input) { in.Sha256 = "abc" }, "invalid_sha256"},
		{"empty file", func(in *modelrelease.Input) { in.SizeBytes = 0 }, "invalid_size"},
		{"no labels", func(in *modelrelease.Input) { in.ClassLabels = nil }, "invalid_class_labels"},
		{"blank label", func(in *modelrelease.Input) { in.ClassLabels = []string{""} }, "invalid_class_labels"},
		{"threshold", func(in *modelrelease.Input) { in.ConfidenceThreshold = 1.5 }, "invalid_threshold"},
		{"shape", func(in *modelrelease.Input) { in.InputShape = []int{224, 224} }, "invalid_input_shape"},
	} {
		t.Run(tt.name, func(t *testing.T) {
			in := valid()
			tt.mutate(&in)
			_, err := modelrelease.New(in, time.Now())
			if de, ok := shared.As(err); !ok || de.Code != tt.code {
				t.Fatalf("want %s, got %v", tt.code, err)
			}
		})
	}
}

func TestAccessorsReturnCopies(t *testing.T) {
	r, err := modelrelease.New(valid(), time.Now())
	if err != nil {
		t.Fatal(err)
	}
	r.ClassLabels()[0] = "tampered"
	if r.ClassLabels()[0] != "Potato___Early_blight" {
		t.Fatal("aggregate state must not be mutable from outside")
	}
}
