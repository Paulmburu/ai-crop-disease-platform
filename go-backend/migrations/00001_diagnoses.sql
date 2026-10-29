-- +goose Up
CREATE TABLE diagnoses (
    id                    UUID PRIMARY KEY,               -- client-generated: the idempotency key
    device_id             TEXT        NOT NULL,
    class_label           TEXT        NOT NULL,
    confidence            DOUBLE PRECISION NOT NULL CHECK (confidence BETWEEN 0 AND 1),
    confidence_threshold  DOUBLE PRECISION NOT NULL CHECK (confidence_threshold BETWEEN 0 AND 1),
    model_version         TEXT        NOT NULL,
    captured_at           TIMESTAMPTZ NOT NULL,
    recorded_at           TIMESTAMPTZ NOT NULL
);

-- History per device, newest first (milestone M1).
CREATE INDEX diagnoses_device_captured_idx ON diagnoses (device_id, captured_at DESC, id);

-- +goose Down
DROP TABLE diagnoses;
