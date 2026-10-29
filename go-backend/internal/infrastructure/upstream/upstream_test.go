package upstream_test

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/advice"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/prediction"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/reqctx"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/domain/shared"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/infrastructure/upstream"
)

func kindOf(err error) shared.Kind {
	if de, ok := shared.As(err); ok {
		return de.Kind
	}
	return 0
}

func TestRAGSuccessForwardsRequestID(t *testing.T) {
	var gotID, gotBody string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotID = r.Header.Get("X-Request-ID")
		b, _ := io.ReadAll(r.Body)
		gotBody = string(b)
		_, _ = w.Write([]byte(`{"answer":"Remove infected plants [1].","grounded":true}`))
	}))
	defer srv.Close()

	ctx := reqctx.WithRequestID(context.Background(), "req-42")
	ans, err := upstream.NewRAG(srv.URL, time.Second).Ask(ctx, advice.Request{Question: "what now?", ClassName: "Potato___Late_blight"})
	if err != nil || !strings.Contains(string(ans.JSON), "grounded") {
		t.Fatalf("ask: %s %v", ans.JSON, err)
	}
	if gotID != "req-42" || !strings.Contains(gotBody, `"class_name":"Potato___Late_blight"`) {
		t.Fatalf("forwarded id %q body %s", gotID, gotBody)
	}
}

func TestUpstreamErrorsMapToDomainKinds(t *testing.T) {
	cases := []struct {
		name    string
		handler http.HandlerFunc
		kind    shared.Kind
		code    string
	}{
		{"validation passes through", func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(422)
			_, _ = w.Write([]byte(`{"error":"validation_error","detail":"bad","request_id":"x"}`))
		}, shared.KindInvalid, "validation_error"},
		{"llm down", func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(503)
			_, _ = w.Write([]byte(`{"error":"llm_unavailable","detail":"down"}`))
		}, shared.KindUnavailable, "advice_unavailable"},
		{"invalid json", func(w http.ResponseWriter, _ *http.Request) {
			_, _ = w.Write([]byte(`not json`))
		}, shared.KindUnavailable, "advice_unavailable"},
		{"timeout", func(w http.ResponseWriter, _ *http.Request) {
			time.Sleep(300 * time.Millisecond)
		}, shared.KindUnavailable, "advice_unavailable"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			srv := httptest.NewServer(c.handler)
			defer srv.Close()
			_, err := upstream.NewRAG(srv.URL, 100*time.Millisecond).Ask(context.Background(), advice.Request{Question: "q?"})
			de, ok := shared.As(err)
			if !ok || de.Kind != c.kind || de.Code != c.code {
				t.Fatalf("want %d/%s, got %v", c.kind, c.code, err)
			}
		})
	}
}

func TestUnreachableUpstreamIsUnavailable(t *testing.T) {
	srv := httptest.NewServer(http.NotFoundHandler())
	url := srv.URL
	srv.Close() // nothing listens any more: connection refused (retried once, then 503)
	_, err := upstream.NewML(url, time.Second).Predict(context.Background(),
		prediction.Image{Bytes: []byte("x"), ContentType: "image/jpeg"}, 3)
	if kindOf(err) != shared.KindUnavailable {
		t.Fatalf("want unavailable, got %v", err)
	}
	if upstream.NewML(url, time.Second).Ping(context.Background()) == nil {
		t.Fatal("ping must fail")
	}
}

func TestMLSendsMultipartFile(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		f, hdr, err := r.FormFile("file")
		if err != nil || hdr.Header.Get("Content-Type") != "image/jpeg" || r.URL.Query().Get("top_k") != "2" {
			w.WriteHeader(400)
			return
		}
		b, _ := io.ReadAll(f)
		_, _ = w.Write([]byte(`{"status":"ok","bytes":` + string(rune('0'+len(b))) + `}`))
	}))
	defer srv.Close()
	res, err := upstream.NewML(srv.URL, time.Second).Predict(context.Background(),
		prediction.Image{Bytes: []byte("abc"), ContentType: "image/jpeg", Filename: "leaf.jpg"}, 2)
	if err != nil || string(res.JSON) != `{"status":"ok","bytes":3}` {
		t.Fatalf("predict: %s %v", res.JSON, err)
	}
}
