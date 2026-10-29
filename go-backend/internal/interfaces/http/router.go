// Package http wires routes and middleware. Handlers live in ./handlers.
package http

import (
	"log/slog"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/advice"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/diagnosis"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/modelrelease"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/prediction"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/interfaces/http/handlers"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/interfaces/http/middleware"
)

// Deps are everything the HTTP layer needs; built in cmd/api/main.go.
type Deps struct {
	Log            *slog.Logger
	DB             handlers.Pinger
	Upstreams      map[string]handlers.Pinger // reported in /ready, e.g. "ml_service", "rag_service"
	Diagnoses      *diagnosis.Service
	Releases       *modelrelease.Service
	Predictions    *prediction.Service
	Advice         *advice.Service
	APIKeys        []string
	AdminAPIKeys   []string // empty = admin endpoints disabled
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
	r.Get("/ready", handlers.Ready(d.DB, d.Upstreams))

	dh := handlers.Diagnoses{Service: d.Diagnoses, Log: d.Log, MaxBodyBytes: d.MaxBodyBytes}
	mh := handlers.ModelReleases{Service: d.Releases, Log: d.Log, MaxBodyBytes: d.MaxBodyBytes}
	ph := handlers.Proxies{Predictions: d.Predictions, Advice: d.Advice, Log: d.Log}

	r.Route("/api/v1", func(r chi.Router) {
		// App endpoints (phone API key).
		r.Group(func(r chi.Router) {
			r.Use(middleware.APIKey(d.APIKeys, handlers.WriteError))
			r.Group(func(r chi.Router) {
				r.Use(chimw.Timeout(d.RequestTimeout)) // local work: short timeout
				r.Post("/diagnoses", dh.Create)
				r.Post("/diagnoses:sync", dh.Sync)
				r.Get("/diagnoses/{id}", dh.Get)
				r.Get("/devices/{device_id}/diagnoses", dh.History)
				r.Get("/model-releases/latest", mh.Latest)
			})
			// No handler timeout: downloads on 2G and LLM answers are bounded by
			// the server write timeout and the upstream client timeouts instead.
			r.Get("/model-releases/{version}/artifact", mh.Artifact)
			r.Post("/predictions", ph.Predict)
			r.Post("/advice", ph.Ask)
		})
		// Admin endpoints (separate keys).
		if len(d.AdminAPIKeys) > 0 {
			r.Group(func(r chi.Router) {
				r.Use(chimw.Timeout(d.RequestTimeout), middleware.APIKey(d.AdminAPIKeys, handlers.WriteError))
				r.Post("/model-releases", mh.Publish)
				r.Delete("/model-releases/{version}", mh.Withdraw)
			})
		}
	})
	return r
}
