package handlers

import (
	"context"
	"net/http"
	"time"
)

// Pinger checks a dependency (the database pool satisfies it).
type Pinger interface {
	Ping(ctx context.Context) error
}

// Health: liveness, 200 while the process runs.
func Health(w http.ResponseWriter, _ *http.Request) {
	WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// Ready: 200 only when the database answers within 2 s, else 503.
func Ready(db Pinger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()
		if err := db.Ping(ctx); err != nil {
			WriteJSON(w, http.StatusServiceUnavailable, map[string]any{"status": "not_ready", "database": false})
			return
		}
		WriteJSON(w, http.StatusOK, map[string]any{"status": "ready", "database": true})
	}
}
