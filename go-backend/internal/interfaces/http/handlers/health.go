package handlers

import (
	"context"
	"net/http"
	"sync"
	"time"
)

// Pinger checks a dependency (the database pool and the upstream clients satisfy it).
type Pinger interface {
	Ping(ctx context.Context) error
}

// Health: liveness, 200 while the process runs.
func Health(w http.ResponseWriter, _ *http.Request) {
	WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// Ready: 200 when the database answers (required). Optional dependencies (ML and
// RAG services) are reported but do not fail readiness: the app uses them to
// decide which online features to enable.
func Ready(db Pinger, optional map[string]Pinger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()
		body := map[string]any{"database": db.Ping(ctx) == nil}
		var mu sync.Mutex
		var wg sync.WaitGroup
		for name, p := range optional { // probe in parallel: /ready stays fast
			wg.Add(1)
			go func() {
				defer wg.Done()
				ok := p != nil && p.Ping(ctx) == nil
				mu.Lock()
				body[name] = ok
				mu.Unlock()
			}()
		}
		wg.Wait()
		if body["database"] != true {
			body["status"] = "not_ready"
			WriteJSON(w, http.StatusServiceUnavailable, body)
			return
		}
		body["status"] = "ready"
		WriteJSON(w, http.StatusOK, body)
	}
}
