package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/modelrelease"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

// ModelReleaseRepository implements modelrelease.Repository.
type ModelReleaseRepository struct{ pool *pgxpool.Pool }

func NewModelReleaseRepository(pool *pgxpool.Pool) *ModelReleaseRepository {
	return &ModelReleaseRepository{pool: pool}
}

var _ modelrelease.Repository = (*ModelReleaseRepository)(nil)

const releaseColumns = `version, sha256, size_bytes, class_labels, confidence_threshold, input_shape, published_at, withdrawn_at`

func (r *ModelReleaseRepository) Save(ctx context.Context, m *modelrelease.ModelRelease) error {
	_, err := r.pool.Exec(ctx, `INSERT INTO model_releases (`+releaseColumns+`) VALUES ($1,$2,$3,$4,$5,$6,$7,NULL)`,
		m.Version(), m.Sha256(), m.SizeBytes(), m.ClassLabels(), m.ConfidenceThreshold(), m.InputShape(), m.PublishedAt())
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23505" { // unique_violation
		return shared.Conflict("release_exists", "model release "+m.Version()+" already exists")
	}
	if err != nil {
		return fmt.Errorf("save release: %w", err)
	}
	return nil
}

func (r *ModelReleaseRepository) Latest(ctx context.Context) (*modelrelease.ModelRelease, error) {
	m, err := scanRelease(r.pool.QueryRow(ctx, `SELECT `+releaseColumns+` FROM model_releases
		WHERE withdrawn_at IS NULL ORDER BY published_at DESC, version DESC LIMIT 1`))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, shared.NotFound("no_release", "no model release has been published")
	}
	return m, err
}

func (r *ModelReleaseRepository) FindByVersion(ctx context.Context, version string) (*modelrelease.ModelRelease, error) {
	m, err := scanRelease(r.pool.QueryRow(ctx, `SELECT `+releaseColumns+` FROM model_releases WHERE version = $1`, version))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, shared.NotFound("release_not_found", "no model release "+version)
	}
	return m, err
}

func (r *ModelReleaseRepository) Withdraw(ctx context.Context, version string, at time.Time) error {
	tag, err := r.pool.Exec(ctx, `UPDATE model_releases SET withdrawn_at = $2 WHERE version = $1`, version, at)
	if err != nil {
		return fmt.Errorf("withdraw release: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return shared.NotFound("release_not_found", "no model release "+version)
	}
	return nil
}

func scanRelease(row pgx.Row) (*modelrelease.ModelRelease, error) {
	var in modelrelease.Input
	var shape []int32
	var publishedAt time.Time
	var withdrawnAt *time.Time
	if err := row.Scan(&in.Version, &in.Sha256, &in.SizeBytes, &in.ClassLabels, &in.ConfidenceThreshold,
		&shape, &publishedAt, &withdrawnAt); err != nil {
		return nil, err
	}
	for _, v := range shape {
		in.InputShape = append(in.InputShape, int(v))
	}
	return modelrelease.Rehydrate(in, publishedAt, withdrawnAt), nil
}
