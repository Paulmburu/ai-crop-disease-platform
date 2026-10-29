package diagnosis_test

import (
	"testing"
	"time"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/diagnosis"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

var now = time.Date(2026, 10, 30, 12, 0, 0, 0, time.UTC)

func valid() diagnosis.NewInput {
	return diagnosis.NewInput{
		ID: "6f1c2b9e-3d4a-4f5b-9c8d-7e6f5a4b3c2d", DeviceID: "device-1",
		ClassLabel: "Potato___Late_blight", Confidence: 0.93, ConfidenceThreshold: 0.5,
		ModelVersion: "v1", CapturedAt: now.Add(-time.Hour),
	}
}

func TestNewDiagnosisInvariants(t *testing.T) {
	tests := []struct {
		name   string
		mutate func(*diagnosis.NewInput)
		code   string
	}{
		{"not a uuid", func(in *diagnosis.NewInput) { in.ID = "abc" }, "invalid_id"},
		{"empty device", func(in *diagnosis.NewInput) { in.DeviceID = " " }, "invalid_device_id"},
		{"empty label", func(in *diagnosis.NewInput) { in.ClassLabel = "" }, "invalid_class_label"},
		{"confidence > 1", func(in *diagnosis.NewInput) { in.Confidence = 1.2 }, "invalid_confidence"},
		{"confidence < 0", func(in *diagnosis.NewInput) { in.Confidence = -0.1 }, "invalid_confidence"},
		{"threshold > 1", func(in *diagnosis.NewInput) { in.ConfidenceThreshold = 2 }, "invalid_threshold"},
		{"no model version", func(in *diagnosis.NewInput) { in.ModelVersion = "" }, "invalid_model_version"},
		{"no capture time", func(in *diagnosis.NewInput) { in.CapturedAt = time.Time{} }, "invalid_captured_at"},
		{"future capture", func(in *diagnosis.NewInput) { in.CapturedAt = now.Add(25 * time.Hour) }, "invalid_captured_at"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			in := valid()
			tt.mutate(&in)
			_, err := diagnosis.NewDiagnosis(in, now)
			de, ok := shared.As(err)
			if !ok || de.Kind != shared.KindInvalid || de.Code != tt.code {
				t.Fatalf("want invalid %q, got %v", tt.code, err)
			}
		})
	}
}

func TestSmallClockSkewIsAccepted(t *testing.T) {
	in := valid()
	in.CapturedAt = now.Add(diagnosis.MaxClockSkew - time.Second)
	if _, err := diagnosis.NewDiagnosis(in, now); err != nil {
		t.Fatal(err)
	}
}

func TestStatusIsDerivedFromThreshold(t *testing.T) {
	for _, tt := range []struct {
		conf, threshold float64
		want            diagnosis.Status
	}{
		{0.93, 0.5, diagnosis.StatusOK},
		{0.5, 0.5, diagnosis.StatusOK}, // threshold is inclusive, as in the ML service
		{0.49, 0.5, diagnosis.StatusUncertain},
	} {
		in := valid()
		in.Confidence, in.ConfidenceThreshold = tt.conf, tt.threshold
		d, err := diagnosis.NewDiagnosis(in, now)
		if err != nil {
			t.Fatal(err)
		}
		if d.Status() != tt.want {
			t.Errorf("conf %.2f threshold %.2f: want %s, got %s", tt.conf, tt.threshold, tt.want, d.Status())
		}
	}
}

func TestIsHealthyOnlyWhenConfident(t *testing.T) {
	in := valid()
	in.ClassLabel = "Potato___healthy"
	d, _ := diagnosis.NewDiagnosis(in, now)
	if !d.IsHealthy() {
		t.Error("confident healthy label should be healthy")
	}
	in.Confidence = 0.2
	d, _ = diagnosis.NewDiagnosis(in, now)
	if d.IsHealthy() {
		t.Error("uncertain result must not be reported as healthy")
	}
}

func TestIDIsNormalisedToLowerCase(t *testing.T) {
	in := valid()
	in.ID = "6F1C2B9E-3D4A-4F5B-9C8D-7E6F5A4B3C2D"
	d, _ := diagnosis.NewDiagnosis(in, now)
	if d.ID() != "6f1c2b9e-3d4a-4f5b-9c8d-7e6f5a4b3c2d" {
		t.Errorf("got %s", d.ID())
	}
}
