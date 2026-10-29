package modelrelease

import (
	"context"
	"sync"
	"time"

	domain "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/modelrelease"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

// MemoryRepository is an in-memory domain.Repository for tests.
type MemoryRepository struct {
	mu        sync.Mutex
	order     []string
	items     map[string]*domain.ModelRelease
	withdrawn map[string]time.Time
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{items: map[string]*domain.ModelRelease{}, withdrawn: map[string]time.Time{}}
}

func (m *MemoryRepository) Save(_ context.Context, r *domain.ModelRelease) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if _, ok := m.items[r.Version()]; ok {
		return shared.Conflict("release_exists", "model release "+r.Version()+" already exists")
	}
	m.items[r.Version()] = r
	m.order = append(m.order, r.Version())
	return nil
}

func (m *MemoryRepository) Latest(ctx context.Context) (*domain.ModelRelease, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	for i := len(m.order) - 1; i >= 0; i-- { // newest published first
		if _, gone := m.withdrawn[m.order[i]]; !gone {
			return m.items[m.order[i]], nil
		}
	}
	return nil, shared.NotFound("no_release", "no model release has been published")
}

func (m *MemoryRepository) FindByVersion(_ context.Context, v string) (*domain.ModelRelease, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	r, ok := m.items[v]
	if !ok {
		return nil, shared.NotFound("release_not_found", "no model release "+v)
	}
	if at, gone := m.withdrawn[v]; gone {
		return domain.Rehydrate(domain.Input{
			Version: r.Version(), Sha256: r.Sha256(), SizeBytes: r.SizeBytes(), ClassLabels: r.ClassLabels(),
			ConfidenceThreshold: r.ConfidenceThreshold(), InputShape: r.InputShape(),
		}, r.PublishedAt(), &at), nil
	}
	return r, nil
}

func (m *MemoryRepository) Withdraw(_ context.Context, v string, at time.Time) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if _, ok := m.items[v]; !ok {
		return shared.NotFound("release_not_found", "no model release "+v)
	}
	m.withdrawn[v] = at
	return nil
}
