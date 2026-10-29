// Package prediction forwards a leaf photo to the server-side classifier (the
// online path; the phone normally classifies on-device).
package prediction

import (
	"context"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

// MaxImageBytes matches the ML service's upload limit.
const MaxImageBytes = 5 << 20

var allowedTypes = map[string]bool{"image/jpeg": true, "image/png": true, "image/webp": true}

type Image struct {
	Bytes       []byte
	ContentType string
	Filename    string
}

// Result is the ML service's JSON, passed through unchanged.
type Result struct{ JSON []byte }

// Predictor is the port to the ML service.
type Predictor interface {
	Predict(ctx context.Context, img Image, topK int) (Result, error)
}

type Service struct{ predictor Predictor }

func NewService(p Predictor) *Service { return &Service{predictor: p} }

func (s *Service) Predict(ctx context.Context, img Image, topK int) (Result, error) {
	switch {
	case len(img.Bytes) == 0:
		return Result{}, shared.Invalid("empty_image", "image is empty")
	case len(img.Bytes) > MaxImageBytes:
		return Result{}, shared.Invalid("image_too_large", "image exceeds 5 MB")
	case !allowedTypes[img.ContentType]:
		return Result{}, shared.Invalid("unsupported_media_type", "image must be JPEG, PNG or WebP")
	}
	if topK < 1 || topK > 10 {
		topK = 3
	}
	return s.predictor.Predict(ctx, img, topK)
}
