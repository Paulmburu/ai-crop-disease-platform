// Package diagnosis holds the Diagnosis use cases. It orchestrates the domain and
// talks to the outside world only through ports (interfaces), never concrete adapters.
package diagnosis

import (
	"context"
	"fmt"
	"time"

	domain "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/diagnosis"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
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

// MaxSyncBatch bounds one sync request (PRD D3).
const MaxSyncBatch = 500

// Outcome of one item in a sync batch.
type Outcome string

const (
	OutcomeCreated   Outcome = "created"
	OutcomeDuplicate Outcome = "duplicate"
	OutcomeInvalid   Outcome = "invalid"
)

// SyncItemResult reports what happened to one item, in request order.
type SyncItemResult struct {
	ID      string
	Outcome Outcome
	Error   *shared.Error // set when Outcome is invalid
}

// Sync records a backlog of diagnoses uploaded by a phone after reconnecting.
// Each item is validated on its own: one bad item never blocks the others. Valid
// items are stored atomically; ids already stored come back as "duplicate", so
// re-sending the same batch after a dropped connection is safe.
func (s *Service) Sync(ctx context.Context, items []domain.NewInput) ([]SyncItemResult, error) {
	if len(items) == 0 {
		return nil, shared.Invalid("empty_batch", "items must contain at least one diagnosis")
	}
	if len(items) > MaxSyncBatch {
		return nil, shared.Invalid("batch_too_large", fmt.Sprintf("at most %d items per sync", MaxSyncBatch))
	}
	now := s.clock.Now()
	results := make([]SyncItemResult, len(items))
	var valid []*domain.Diagnosis
	seen := map[string]bool{}
	for i, in := range items {
		d, err := domain.NewDiagnosis(in, now)
		if err != nil {
			de, _ := shared.As(err)
			results[i] = SyncItemResult{ID: in.ID, Outcome: OutcomeInvalid, Error: de}
			continue
		}
		results[i] = SyncItemResult{ID: d.ID()}
		if !seen[d.ID()] { // the same id twice in one batch is stored once
			seen[d.ID()] = true
			valid = append(valid, d)
		}
	}
	created := map[string]bool{}
	if len(valid) > 0 {
		var err error
		if created, err = s.repo.SaveMany(ctx, valid); err != nil {
			return nil, err
		}
	}
	for i := range results {
		if results[i].Outcome == OutcomeInvalid {
			continue
		}
		if created[results[i].ID] {
			results[i].Outcome = OutcomeCreated
			delete(created, results[i].ID) // a repeated id later in the batch is a duplicate
		} else {
			results[i].Outcome = OutcomeDuplicate
		}
	}
	return results, nil
}

// MaxPageSize bounds one history page.
const MaxPageSize = 100

// Page is one page of a device's history plus the cursor for the next one (nil = end).
type Page struct {
	Items []*domain.Diagnosis
	Next  *domain.Cursor
}

// List returns a device's diagnoses, newest first.
func (s *Service) List(ctx context.Context, deviceID string, after *domain.Cursor, limit int) (Page, error) {
	if deviceID == "" {
		return Page{}, shared.Invalid("invalid_device_id", "device_id is required")
	}
	if limit <= 0 || limit > MaxPageSize {
		limit = MaxPageSize
	}
	// Ask for one extra row to know whether another page exists.
	items, err := s.repo.ListByDevice(ctx, deviceID, after, limit+1)
	if err != nil {
		return Page{}, err
	}
	page := Page{Items: items}
	if len(items) > limit {
		page.Items = items[:limit]
		c := domain.CursorOf(page.Items[limit-1])
		page.Next = &c
	}
	return page, nil
}
