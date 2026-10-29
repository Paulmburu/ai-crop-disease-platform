// Package advice is the Advice context: grounded, source-cited answers about a
// disease, produced by the RAG service behind the Provider port.
package advice

import (
	"context"
	"strings"
	"unicode/utf8"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

// Request is a farmer's question, optionally scoped to the classifier's label.
type Request struct {
	Question  string
	ClassName string // e.g. "Potato___Late_blight"; empty = free question
}

// Answer is passed through to the app unchanged (answer, sources, grounded, ...);
// the backend does not reinterpret the RAG service's response.
type Answer struct{ JSON []byte }

// Provider is the port to the RAG service (implemented in infrastructure/upstream).
// It returns shared errors: KindInvalid for rejected input, KindUnavailable when down.
type Provider interface {
	Ask(ctx context.Context, req Request) (Answer, error)
}

type Service struct{ provider Provider }

func NewService(p Provider) *Service { return &Service{provider: p} }

// Ask validates the question locally (fail fast, no upstream call) and forwards it.
func (s *Service) Ask(ctx context.Context, req Request) (Answer, error) {
	req.Question = strings.TrimSpace(req.Question)
	n := utf8.RuneCountInString(req.Question)
	switch {
	case n < 3 || n > 500:
		return Answer{}, shared.Invalid("invalid_question", "question must be 3-500 characters")
	case len(req.ClassName) > 100:
		return Answer{}, shared.Invalid("invalid_class_name", "class_name is too long")
	}
	return s.provider.Ask(ctx, req)
}
