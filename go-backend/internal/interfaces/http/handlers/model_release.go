package handlers

import (
	"errors"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"

	app "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/modelrelease"
	domain "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/modelrelease"
)

type ModelReleaseResponse struct {
	Version             string    `json:"version"`
	Sha256              string    `json:"sha256"`
	SizeBytes           int64     `json:"size_bytes"`
	ClassLabels         []string  `json:"class_labels"`
	ConfidenceThreshold float64   `json:"confidence_threshold"`
	InputShape          []int     `json:"input_shape"`
	InputLayout         string    `json:"input_layout"`
	ArtifactURL         string    `json:"artifact_url"` // relative to the API base URL
	PublishedAt         time.Time `json:"published_at"`
}

func toReleaseResponse(r *domain.ModelRelease) ModelReleaseResponse {
	return ModelReleaseResponse{
		Version: r.Version(), Sha256: r.Sha256(), SizeBytes: r.SizeBytes(), ClassLabels: r.ClassLabels(),
		ConfidenceThreshold: r.ConfidenceThreshold(), InputShape: r.InputShape(), InputLayout: "NHWC",
		ArtifactURL: "/api/v1/model-releases/" + r.Version() + "/artifact", PublishedAt: r.PublishedAt(),
	}
}

// ModelReleases holds the model-release endpoints.
type ModelReleases struct {
	Service      *app.Service
	Log          *slog.Logger
	MaxBodyBytes int64
}

// etag quotes the checksum: a release's content never changes, so it is a strong ETag.
func etag(sha string) string { return `"` + sha + `"` }

// Latest: GET /api/v1/model-releases/latest. Phones send If-None-Match with the
// ETag they have; 304 means "your model is current" with no body to download.
func (h ModelReleases) Latest(w http.ResponseWriter, r *http.Request) {
	rel, err := h.Service.Latest(r.Context())
	if err != nil {
		WriteDomainError(h.Log, w, r, err)
		return
	}
	tag := etag(rel.Sha256())
	w.Header().Set("ETag", tag)
	w.Header().Set("Cache-Control", "no-cache") // always revalidate, cheap thanks to the ETag
	if strings.Contains(r.Header.Get("If-None-Match"), tag) {
		w.WriteHeader(http.StatusNotModified)
		return
	}
	WriteJSON(w, http.StatusOK, toReleaseResponse(rel))
}

// Artifact: GET /api/v1/model-releases/{version}/artifact. http.ServeContent
// supports Range requests, so an interrupted download on a weak network resumes.
func (h ModelReleases) Artifact(w http.ResponseWriter, r *http.Request) {
	rel, a, err := h.Service.OpenArtifact(r.Context(), chi.URLParam(r, "version"))
	if err != nil {
		WriteDomainError(h.Log, w, r, err)
		return
	}
	defer a.Content.Close()
	w.Header().Set("Content-Type", "application/octet-stream")
	w.Header().Set("ETag", etag(rel.Sha256()))
	w.Header().Set("X-Checksum-Sha256", rel.Sha256())
	w.Header().Set("Content-Disposition", `attachment; filename="crop_disease_`+rel.Version()+`.tflite"`)
	http.ServeContent(w, r, "", a.ModTime, a.Content)
}

type PublishRequest struct {
	Version             string   `json:"version"`
	ClassLabels         []string `json:"class_labels"`
	ConfidenceThreshold float64  `json:"confidence_threshold"`
	InputShape          []int    `json:"input_shape"`
}

// Publish: POST /api/v1/model-releases (admin key). The .tflite must already be in MODELS_DIR.
func (h ModelReleases) Publish(w http.ResponseWriter, r *http.Request) {
	var req PublishRequest
	if err := DecodeJSON(w, r, h.MaxBodyBytes, &req); err != nil {
		if errors.Is(err, errBodyTooLarge) {
			WriteError(w, r, http.StatusRequestEntityTooLarge, "payload_too_large", err.Error())
			return
		}
		WriteError(w, r, http.StatusBadRequest, "bad_request", "invalid JSON: "+err.Error())
		return
	}
	rel, err := h.Service.Publish(r.Context(), app.PublishInput(req))
	if err != nil {
		WriteDomainError(h.Log, w, r, err)
		return
	}
	WriteJSON(w, http.StatusCreated, toReleaseResponse(rel))
}

// Withdraw: DELETE /api/v1/model-releases/{version} (admin key).
func (h ModelReleases) Withdraw(w http.ResponseWriter, r *http.Request) {
	if err := h.Service.Withdraw(r.Context(), chi.URLParam(r, "version")); err != nil {
		WriteDomainError(h.Log, w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
