// Package modelrelease holds the Model Release use cases: publish, find the
// latest, withdraw, and open the artifact for download.
package modelrelease

import (
	"context"
	"io"
	"time"

	domain "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/modelrelease"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

type Clock interface{ Now() time.Time }

// Artifact is an opened model file.
type Artifact struct {
	Content   io.ReadSeekCloser
	SizeBytes int64
	Sha256    string
	ModTime   time.Time
}

// ArtifactStore is the port to wherever .tflite files live (local folder today,
// object storage later). Describe computes the real checksum and size.
type ArtifactStore interface {
	Describe(ctx context.Context, version string) (sha256 string, size int64, err error)
	Open(ctx context.Context, version string) (Artifact, error)
}

type Service struct {
	repo  domain.Repository
	store ArtifactStore
	clock Clock
}

func NewService(repo domain.Repository, store ArtifactStore, clock Clock) *Service {
	return &Service{repo: repo, store: store, clock: clock}
}

// PublishInput is what an admin (or the startup seeder) supplies.
type PublishInput struct {
	Version             string
	ClassLabels         []string
	ConfidenceThreshold float64
	InputShape          []int
}

// Publish registers a release whose artifact already exists in the store.
// Checksum and size are taken from the file itself.
func (s *Service) Publish(ctx context.Context, in PublishInput) (*domain.ModelRelease, error) {
	if !domain.ValidVersion(in.Version) { // check before touching the store with the name
		return nil, shared.Invalid("invalid_version", "version must be 1-32 chars: lowercase letters, digits, . _ -")
	}
	sum, size, err := s.store.Describe(ctx, in.Version)
	if err != nil {
		return nil, err
	}
	r, err := domain.New(domain.Input{
		Version: in.Version, Sha256: sum, SizeBytes: size, ClassLabels: in.ClassLabels,
		ConfidenceThreshold: in.ConfidenceThreshold, InputShape: in.InputShape,
	}, s.clock.Now())
	if err != nil {
		return nil, err
	}
	if err := s.repo.Save(ctx, r); err != nil {
		return nil, err
	}
	return r, nil
}

// PublishIfAbsent is used by the startup seeder: publishing an existing version is not an error.
func (s *Service) PublishIfAbsent(ctx context.Context, in PublishInput) (created bool, err error) {
	if _, err := s.repo.FindByVersion(ctx, in.Version); err == nil {
		return false, nil
	} else if de, ok := shared.As(err); !ok || de.Kind != shared.KindNotFound {
		return false, err
	}
	_, err = s.Publish(ctx, in)
	return err == nil, err
}

func (s *Service) Latest(ctx context.Context) (*domain.ModelRelease, error) {
	return s.repo.Latest(ctx)
}

func (s *Service) Withdraw(ctx context.Context, version string) error {
	return s.repo.Withdraw(ctx, version, s.clock.Now())
}

// OpenArtifact returns the file of a published, non-withdrawn release.
func (s *Service) OpenArtifact(ctx context.Context, version string) (*domain.ModelRelease, Artifact, error) {
	r, err := s.repo.FindByVersion(ctx, version)
	if err != nil {
		return nil, Artifact{}, err
	}
	if r.Withdrawn() {
		return nil, Artifact{}, shared.NotFound("release_withdrawn", "model release "+version+" was withdrawn")
	}
	a, err := s.store.Open(ctx, version)
	if err != nil {
		return nil, Artifact{}, err
	}
	// The file was replaced after publishing: the phone would reject it anyway, so
	// fail loudly here instead. Publish a new version for a new file.
	if a.Sha256 != r.Sha256() {
		_ = a.Content.Close()
		return nil, Artifact{}, shared.Conflict("artifact_checksum_mismatch",
			"model file for "+version+" no longer matches its published sha256")
	}
	return r, a, nil
}
