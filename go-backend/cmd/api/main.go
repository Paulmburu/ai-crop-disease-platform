// Command api is the composition root: the only place that knows concrete types.
// It wires config → logger → database → repositories → use cases → HTTP router,
// then serves until SIGINT/SIGTERM and drains in-flight requests.
package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/advice"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/diagnosis"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/modelrelease"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/application/prediction"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/infrastructure/config"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/infrastructure/filestore"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/infrastructure/observability"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/infrastructure/postgres"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/infrastructure/upstream"
	httpapi "github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/interfaces/http"
	"github.com/Paulmburu/ai-crop-disease-platform/go-backend/internal/interfaces/http/handlers"
)

type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now() }

func main() {
	// `api healthcheck` lets Docker probe the distroless image (no shell or curl inside).
	if len(os.Args) > 1 && os.Args[1] == "healthcheck" {
		os.Exit(healthcheck())
	}
	if err := run(); err != nil {
		slog.Error("fatal", "error", err)
		os.Exit(1)
	}
}

func healthcheck() int {
	addr := os.Getenv("HTTP_ADDR")
	if addr == "" {
		addr = ":8080"
	}
	client := http.Client{Timeout: 3 * time.Second}
	resp, err := client.Get("http://127.0.0.1" + addr + "/health")
	if err != nil || resp.StatusCode != http.StatusOK {
		return 1
	}
	_ = resp.Body.Close()
	return 0
}

// seedReleases publishes every exported model found in MODELS_DIR that is not
// published yet (crop_disease_<v>.tflite + .json from export_tflite.py). A
// missing or empty folder is fine: the API then reports "no release".
func seedReleases(ctx context.Context, log *slog.Logger, store *filestore.Store, svc *modelrelease.Service) {
	found, err := store.Discover()
	if err != nil {
		log.Warn("model seed: cannot read models dir", "error", err)
		return
	}
	for _, in := range found {
		created, err := svc.PublishIfAbsent(ctx, in)
		switch {
		case err != nil:
			log.Warn("model seed failed", "version", in.Version, "error", err)
		case created:
			log.Info("model release published from models dir", "version", in.Version)
		}
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	log := observability.NewLogger(os.Stdout, cfg.LogLevel)
	log.Info("starting", "config", cfg.String())

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	startCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	pool, err := postgres.Connect(startCtx, cfg.DatabaseURL) // fail fast if the DB is unreachable
	if err != nil {
		return err
	}
	defer pool.Close()
	if err := postgres.Migrate(startCtx, pool); err != nil {
		return err
	}

	clock := systemClock{}
	store := filestore.New(cfg.ModelsDir)
	releases := modelrelease.NewService(postgres.NewModelReleaseRepository(pool), store, clock)
	seedReleases(startCtx, log, store, releases)
	ml := upstream.NewML(cfg.MLServiceURL, cfg.PredictTimeout)
	rag := upstream.NewRAG(cfg.RAGServiceURL, cfg.AdviceTimeout)

	srv := &http.Server{
		Addr: cfg.HTTPAddr,
		Handler: httpapi.NewRouter(httpapi.Deps{
			Log:            log,
			DB:             pool,
			Upstreams:      map[string]handlers.Pinger{"ml_service": ml, "rag_service": rag},
			Diagnoses:      diagnosis.NewService(postgres.NewDiagnosisRepository(pool), clock),
			Releases:       releases,
			Predictions:    prediction.NewService(ml),
			Advice:         advice.NewService(rag),
			APIKeys:        cfg.APIKeys,
			AdminAPIKeys:   cfg.AdminAPIKeys,
			RequestTimeout: cfg.RequestTimeout,
			MaxBodyBytes:   cfg.MaxBodyBytes,
		}),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       60 * time.Second, // 5 MB image uploads on slow links
		// Must outlast the slowest handler: an LLM answer, or a model download on 2G.
		WriteTimeout: max(cfg.AdviceTimeout, 10*time.Minute) + 5*time.Second,
		IdleTimeout:  60 * time.Second,
	}

	errCh := make(chan error, 1)
	go func() {
		log.Info("listening", "addr", cfg.HTTPAddr)
		if err := srv.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
			errCh <- err
		}
	}()

	select {
	case err := <-errCh:
		return err
	case <-ctx.Done():
	}
	log.Info("shutting down", "drain", cfg.ShutdownTimeout.String())
	shutdownCtx, cancelShutdown := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
	defer cancelShutdown()
	return srv.Shutdown(shutdownCtx)
}
