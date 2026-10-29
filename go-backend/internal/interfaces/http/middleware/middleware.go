// Package middleware holds cross-cutting HTTP concerns: request id, access log,
// panic recovery and API-key authentication.
package middleware

import (
	"context"
	"crypto/rand"
	"crypto/subtle"
	"encoding/hex"
	"log/slog"
	"net/http"
	"time"
)

type ctxKey struct{}

// HeaderRequestID is shared with the Python services so one id follows a request everywhere.
const HeaderRequestID = "X-Request-ID"

// RequestID reuses the caller's X-Request-ID (e.g. from the app) or creates one,
// stores it in the context and echoes it in the response.
func RequestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.Header.Get(HeaderRequestID)
		if id == "" || len(id) > 128 {
			b := make([]byte, 16)
			_, _ = rand.Read(b)
			id = hex.EncodeToString(b)
		}
		w.Header().Set(HeaderRequestID, id)
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), ctxKey{}, id)))
	})
}

// GetRequestID returns the id stored by RequestID ("" if absent).
func GetRequestID(ctx context.Context) string {
	id, _ := ctx.Value(ctxKey{}).(string)
	return id
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (s *statusRecorder) WriteHeader(code int) {
	s.status = code
	s.ResponseWriter.WriteHeader(code)
}

// AccessLog writes one structured line per request.
func AccessLog(log *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
			next.ServeHTTP(rec, r)
			log.InfoContext(r.Context(), "request",
				"method", r.Method, "path", r.URL.Path, "status", rec.status,
				"ms", float64(time.Since(start).Microseconds())/1000, "request_id", GetRequestID(r.Context()))
		})
	}
}

// ErrorWriter writes the shared error JSON; injected to avoid an import cycle with handlers.
type ErrorWriter func(w http.ResponseWriter, r *http.Request, status int, code, detail string)

// Recover turns a panic into a 500 with the shared error shape and logs it.
func Recover(log *slog.Logger, writeErr ErrorWriter) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if v := recover(); v != nil {
					log.ErrorContext(r.Context(), "panic", "error", v, "request_id", GetRequestID(r.Context()))
					writeErr(w, r, http.StatusInternalServerError, "internal_error", "Unexpected server error")
				}
			}()
			next.ServeHTTP(w, r)
		})
	}
}

// APIKey requires a valid X-API-Key header. Comparison is constant-time so
// response timing does not leak how much of a key matched.
func APIKey(keys []string, writeErr ErrorWriter) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			got := []byte(r.Header.Get("X-API-Key"))
			for _, k := range keys {
				if subtle.ConstantTimeCompare(got, []byte(k)) == 1 {
					next.ServeHTTP(w, r)
					return
				}
			}
			writeErr(w, r, http.StatusUnauthorized, "unauthorized", "missing or invalid X-API-Key")
		})
	}
}
