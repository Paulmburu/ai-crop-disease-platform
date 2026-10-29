package diagnosis

import (
	"context"
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

// Len is for tests.
func (r *MemoryRepository) Len() int {
	r.mu.Lock()
	defer r.mu.Unlock()
	return len(r.items)
}
