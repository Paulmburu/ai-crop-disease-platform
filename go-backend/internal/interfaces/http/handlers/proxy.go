package handlers

import (
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strconv"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/advice"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/prediction"
)

// Proxies forwards prediction and advice requests to the Python services, so the
// phone needs one base URL, one API key and one error format.
type Proxies struct {
	Predictions *prediction.Service
	Advice      *advice.Service
	Log         *slog.Logger
}

func writeRawJSON(w http.ResponseWriter, body []byte) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(body)
}

// Predict: POST /api/v1/predictions (multipart "file", optional ?top_k=).
func (h Proxies) Predict(w http.ResponseWriter, r *http.Request) {
	r.Body = http.MaxBytesReader(w, r.Body, prediction.MaxImageBytes+64<<10) // image + multipart overhead
	file, hdr, err := r.FormFile("file")
	if err != nil {
		var tooBig *http.MaxBytesError
		if errors.As(err, &tooBig) {
			WriteError(w, r, http.StatusRequestEntityTooLarge, "payload_too_large", "image exceeds 5 MB")
			return
		}
		WriteError(w, r, http.StatusBadRequest, "bad_request", "multipart field 'file' is required")
		return
	}
	defer file.Close()
	data, err := io.ReadAll(file)
	if err != nil {
		WriteError(w, r, http.StatusBadRequest, "bad_request", "could not read the image")
		return
	}
	topK, _ := strconv.Atoi(r.URL.Query().Get("top_k"))
	res, err := h.Predictions.Predict(r.Context(), prediction.Image{
		Bytes: data, ContentType: hdr.Header.Get("Content-Type"), Filename: hdr.Filename,
	}, topK)
	if err != nil {
		WriteDomainError(h.Log, w, r, err)
		return
	}
	writeRawJSON(w, res.JSON)
}

type AdviceRequest struct {
	Question  string `json:"question"`
	ClassName string `json:"class_name"`
}

// Ask: POST /api/v1/advice {"question", "class_name"} → answer + sources from the RAG service.
func (h Proxies) Ask(w http.ResponseWriter, r *http.Request) {
	var req AdviceRequest
	if err := DecodeJSON(w, r, 16<<10, &req); err != nil {
		WriteError(w, r, http.StatusBadRequest, "bad_request", "invalid JSON: "+err.Error())
		return
	}
	ans, err := h.Advice.Ask(r.Context(), advice.Request(req))
	if err != nil {
		WriteDomainError(h.Log, w, r, err)
		return
	}
	writeRawJSON(w, ans.JSON)
}
