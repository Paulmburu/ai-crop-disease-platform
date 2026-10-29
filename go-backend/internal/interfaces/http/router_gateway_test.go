package http_test

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/advice"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/modelrelease"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/prediction"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
	httpapi "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/interfaces/http"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/interfaces/http/handlers"
)

const sha123 = "a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3" // sha256("123")

// memStore is an ArtifactStore holding one file per version in memory.
type memStore map[string][]byte

func (m memStore) Describe(_ context.Context, v string) (string, int64, error) {
	b, ok := m[v]
	if !ok {
		return "", 0, shared.NotFound("artifact_not_found", v)
	}
	sum := sha256.Sum256(b)
	return hex.EncodeToString(sum[:]), int64(len(b)), nil
}

type nopSeeker struct{ *bytes.Reader }

func (nopSeeker) Close() error { return nil }

func (m memStore) Open(ctx context.Context, v string) (modelrelease.Artifact, error) {
	sum, size, err := m.Describe(ctx, v)
	return modelrelease.Artifact{Content: nopSeeker{bytes.NewReader(m[v])}, SizeBytes: size, Sha256: sum}, err
}

func releaseServer(t *testing.T) *httptest.Server {
	return newServerWith(t, func(d *httpapi.Deps) {
		d.Releases = modelrelease.NewService(modelrelease.NewMemoryRepository(), memStore{"v1": []byte("123")}, clock{})
		d.AdminAPIKeys = []string{"admin-key"}
	})
}

func send(t *testing.T, req *http.Request) (*http.Response, string) {
	t.Helper()
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	b, _ := io.ReadAll(resp.Body)
	return resp, string(b)
}

func TestModelReleaseLifecycle(t *testing.T) {
	srv := releaseServer(t)
	publish := `{"version":"v1","class_labels":["a","b","c"],"confidence_threshold":0.5,"input_shape":[1,224,224,3]}`

	if r, _ := do(t, srv, "GET", "/api/v1/model-releases/latest", "test-key", ""); r.StatusCode != 404 {
		t.Fatalf("latest before publish: %d", r.StatusCode)
	}
	if r, _ := do(t, srv, "POST", "/api/v1/model-releases", "test-key", publish); r.StatusCode != 401 {
		t.Fatalf("app key must not publish: %d", r.StatusCode)
	}
	r, b := do(t, srv, "POST", "/api/v1/model-releases", "admin-key", publish)
	if r.StatusCode != 201 || b["sha256"] != sha123 || b["size_bytes"] != 3.0 {
		t.Fatalf("publish: %d %v", r.StatusCode, b)
	}

	// latest + conditional GET
	r, b = do(t, srv, "GET", "/api/v1/model-releases/latest", "test-key", "")
	if r.StatusCode != 200 || r.Header.Get("ETag") != `"`+sha123+`"` || b["artifact_url"] != "/api/v1/model-releases/v1/artifact" {
		t.Fatalf("latest: %d %v %v", r.StatusCode, r.Header, b)
	}
	req, _ := http.NewRequest("GET", srv.URL+"/api/v1/model-releases/latest", nil)
	req.Header.Set("X-API-Key", "test-key")
	req.Header.Set("If-None-Match", r.Header.Get("ETag"))
	if r, _ := send(t, req); r.StatusCode != 304 {
		t.Fatalf("if-none-match: %d", r.StatusCode)
	}

	// full and ranged download
	req, _ = http.NewRequest("GET", srv.URL+"/api/v1/model-releases/v1/artifact", nil)
	req.Header.Set("X-API-Key", "test-key")
	if r, body := send(t, req); r.StatusCode != 200 || body != "123" || r.Header.Get("X-Checksum-Sha256") != sha123 {
		t.Fatalf("artifact: %d %q", r.StatusCode, body)
	}
	req.Header.Set("Range", "bytes=1-")
	if r, body := send(t, req); r.StatusCode != 206 || body != "23" {
		t.Fatalf("range: %d %q", r.StatusCode, body)
	}

	// withdraw hides the download
	if r, _ := do(t, srv, "DELETE", "/api/v1/model-releases/v1", "admin-key", ""); r.StatusCode != 204 {
		t.Fatalf("withdraw: %d", r.StatusCode)
	}
	if r, b := do(t, srv, "GET", "/api/v1/model-releases/v1/artifact", "test-key", ""); r.StatusCode != 404 || b["error"] != "release_withdrawn" {
		t.Fatalf("withdrawn artifact: %d %v", r.StatusCode, b)
	}
}

func TestAdminRoutesOffWithoutAdminKeys(t *testing.T) {
	srv := newServer(t, pinger{})
	if r, _ := do(t, srv, "POST", "/api/v1/model-releases", "test-key", "{}"); r.StatusCode != 405 && r.StatusCode != 404 {
		t.Fatalf("admin route must not exist: %d", r.StatusCode)
	}
}

// fakeUpstream stands in for the ML and RAG adapters (their HTTP mapping is
// tested in infrastructure/upstream).
type fakeUpstream struct {
	json string
	err  error
}

func (f fakeUpstream) Predict(context.Context, prediction.Image, int) (prediction.Result, error) {
	return prediction.Result{JSON: []byte(f.json)}, f.err
}
func (f fakeUpstream) Ask(context.Context, advice.Request) (advice.Answer, error) {
	return advice.Answer{JSON: []byte(f.json)}, f.err
}

func proxyServer(t *testing.T, ml, rag fakeUpstream) *httptest.Server {
	return newServerWith(t, func(d *httpapi.Deps) {
		d.Predictions = prediction.NewService(ml)
		d.Advice = advice.NewService(rag)
		d.Upstreams = map[string]handlers.Pinger{"ml_service": pinger{}, "rag_service": pinger{err: rag.err}}
	})
}

func postImage(t *testing.T, srv *httptest.Server, data []byte) (*http.Response, string) {
	var buf bytes.Buffer
	mw := multipart.NewWriter(&buf)
	h := make(map[string][]string)
	h["Content-Disposition"] = []string{`form-data; name="file"; filename="leaf.jpg"`}
	h["Content-Type"] = []string{"image/jpeg"}
	part, _ := mw.CreatePart(h)
	_, _ = part.Write(data)
	_ = mw.Close()
	req, _ := http.NewRequest("POST", srv.URL+"/api/v1/predictions", &buf)
	req.Header.Set("Content-Type", mw.FormDataContentType())
	req.Header.Set("X-API-Key", "test-key")
	return send(t, req)
}

func TestProxies(t *testing.T) {
	srv := proxyServer(t,
		fakeUpstream{json: `{"status":"ok","prediction":{"class_name":"Potato___Late_blight"}}`},
		fakeUpstream{err: shared.Unavailable("advice_unavailable", "RAG service returned 503")})

	if r, body := postImage(t, srv, []byte("jpeg-bytes")); r.StatusCode != 200 || !strings.Contains(body, "Potato___Late_blight") {
		t.Fatalf("predict: %d %s", r.StatusCode, body)
	}
	if r, _ := postImage(t, srv, bytes.Repeat([]byte("x"), 6<<20)); r.StatusCode != 413 {
		t.Fatalf("oversized image: %d", r.StatusCode)
	}
	if r, b := do(t, srv, "POST", "/api/v1/advice", "test-key", `{"question":"what should I spray?"}`); r.StatusCode != 503 || b["error"] != "advice_unavailable" {
		t.Fatalf("advice with RAG down: %d %v", r.StatusCode, b)
	}
	if r, b := do(t, srv, "POST", "/api/v1/advice", "test-key", `{"question":"?"}`); r.StatusCode != 422 {
		t.Fatalf("short question: %d %v", r.StatusCode, b)
	}
	r, b := do(t, srv, "GET", "/ready", "", "")
	if r.StatusCode != 200 || b["database"] != true || b["ml_service"] != true || b["rag_service"] != false {
		t.Fatalf("ready: %d %v", r.StatusCode, b)
	}
}

func TestAdviceUpstreamValidationPassesThrough(t *testing.T) {
	srv := proxyServer(t, fakeUpstream{}, fakeUpstream{err: shared.Invalid("validation_error", "class_name unknown")})
	r, b := do(t, srv, "POST", "/api/v1/advice", "test-key", `{"question":"what now?","class_name":"Tomato"}`)
	if r.StatusCode != 422 || b["error"] != "validation_error" {
		t.Fatalf("passthrough: %d %v", r.StatusCode, b)
	}
}
