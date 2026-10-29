-- +goose Up
CREATE TABLE model_releases (
    version               TEXT PRIMARY KEY,
    sha256                CHAR(64)    NOT NULL,
    size_bytes            BIGINT      NOT NULL CHECK (size_bytes > 0),
    class_labels          TEXT[]      NOT NULL,
    confidence_threshold  DOUBLE PRECISION NOT NULL CHECK (confidence_threshold BETWEEN 0 AND 1),
    input_shape           INTEGER[]   NOT NULL,
    published_at          TIMESTAMPTZ NOT NULL,
    withdrawn_at          TIMESTAMPTZ
);

-- "Latest" = newest published, not withdrawn.
CREATE INDEX model_releases_latest_idx ON model_releases (published_at DESC) WHERE withdrawn_at IS NULL;

-- +goose Down
DROP TABLE model_releases;
