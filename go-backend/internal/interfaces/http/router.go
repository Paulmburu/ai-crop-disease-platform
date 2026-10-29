// Package http wires routes and middleware. Handlers live in ./handlers.
package http

import (
	"log/slog"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"

	app "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/diagnosis"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/interfaces/http/handlers"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/interfaces/http/middleware"
)

// Deps are everything the HTTP layer needs; built in cmd/api/main.go.
type Deps struct {
	Log            *slog.Logger
	DB             handlers.Pinger
	Diagnoses      *app.Service
	APIKeys        []string
	RequestTimeout time.Duration
	MaxBodyBytes   int64
}

// NewRouter returns the full HTTP handler.
func NewRouter(d Deps) http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.RequestID, middleware.AccessLog(d.Log), middleware.Recover(d.Log, handlers.WriteError))

	r.NotFound(func(w http.ResponseWriter, r *http.Request) {
		handlers.WriteError(w, r, http.StatusNotFound, "not_found", "no route for "+r.URL.Path)
	})
	r.MethodNotAllowed(func(w http.ResponseWriter, r *http.Request) {
		handlers.WriteError(w, r, http.StatusMethodNotAllowed, "method_not_allowed", r.Method+" not allowed")
	})

	r.Get("/health", handlers.Health)
	r.Get("/ready", handlers.Ready(d.DB))

	r.Route("/api/v1", func(r chi.Router) {
		r.Use(chimw.Timeout(d.RequestTimeout), middleware.APIKey(d.APIKeys, handlers.WriteError))
		dh := handlers.Diagnoses{Service: d.Diagnoses, Log: d.Log, MaxBodyBytes: d.MaxBodyBytes}
		r.Post("/diagnoses", dh.Create)
		r.Post("/diagnoses:sync", dh.Sync)
		r.Get("/diagnoses/{id}", dh.Get)
		r.Get("/devices/{device_id}/diagnoses", dh.History)
	})
	return r
}
