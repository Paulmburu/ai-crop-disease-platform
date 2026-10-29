// Package config reads settings from environment variables once at startup.
package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	Env             string        // development | production
	HTTPAddr        string        // e.g. ":8080"
	DatabaseURL     string        // postgres://user:pass@host:5432/db?sslmode=disable
	APIKeys         []string      // accepted X-API-Key values (comma-separated in env)
	LogLevel        string        // debug | info | warn | error
	RequestTimeout  time.Duration // per-request handler timeout
	ShutdownTimeout time.Duration // drain time on SIGTERM
	MaxBodyBytes    int64

	AdminAPIKeys   []string      // keys for publishing/withdrawing models (empty = admin API off)
	ModelsDir      string        // folder with crop_disease_<version>.tflite + .json
	MLServiceURL   string        // python-ml-service base URL
	RAGServiceURL  string        // rag-service base URL
	PredictTimeout time.Duration // upstream timeout for /predictions
	AdviceTimeout  time.Duration // upstream timeout for /advice (local LLMs are slow when cold)
}

// Load reads the environment and validates it. Missing required values fail startup.
func Load() (Config, error) {
	c := Config{
		Env:             get("APP_ENV", "development"),
		HTTPAddr:        get("HTTP_ADDR", ":8080"),
		DatabaseURL:     os.Getenv("DATABASE_URL"),
		LogLevel:        get("LOG_LEVEL", "info"),
		RequestTimeout:  duration("REQUEST_TIMEOUT", 15*time.Second),
		ShutdownTimeout: duration("SHUTDOWN_TIMEOUT", 10*time.Second),
		MaxBodyBytes:    int64(integer("MAX_BODY_BYTES", 1<<20)),
	}
	c.APIKeys = list("API_KEYS")
	c.AdminAPIKeys = list("ADMIN_API_KEYS")
	c.ModelsDir = get("MODELS_DIR", "models")
	c.MLServiceURL = strings.TrimRight(get("ML_SERVICE_URL", "http://localhost:8000"), "/")
	c.RAGServiceURL = strings.TrimRight(get("RAG_SERVICE_URL", "http://localhost:8001"), "/")
	c.PredictTimeout = duration("PREDICT_TIMEOUT", 10*time.Second)
	c.AdviceTimeout = duration("ADVICE_TIMEOUT", 60*time.Second)
	var errs []error
	if c.DatabaseURL == "" {
		errs = append(errs, errors.New("DATABASE_URL is required"))
	}
	if len(c.APIKeys) == 0 {
		errs = append(errs, errors.New("API_KEYS is required (comma-separated)"))
	}
	return c, errors.Join(errs...)
}

func list(key string) []string {
	var out []string
	for _, k := range strings.Split(os.Getenv(key), ",") {
		if k = strings.TrimSpace(k); k != "" {
			out = append(out, k)
		}
	}
	return out
}

func get(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func duration(key string, def time.Duration) time.Duration {
	if d, err := time.ParseDuration(os.Getenv(key)); err == nil {
		return d
	}
	return def
}

func integer(key string, def int) int {
	if n, err := strconv.Atoi(os.Getenv(key)); err == nil {
		return n
	}
	return def
}

// String hides secrets so the config can be logged safely.
func (c Config) String() string {
	return fmt.Sprintf("env=%s addr=%s api_keys=%d admin_keys=%d models_dir=%s ml=%s rag=%s",
		c.Env, c.HTTPAddr, len(c.APIKeys), len(c.AdminAPIKeys), c.ModelsDir, c.MLServiceURL, c.RAGServiceURL)
}
