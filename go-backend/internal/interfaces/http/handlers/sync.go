package handlers

import (
	"encoding/base64"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"

	app "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/diagnosis"
	domain "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/diagnosis"
)

type SyncRequest struct {
	Items []DiagnosisRequest `json:"items"`
}

type SyncItem struct {
	ID      string     `json:"id"`
	Outcome string     `json:"outcome"` // created | duplicate | invalid
	Error   *ErrorItem `json:"error,omitempty"`
}

type ErrorItem struct {
	Code   string `json:"code"`
	Detail string `json:"detail"`
}

type SyncResponse struct {
	Created   int        `json:"created"`
	Duplicate int        `json:"duplicate"`
	Invalid   int        `json:"invalid"`
	Items     []SyncItem `json:"items"` // same order as the request
}

// Sync: POST /api/v1/diagnoses:sync. Always 200 when the batch itself is valid;
// per-item problems are reported in items[].
func (h Diagnoses) Sync(w http.ResponseWriter, r *http.Request) {
	var req SyncRequest
	if err := DecodeJSON(w, r, h.MaxBodyBytes, &req); err != nil {
		if errors.Is(err, errBodyTooLarge) {
			WriteError(w, r, http.StatusRequestEntityTooLarge, "payload_too_large", err.Error())
			return
		}
		WriteError(w, r, http.StatusBadRequest, "bad_request", "invalid JSON: "+err.Error())
		return
	}
	inputs := make([]domain.NewInput, len(req.Items))
	for i, it := range req.Items {
		inputs[i] = domain.NewInput(it)
	}
	results, err := h.Service.Sync(r.Context(), inputs)
	if err != nil {
		WriteDomainError(h.Log, w, r, err)
		return
	}
	resp := SyncResponse{Items: make([]SyncItem, len(results))}
	for i, res := range results {
		item := SyncItem{ID: res.ID, Outcome: string(res.Outcome)}
		switch res.Outcome {
		case app.OutcomeCreated:
			resp.Created++
		case app.OutcomeDuplicate:
			resp.Duplicate++
		case app.OutcomeInvalid:
			resp.Invalid++
			item.Error = &ErrorItem{Code: res.Error.Code, Detail: res.Error.Message}
		}
		resp.Items[i] = item
	}
	WriteJSON(w, http.StatusOK, resp)
}

type HistoryResponse struct {
	Items      []DiagnosisResponse `json:"items"`
	NextCursor *string             `json:"next_cursor"` // null on the last page
}

// History: GET /api/v1/devices/{device_id}/diagnoses?limit=50&cursor=... (newest first).
func (h Diagnoses) History(w http.ResponseWriter, r *http.Request) {
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	var after *domain.Cursor
	if raw := r.URL.Query().Get("cursor"); raw != "" {
		c, err := decodeCursor(raw)
		if err != nil {
			WriteError(w, r, http.StatusBadRequest, "invalid_cursor", "cursor is not valid")
			return
		}
		after = &c
	}
	page, err := h.Service.List(r.Context(), chi.URLParam(r, "device_id"), after, limit)
	if err != nil {
		WriteDomainError(h.Log, w, r, err)
		return
	}
	resp := HistoryResponse{Items: make([]DiagnosisResponse, len(page.Items))}
	for i, d := range page.Items {
		resp.Items[i] = toResponse(d)
	}
	if page.Next != nil {
		s := encodeCursor(*page.Next)
		resp.NextCursor = &s
	}
	WriteJSON(w, http.StatusOK, resp)
}

// Cursors are opaque to clients: base64("<RFC3339Nano>|<id>").
func encodeCursor(c domain.Cursor) string {
	return base64.RawURLEncoding.EncodeToString([]byte(c.CapturedAt.UTC().Format(time.RFC3339Nano) + "|" + c.ID))
}

func decodeCursor(s string) (domain.Cursor, error) {
	b, err := base64.RawURLEncoding.DecodeString(s)
	if err != nil {
		return domain.Cursor{}, err
	}
	ts, id, ok := strings.Cut(string(b), "|")
	if !ok {
		return domain.Cursor{}, errors.New("malformed cursor")
	}
	t, err := time.Parse(time.RFC3339Nano, ts)
	if err != nil {
		return domain.Cursor{}, err
	}
	return domain.Cursor{CapturedAt: t, ID: id}, nil
}
