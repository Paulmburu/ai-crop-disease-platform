package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/diagnosis"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

// DiagnosisRepository implements diagnosis.Repository.
type DiagnosisRepository struct{ pool *pgxpool.Pool }

func NewDiagnosisRepository(pool *pgxpool.Pool) *DiagnosisRepository {
	return &DiagnosisRepository{pool: pool}
}

var _ diagnosis.Repository = (*DiagnosisRepository)(nil)

// Save inserts unless the id exists; ON CONFLICT makes concurrent retries safe too.
func (r *DiagnosisRepository) Save(ctx context.Context, d *diagnosis.Diagnosis) (bool, error) {
	tag, err := r.pool.Exec(ctx, `
		INSERT INTO diagnoses (id, device_id, class_label, confidence, confidence_threshold,
		                       model_version, captured_at, recorded_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		ON CONFLICT (id) DO NOTHING`,
		d.ID(), d.DeviceID(), d.ClassLabel(), d.Confidence(), d.ConfidenceThreshold(),
		d.ModelVersion(), d.CapturedAt(), d.RecordedAt())
	if err != nil {
		return false, fmt.Errorf("save diagnosis: %w", err)
	}
	return tag.RowsAffected() == 1, nil
}

func (r *DiagnosisRepository) FindByID(ctx context.Context, id string) (*diagnosis.Diagnosis, error) {
	var in diagnosis.NewInput
	var recordedAt time.Time
	err := r.pool.QueryRow(ctx, `
		SELECT id::text, device_id, class_label, confidence, confidence_threshold,
		       model_version, captured_at, recorded_at
		FROM diagnoses WHERE id::text = $1`, id).
		Scan(&in.ID, &in.DeviceID, &in.ClassLabel, &in.Confidence, &in.ConfidenceThreshold,
			&in.ModelVersion, &in.CapturedAt, &recordedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, shared.NotFound("diagnosis_not_found", "no diagnosis with id "+id)
	}
	if err != nil {
		return nil, fmt.Errorf("find diagnosis: %w", err)
	}
	return diagnosis.Rehydrate(in, recordedAt), nil
}

// SaveMany inserts all diagnoses in one transaction; RETURNING id tells us which
// rows were new (existing ids are skipped by ON CONFLICT and not returned).
func (r *DiagnosisRepository) SaveMany(ctx context.Context, ds []*diagnosis.Diagnosis) (map[string]bool, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }() // no-op after Commit

	batch := &pgx.Batch{}
	for _, d := range ds {
		batch.Queue(`
			INSERT INTO diagnoses (id, device_id, class_label, confidence, confidence_threshold,
			                       model_version, captured_at, recorded_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
			ON CONFLICT (id) DO NOTHING
			RETURNING id::text`,
			d.ID(), d.DeviceID(), d.ClassLabel(), d.Confidence(), d.ConfidenceThreshold(),
			d.ModelVersion(), d.CapturedAt(), d.RecordedAt())
	}
	results := tx.SendBatch(ctx, batch)
	created := map[string]bool{}
	for range ds {
		var id string
		err := results.QueryRow().Scan(&id)
		switch {
		case errors.Is(err, pgx.ErrNoRows): // already stored
		case err != nil:
			_ = results.Close()
			return nil, fmt.Errorf("save batch: %w", err)
		default:
			created[id] = true
		}
	}
	if err := results.Close(); err != nil {
		return nil, fmt.Errorf("save batch: %w", err)
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit: %w", err)
	}
	return created, nil
}

// ListByDevice uses keyset pagination on (captured_at, id), served by the
// diagnoses_device_captured_idx index; no OFFSET, so deep pages stay fast.
func (r *DiagnosisRepository) ListByDevice(ctx context.Context, deviceID string, after *diagnosis.Cursor, limit int) ([]*diagnosis.Diagnosis, error) {
	query := `
		SELECT id::text, device_id, class_label, confidence, confidence_threshold,
		       model_version, captured_at, recorded_at
		FROM diagnoses WHERE device_id = $1`
	args := []any{deviceID}
	if after != nil {
		query += ` AND (captured_at, id) < ($2, $3::uuid)`
		args = append(args, after.CapturedAt, after.ID)
	}
	query += fmt.Sprintf(` ORDER BY captured_at DESC, id DESC LIMIT %d`, limit)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("list diagnoses: %w", err)
	}
	defer rows.Close()
	var out []*diagnosis.Diagnosis
	for rows.Next() {
		var in diagnosis.NewInput
		var recordedAt time.Time
		if err := rows.Scan(&in.ID, &in.DeviceID, &in.ClassLabel, &in.Confidence, &in.ConfidenceThreshold,
			&in.ModelVersion, &in.CapturedAt, &recordedAt); err != nil {
			return nil, fmt.Errorf("scan diagnosis: %w", err)
		}
		out = append(out, diagnosis.Rehydrate(in, recordedAt))
	}
	return out, rows.Err()
}
