// Package modelrelease is the Model Release bounded context: which on-device
// model (.tflite) phones should run, and how to verify the file they download.
package modelrelease

import (
	"context"
	"regexp"
	"time"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

var (
	// Versions double as file names, so keep them short and path-safe.
	versionRE = regexp.MustCompile(`^[a-z0-9][a-z0-9._-]{0,31}$`)
	sha256RE  = regexp.MustCompile(`^[0-9a-f]{64}$`)
)

// ModelRelease is the aggregate root.
type ModelRelease struct {
	version             string
	sha256              string
	sizeBytes           int64
	classLabels         []string
	confidenceThreshold float64
	inputShape          []int
	publishedAt         time.Time
	withdrawnAt         *time.Time
}

// Input describes a release. Sha256 and SizeBytes come from the stored artifact,
// never from the client, so the checksum phones verify is always the real one.
type Input struct {
	Version             string
	Sha256              string
	SizeBytes           int64
	ClassLabels         []string
	ConfidenceThreshold float64
	InputShape          []int // e.g. [1, 224, 224, 3]
}

func ValidVersion(v string) bool { return versionRE.MatchString(v) }

// New validates every invariant.
func New(in Input, now time.Time) (*ModelRelease, error) {
	switch {
	case !ValidVersion(in.Version):
		return nil, shared.Invalid("invalid_version", "version must be 1-32 chars: lowercase letters, digits, . _ -")
	case !sha256RE.MatchString(in.Sha256):
		return nil, shared.Invalid("invalid_sha256", "sha256 must be 64 lowercase hex characters")
	case in.SizeBytes <= 0:
		return nil, shared.Invalid("invalid_size", "artifact is empty")
	case len(in.ClassLabels) == 0:
		return nil, shared.Invalid("invalid_class_labels", "at least one class label is required")
	case in.ConfidenceThreshold < 0 || in.ConfidenceThreshold > 1:
		return nil, shared.Invalid("invalid_threshold", "confidence_threshold must be between 0 and 1")
	case len(in.InputShape) != 4:
		return nil, shared.Invalid("invalid_input_shape", "input_shape must be [batch, height, width, channels]")
	}
	for _, l := range in.ClassLabels {
		if l == "" {
			return nil, shared.Invalid("invalid_class_labels", "class labels must not be empty")
		}
	}
	return Rehydrate(in, now, nil), nil
}

// Rehydrate rebuilds a stored release (repositories only).
func Rehydrate(in Input, publishedAt time.Time, withdrawnAt *time.Time) *ModelRelease {
	return &ModelRelease{
		version: in.Version, sha256: in.Sha256, sizeBytes: in.SizeBytes,
		classLabels: append([]string(nil), in.ClassLabels...), confidenceThreshold: in.ConfidenceThreshold,
		inputShape: append([]int(nil), in.InputShape...), publishedAt: publishedAt.UTC(), withdrawnAt: withdrawnAt,
	}
}

func (m *ModelRelease) Version() string              { return m.version }
func (m *ModelRelease) Sha256() string               { return m.sha256 }
func (m *ModelRelease) SizeBytes() int64             { return m.sizeBytes }
func (m *ModelRelease) ClassLabels() []string        { return append([]string(nil), m.classLabels...) }
func (m *ModelRelease) ConfidenceThreshold() float64 { return m.confidenceThreshold }
func (m *ModelRelease) InputShape() []int            { return append([]int(nil), m.inputShape...) }
func (m *ModelRelease) PublishedAt() time.Time       { return m.publishedAt }
func (m *ModelRelease) Withdrawn() bool              { return m.withdrawnAt != nil }

// Repository is the persistence port.
type Repository interface {
	// Save stores a new release; KindConflict if the version already exists.
	Save(ctx context.Context, r *ModelRelease) error
	// Latest returns the most recently published release that is not withdrawn
	// (KindNotFound when there is none).
	Latest(ctx context.Context) (*ModelRelease, error)
	FindByVersion(ctx context.Context, version string) (*ModelRelease, error)
	// Withdraw marks a release withdrawn; KindNotFound if unknown.
	Withdraw(ctx context.Context, version string, at time.Time) error
}
