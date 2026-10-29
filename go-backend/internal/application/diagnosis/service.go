// Package diagnosis holds the Diagnosis use cases. It orchestrates the domain and
// talks to the outside world only through ports (interfaces), never concrete adapters.
package diagnosis

import (
	"context"
	"time"

	domain "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/diagnosis"
)

// Clock is a port so tests control "now" (domain/application never call time.Now).
type Clock interface{ Now() time.Time }

// Service groups the Diagnosis use cases.
type Service struct {
	repo  domain.Repository
	clock Clock
}

func NewService(repo domain.Repository, clock Clock) *Service {
	return &Service{repo: repo, clock: clock}
}

// RecordResult tells the caller whether the diagnosis was new or already synced.
type RecordResult struct {
	Diagnosis *domain.Diagnosis
	Created   bool
}

// Record stores a diagnosis synced from a phone. It is idempotent: sending the
// same id again returns the stored record with Created=false. That is what makes
// retrying an interrupted offline sync safe.
func (s *Service) Record(ctx context.Context, in domain.NewInput) (RecordResult, error) {
	d, err := domain.NewDiagnosis(in, s.clock.Now())
	if err != nil {
		return RecordResult{}, err
	}
	created, err := s.repo.Save(ctx, d)
	if err != nil {
		return RecordResult{}, err
	}
	if created {
		return RecordResult{Diagnosis: d, Created: true}, nil
	}
	existing, err := s.repo.FindByID(ctx, d.ID())
	if err != nil {
		return RecordResult{}, err
	}
	return RecordResult{Diagnosis: existing, Created: false}, nil
}

// Get returns one diagnosis by id.
func (s *Service) Get(ctx context.Context, id string) (*domain.Diagnosis, error) {
	return s.repo.FindByID(ctx, id)
}
