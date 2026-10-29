// Package handlers turns HTTP requests into use-case calls and use-case results
// (or domain errors) into JSON responses. It is the only place that knows status codes.
package handlers

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/interfaces/http/middleware"
)

// ErrorBody is the error shape shared with the Python services.
type ErrorBody struct {
	Error     string `json:"error"`
	Detail    string `json:"detail"`
	RequestID string `json:"request_id"`
}

func WriteJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

// WriteError writes the shared error JSON (also used by middleware).
func WriteError(w http.ResponseWriter, r *http.Request, status int, code, detail string) {
	WriteJSON(w, status, ErrorBody{Error: code, Detail: detail, RequestID: middleware.GetRequestID(r.Context())})
}

// WriteDomainError maps domain error kinds to HTTP status codes. Anything that
// is not a domain error is logged and returned as an opaque 500.
func WriteDomainError(log *slog.Logger, w http.ResponseWriter, r *http.Request, err error) {
	if de, ok := shared.As(err); ok {
		status := map[shared.Kind]int{
			shared.KindInvalid:  http.StatusUnprocessableEntity,
			shared.KindNotFound: http.StatusNotFound,
			shared.KindConflict: http.StatusConflict,
		}[de.Kind]
		if status == 0 {
			status = http.StatusInternalServerError
		}
		WriteError(w, r, status, de.Code, de.Message)
		return
	}
	log.ErrorContext(r.Context(), "internal_error", "error", err, "request_id", middleware.GetRequestID(r.Context()))
	WriteError(w, r, http.StatusInternalServerError, "internal_error", "Unexpected server error")
}

// DecodeJSON reads a size-limited JSON body and rejects unknown fields.
func DecodeJSON(w http.ResponseWriter, r *http.Request, maxBytes int64, dst any) error {
	dec := json.NewDecoder(http.MaxBytesReader(w, r.Body, maxBytes))
	dec.DisallowUnknownFields()
	if err := dec.Decode(dst); err != nil {
		var tooBig *http.MaxBytesError
		if errors.As(err, &tooBig) {
			return errBodyTooLarge
		}
		return err
	}
	return nil
}

var errBodyTooLarge = errors.New("request body too large")
