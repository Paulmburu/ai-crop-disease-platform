package http_test

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	app "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/diagnosis"
	httpapi "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/interfaces/http"
)

type clock struct{}

func (clock) Now() time.Time { return time.Date(2026, 10, 30, 12, 0, 0, 0, time.UTC) }

type pinger struct{ err error }

func (p pinger) Ping(context.Context) error { return p.err }

func newServer(t *testing.T, db pinger) *httptest.Server {
	t.Helper()
	srv := httptest.NewServer(httpapi.NewRouter(httpapi.Deps{
		Log:            slog.New(slog.NewTextHandler(io.Discard, nil)),
		DB:             db,
		Diagnoses:      app.NewService(app.NewMemoryRepository(), clock{}),
		APIKeys:        []string{"test-key"},
		RequestTimeout: 5 * time.Second,
		MaxBodyBytes:   1 << 10,
	}))
	t.Cleanup(srv.Close)
	return srv
}

const body = `{"id":"6f1c2b9e-3d4a-4f5b-9c8d-7e6f5a4b3c2d","device_id":"device-1",
 "class_label":"Potato___Late_blight","confidence":0.93,"confidence_threshold":0.5,
 "model_version":"v1","captured_at":"2026-10-30T11:00:00Z"}`

func do(t *testing.T, srv *httptest.Server, method, path, key, payload string) (*http.Response, map[string]any) {
	t.Helper()
	req, _ := http.NewRequest(method, srv.URL+path, strings.NewReader(payload))
	if key != "" {
		req.Header.Set("X-API-Key", key)
	}
	req.Header.Set("X-Request-ID", "req-1")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	var out map[string]any
	_ = json.NewDecoder(resp.Body).Decode(&out)
	return resp, out
}

func TestHealthAndReady(t *testing.T) {
	ok := newServer(t, pinger{})
	if r, _ := do(t, ok, "GET", "/health", "", ""); r.StatusCode != 200 {
		t.Fatalf("health: %d", r.StatusCode)
	}
	if r, _ := do(t, ok, "GET", "/ready", "", ""); r.StatusCode != 200 {
		t.Fatalf("ready: %d", r.StatusCode)
	}
	down := newServer(t, pinger{err: errors.New("db down")})
	if r, _ := do(t, down, "GET", "/ready", "", ""); r.StatusCode != 503 {
		t.Fatalf("ready with db down: %d", r.StatusCode)
	}
}

func TestCreateIsIdempotentAndGetReturnsIt(t *testing.T) {
	srv := newServer(t, pinger{})
	r1, b1 := do(t, srv, "POST", "/api/v1/diagnoses", "test-key", body)
	r2, b2 := do(t, srv, "POST", "/api/v1/diagnoses", "test-key", body)
	if r1.StatusCode != 201 || r2.StatusCode != 200 {
		t.Fatalf("want 201 then 200, got %d then %d", r1.StatusCode, r2.StatusCode)
	}
	if b1["status"] != "ok" || b1["id"] != b2["id"] {
		t.Fatalf("unexpected bodies: %v / %v", b1, b2)
	}
	r3, b3 := do(t, srv, "GET", "/api/v1/diagnoses/6f1c2b9e-3d4a-4f5b-9c8d-7e6f5a4b3c2d", "test-key", "")
	if r3.StatusCode != 200 || b3["class_label"] != "Potato___Late_blight" {
		t.Fatalf("get: %d %v", r3.StatusCode, b3)
	}
}

func TestErrorsUseSharedShape(t *testing.T) {
	srv := newServer(t, pinger{})
	cases := []struct {
		name, method, path, key, payload string
		status                           int
		code                             string
	}{
		{"no key", "POST", "/api/v1/diagnoses", "", body, 401, "unauthorized"},
		{"wrong key", "POST", "/api/v1/diagnoses", "nope", body, 401, "unauthorized"},
		{"bad json", "POST", "/api/v1/diagnoses", "test-key", "{", 400, "bad_request"},
		{"unknown field", "POST", "/api/v1/diagnoses", "test-key", `{"status":"ok"}`, 400, "bad_request"},
		{"invariant", "POST", "/api/v1/diagnoses", "test-key", strings.Replace(body, "0.93", "1.5", 1), 422, "invalid_confidence"},
		{"too large", "POST", "/api/v1/diagnoses", "test-key", `{"id":"` + strings.Repeat("x", 2048) + `"}`, 413, "payload_too_large"},
		{"not found", "GET", "/api/v1/diagnoses/00000000-0000-0000-0000-000000000000", "test-key", "", 404, "diagnosis_not_found"},
		{"no route", "GET", "/nope", "", "", 404, "not_found"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			resp, b := do(t, srv, c.method, c.path, c.key, c.payload)
			if resp.StatusCode != c.status || b["error"] != c.code || b["request_id"] != "req-1" {
				t.Fatalf("want %d %s, got %d %v", c.status, c.code, resp.StatusCode, b)
			}
			if resp.Header.Get("X-Request-ID") != "req-1" {
				t.Fatal("X-Request-ID not echoed")
			}
		})
	}
}

func diag(id, captured string) string {
	return `{"id":"` + id + `","device_id":"device-9","class_label":"Potato___Early_blight","confidence":0.8,` +
		`"confidence_threshold":0.5,"model_version":"v1","captured_at":"` + captured + `"}`
}

func TestSyncAndHistory(t *testing.T) {
	srv := newServer(t, pinger{})
	batch := `{"items":[` +
		diag("00000000-0000-4000-8000-000000000001", "2026-10-30T10:00:00Z") + `,` +
		diag("00000000-0000-4000-8000-000000000002", "2026-10-30T11:00:00Z") + `,` +
		diag("00000000-0000-4000-8000-000000000003", "2026-10-30T09:00:00Z") + `,` +
		`{"id":"bad","device_id":"device-9","class_label":"x","confidence":0.8,"confidence_threshold":0.5,"model_version":"v1","captured_at":"2026-10-30T09:00:00Z"}` +
		`]}`
	r, b := do(t, srv, "POST", "/api/v1/diagnoses:sync", "test-key", batch)
	if r.StatusCode != 200 || b["created"] != 3.0 || b["invalid"] != 1.0 {
		t.Fatalf("first sync: %d %v", r.StatusCode, b)
	}
	_, b = do(t, srv, "POST", "/api/v1/diagnoses:sync", "test-key", batch)
	if b["duplicate"] != 3.0 || b["created"] != 0.0 {
		t.Fatalf("resync must be all duplicate: %v", b)
	}

	_, page1 := do(t, srv, "GET", "/api/v1/devices/device-9/diagnoses?limit=2", "test-key", "")
	items := page1["items"].([]any)
	if len(items) != 2 || items[0].(map[string]any)["id"] != "00000000-0000-4000-8000-000000000002" {
		t.Fatalf("page 1 not newest first: %v", page1)
	}
	cursor, _ := page1["next_cursor"].(string)
	_, page2 := do(t, srv, "GET", "/api/v1/devices/device-9/diagnoses?limit=2&cursor="+cursor, "test-key", "")
	if len(page2["items"].([]any)) != 1 || page2["next_cursor"] != nil {
		t.Fatalf("page 2: %v", page2)
	}
	if r, b := do(t, srv, "GET", "/api/v1/devices/device-9/diagnoses?cursor=bm90LWEtY3Vyc29y", "test-key", ""); r.StatusCode != 400 || b["error"] != "invalid_cursor" {
		t.Fatalf("bad cursor: %d %v", r.StatusCode, b)
	}
	if r, b := do(t, srv, "POST", "/api/v1/diagnoses:sync", "test-key", `{"items":[]}`); r.StatusCode != 422 || b["error"] != "empty_batch" {
		t.Fatalf("empty batch: %d %v", r.StatusCode, b)
	}
}
