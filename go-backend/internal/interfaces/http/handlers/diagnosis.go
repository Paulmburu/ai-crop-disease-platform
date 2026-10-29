package handlers

import (
	"errors"
	"log/slog"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	app "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/diagnosis"
	domain "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/diagnosis"
)

// DiagnosisRequest is the JSON the phone sends. Status is not accepted: the
// server derives it from confidence and threshold.
type DiagnosisRequest struct {
	ID                  string    `json:"id"`
	DeviceID            string    `json:"device_id"`
	ClassLabel          string    `json:"class_label"`
	Confidence          float64   `json:"confidence"`
	ConfidenceThreshold float64   `json:"confidence_threshold"`
	ModelVersion        string    `json:"model_version"`
	CapturedAt          time.Time `json:"captured_at"`
}

type DiagnosisResponse struct {
	ID                  string    `json:"id"`
	DeviceID            string    `json:"device_id"`
	ClassLabel          string    `json:"class_label"`
	Confidence          float64   `json:"confidence"`
	ConfidenceThreshold float64   `json:"confidence_threshold"`
	Status              string    `json:"status"`
	IsHealthy           bool      `json:"is_healthy"`
	ModelVersion        string    `json:"model_version"`
	CapturedAt          time.Time `json:"captured_at"`
	RecordedAt          time.Time `json:"recorded_at"`
}

func toResponse(d *domain.Diagnosis) DiagnosisResponse {
	return DiagnosisResponse{
		ID: d.ID(), DeviceID: d.DeviceID(), ClassLabel: d.ClassLabel(), Confidence: d.Confidence(),
		ConfidenceThreshold: d.ConfidenceThreshold(), Status: string(d.Status()), IsHealthy: d.IsHealthy(),
		ModelVersion: d.ModelVersion(), CapturedAt: d.CapturedAt(), RecordedAt: d.RecordedAt(),
	}
}

// Diagnoses holds the diagnosis endpoints.
type Diagnoses struct {
	Service      *app.Service
	Log          *slog.Logger
	MaxBodyBytes int64
}

// Create: POST /api/v1/diagnoses. 201 when new, 200 when the id was already synced.
func (h Diagnoses) Create(w http.ResponseWriter, r *http.Request) {
	var req DiagnosisRequest
	if err := DecodeJSON(w, r, h.MaxBodyBytes, &req); err != nil {
		if errors.Is(err, errBodyTooLarge) {
			WriteError(w, r, http.StatusRequestEntityTooLarge, "payload_too_large", err.Error())
			return
		}
		WriteError(w, r, http.StatusBadRequest, "bad_request", "invalid JSON: "+err.Error())
		return
	}
	res, err := h.Service.Record(r.Context(), domain.NewInput(req))
	if err != nil {
		WriteDomainError(h.Log, w, r, err)
		return
	}
	status := http.StatusOK
	if res.Created {
		status = http.StatusCreated
	}
	WriteJSON(w, status, toResponse(res.Diagnosis))
}

// Get: GET /api/v1/diagnoses/{id}.
func (h Diagnoses) Get(w http.ResponseWriter, r *http.Request) {
	d, err := h.Service.Get(r.Context(), chi.URLParam(r, "id"))
	if err != nil {
		WriteDomainError(h.Log, w, r, err)
		return
	}
	WriteJSON(w, http.StatusOK, toResponse(d))
}
