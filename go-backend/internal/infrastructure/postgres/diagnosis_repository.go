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
