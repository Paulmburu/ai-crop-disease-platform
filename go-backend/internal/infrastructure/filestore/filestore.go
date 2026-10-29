// Package filestore stores model artifacts as files in one directory, using the
// naming the export script produces: crop_disease_<version>.tflite + .json.
package filestore

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"

	app "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/modelrelease"
	domain "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/modelrelease"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

const prefix = "crop_disease_"

// Store implements app.ArtifactStore on a local directory.
type Store struct{ dir string }

func New(dir string) *Store { return &Store{dir: dir} }

var _ app.ArtifactStore = (*Store)(nil)

func (s *Store) path(version, ext string) (string, error) {
	if !domain.ValidVersion(version) { // never build a path from an unvalidated name
		return "", shared.Invalid("invalid_version", "invalid version")
	}
	return filepath.Join(s.dir, prefix+version+ext), nil
}

func (s *Store) Describe(_ context.Context, version string) (string, int64, error) {
	p, err := s.path(version, ".tflite")
	if err != nil {
		return "", 0, err
	}
	f, err := os.Open(p)
	if errors.Is(err, fs.ErrNotExist) {
		return "", 0, shared.NotFound("artifact_not_found", "no model file for version "+version)
	}
	if err != nil {
		return "", 0, err
	}
	defer f.Close()
	h := sha256.New()
	n, err := io.Copy(h, f)
	if err != nil {
		return "", 0, fmt.Errorf("hash artifact: %w", err)
	}
	return hex.EncodeToString(h.Sum(nil)), n, nil
}

func (s *Store) Open(ctx context.Context, version string) (app.Artifact, error) {
	sum, size, err := s.Describe(ctx, version)
	if err != nil {
		return app.Artifact{}, err
	}
	p, _ := s.path(version, ".tflite")
	f, err := os.Open(p)
	if err != nil {
		return app.Artifact{}, err
	}
	st, err := f.Stat()
	if err != nil {
		_ = f.Close()
		return app.Artifact{}, err
	}
	return app.Artifact{Content: f, SizeBytes: size, Sha256: sum, ModTime: st.ModTime()}, nil
}

// exportMetadata mirrors the .json written by python-ml-service/scripts/export_tflite.py.
type exportMetadata struct {
	ModelVersion        string   `json:"model_version"`
	InputShape          []int    `json:"input_shape"`
	ClassNames          []string `json:"class_names"`
	ConfidenceThreshold *float64 `json:"confidence_threshold"`
}

// Discover returns publish inputs for every crop_disease_<v>.json with a matching
// .tflite in the directory (used by the startup seeder), sorted by version.
func (s *Store) Discover() ([]app.PublishInput, error) {
	matches, err := filepath.Glob(filepath.Join(s.dir, prefix+"*.json"))
	if err != nil {
		return nil, err
	}
	sort.Strings(matches)
	var out []app.PublishInput
	for _, m := range matches {
		version := strings.TrimSuffix(strings.TrimPrefix(filepath.Base(m), prefix), ".json")
		if !domain.ValidVersion(version) {
			continue
		}
		if _, err := os.Stat(filepath.Join(s.dir, prefix+version+".tflite")); err != nil {
			continue
		}
		raw, err := os.ReadFile(m)
		if err != nil {
			return nil, err
		}
		var meta exportMetadata
		if err := json.Unmarshal(raw, &meta); err != nil {
			return nil, fmt.Errorf("%s: %w", m, err)
		}
		threshold := 0.5 // default for exports made before the threshold existed
		if meta.ConfidenceThreshold != nil {
			threshold = *meta.ConfidenceThreshold
		}
		out = append(out, app.PublishInput{
			Version: version, ClassLabels: meta.ClassNames, ConfidenceThreshold: threshold, InputShape: meta.InputShape,
		})
	}
	return out, nil
}
