package diagnosis

import (
	"context"
	"sort"
	"sync"

	domain "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/diagnosis"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

// MemoryRepository is an in-memory domain.Repository for tests (here and in the
// HTTP layer). It is not used in production.
type MemoryRepository struct {
	mu    sync.Mutex
	items map[string]*domain.Diagnosis
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{items: map[string]*domain.Diagnosis{}}
}

func (r *MemoryRepository) Save(_ context.Context, d *domain.Diagnosis) (bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.items[d.ID()]; ok {
		return false, nil
	}
	r.items[d.ID()] = d
	return true, nil
}

func (r *MemoryRepository) FindByID(_ context.Context, id string) (*domain.Diagnosis, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if d, ok := r.items[id]; ok {
		return d, nil
	}
	return nil, shared.NotFound("diagnosis_not_found", "no diagnosis with id "+id)
}

func (r *MemoryRepository) SaveMany(_ context.Context, ds []*domain.Diagnosis) (map[string]bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	created := map[string]bool{}
	for _, d := range ds {
		if _, ok := r.items[d.ID()]; !ok {
			r.items[d.ID()] = d
			created[d.ID()] = true
		}
	}
	return created, nil
}

func (r *MemoryRepository) ListByDevice(_ context.Context, deviceID string, after *domain.Cursor, limit int) ([]*domain.Diagnosis, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	var out []*domain.Diagnosis
	for _, d := range r.items {
		if d.DeviceID() == deviceID && (after == nil || before(d, *after)) {
			out = append(out, d)
		}
	}
	sort.Slice(out, func(i, j int) bool { return before(out[j], domain.CursorOf(out[i])) }) // newest first
	if len(out) > limit {
		out = out[:limit]
	}
	return out, nil
}

// before reports whether d comes after cursor c in newest-first order
// (same ordering as the SQL: captured_at DESC, id DESC).
func before(d *domain.Diagnosis, c domain.Cursor) bool {
	if !d.CapturedAt().Equal(c.CapturedAt) {
		return d.CapturedAt().Before(c.CapturedAt)
	}
	return d.ID() < c.ID
}

// Len is for tests.
func (r *MemoryRepository) Len() int {
	r.mu.Lock()
	defer r.mu.Unlock()
	return len(r.items)
}
