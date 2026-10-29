// Package observability builds the structured logger (log/slog, JSON lines).
package observability

import (
	"io"
	"log/slog"
	"strings"
)

// NewLogger returns a JSON slog logger at the given level ("debug", "info", "warn", "error").
func NewLogger(w io.Writer, level string) *slog.Logger {
	var l slog.Level
	if err := l.UnmarshalText([]byte(strings.ToUpper(level))); err != nil {
		l = slog.LevelInfo
	}
	return slog.New(slog.NewJSONHandler(w, &slog.HandlerOptions{Level: l})).With("service", "go-backend")
}
