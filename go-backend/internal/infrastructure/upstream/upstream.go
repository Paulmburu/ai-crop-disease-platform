// Package upstream holds HTTP adapters to the Python services. They implement
// the application ports (advice.Provider, prediction.Predictor) and translate
// upstream failures into domain errors, so the HTTP layer treats them uniformly.
package upstream

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"net"
	"net/http"
	"net/textproto"
	"strconv"
	"time"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/advice"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/prediction"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/reqctx"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
)

const maxResponseBytes = 1 << 20

// client is the shared plumbing: base URL, timeout, request id, retry, error mapping.
type client struct {
	base            string
	http            *http.Client
	unavailableCode string // e.g. "advice_unavailable"
	name            string // for messages, e.g. "RAG service"
}

func newClient(base string, timeout time.Duration, unavailableCode, name string) client {
	return client{base: base, http: &http.Client{Timeout: timeout}, unavailableCode: unavailableCode, name: name}
}

// do sends the request built by newReq (called again for the one retry, because a
// request body can only be read once). Only connection failures are retried: a
// timeout may mean the upstream is still working, and retrying would double the load.
func (c client) do(ctx context.Context, newReq func() (*http.Request, error)) ([]byte, error) {
	var resp *http.Response
	var err error
	for attempt := 0; attempt < 2; attempt++ {
		var req *http.Request
		if req, err = newReq(); err != nil {
			return nil, err
		}
		req = req.WithContext(ctx)
		if id := reqctx.RequestID(ctx); id != "" {
			req.Header.Set("X-Request-ID", id)
		}
		resp, err = c.http.Do(req)
		if err == nil || !isConnRefused(err) || ctx.Err() != nil {
			break
		}
	}
	if err != nil {
		return nil, shared.Unavailable(c.unavailableCode, c.name+" is not reachable")
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, maxResponseBytes))
	if err != nil {
		return nil, shared.Unavailable(c.unavailableCode, c.name+" response could not be read")
	}

	switch {
	case resp.StatusCode >= 200 && resp.StatusCode < 300:
		if !json.Valid(body) {
			return nil, shared.Unavailable(c.unavailableCode, c.name+" returned invalid JSON")
		}
		return body, nil
	case resp.StatusCode >= 400 && resp.StatusCode < 500:
		// The Python services use the same error shape; keep their code and detail.
		var e struct {
			Error  string `json:"error"`
			Detail any    `json:"detail"`
		}
		_ = json.Unmarshal(body, &e)
		if e.Error == "" {
			e.Error = "upstream_rejected"
		}
		return nil, shared.Invalid(e.Error, fmt.Sprint(e.Detail))
	default: // 5xx, including 503 when the model or LLM is not ready
		return nil, shared.Unavailable(c.unavailableCode, c.name+" returned "+strconv.Itoa(resp.StatusCode))
	}
}

func isConnRefused(err error) bool {
	var opErr *net.OpError
	return errors.As(err, &opErr) && opErr.Op == "dial"
}

// Ping reports whether the upstream's /ready answers 200 within 2 s.
func (c client) Ping(ctx context.Context) error {
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.base+"/ready", nil)
	if err != nil {
		return err
	}
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	_ = resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("%s not ready: %d", c.name, resp.StatusCode)
	}
	return nil
}

// RAG implements advice.Provider against rag-service POST /api/v1/ask.
type RAG struct{ client }

func NewRAG(baseURL string, timeout time.Duration) *RAG {
	return &RAG{newClient(baseURL, timeout, "advice_unavailable", "RAG service")}
}

var _ advice.Provider = (*RAG)(nil)

func (r *RAG) Ask(ctx context.Context, q advice.Request) (advice.Answer, error) {
	payload := map[string]any{"question": q.Question}
	if q.ClassName != "" {
		payload["class_name"] = q.ClassName
	}
	body, _ := json.Marshal(payload)
	out, err := r.do(ctx, func() (*http.Request, error) {
		req, err := http.NewRequest(http.MethodPost, r.base+"/api/v1/ask", bytes.NewReader(body))
		if err == nil {
			req.Header.Set("Content-Type", "application/json")
		}
		return req, err
	})
	return advice.Answer{JSON: out}, err
}

// ML implements prediction.Predictor against python-ml-service POST /api/v1/predict.
type ML struct{ client }

func NewML(baseURL string, timeout time.Duration) *ML {
	return &ML{newClient(baseURL, timeout, "prediction_unavailable", "ML service")}
}

var _ prediction.Predictor = (*ML)(nil)

func (m *ML) Predict(ctx context.Context, img prediction.Image, topK int) (prediction.Result, error) {
	var buf bytes.Buffer
	mw := multipart.NewWriter(&buf)
	h := textproto.MIMEHeader{}
	name := img.Filename
	if name == "" {
		name = "leaf"
	}
	h.Set("Content-Disposition", fmt.Sprintf(`form-data; name="file"; filename=%q`, name))
	h.Set("Content-Type", img.ContentType)
	part, err := mw.CreatePart(h)
	if err != nil {
		return prediction.Result{}, err
	}
	if _, err := part.Write(img.Bytes); err != nil {
		return prediction.Result{}, err
	}
	if err := mw.Close(); err != nil {
		return prediction.Result{}, err
	}
	payload := buf.Bytes()
	out, err := m.do(ctx, func() (*http.Request, error) {
		req, err := http.NewRequest(http.MethodPost, m.base+"/api/v1/predict?top_k="+strconv.Itoa(topK), bytes.NewReader(payload))
		if err == nil {
			req.Header.Set("Content-Type", mw.FormDataContentType())
		}
		return req, err
	})
	return prediction.Result{JSON: out}, err
}
