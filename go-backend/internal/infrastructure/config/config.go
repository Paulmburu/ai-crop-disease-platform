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
	for _, k := range strings.Split(os.Getenv("API_KEYS"), ",") {
		if k = strings.TrimSpace(k); k != "" {
			c.APIKeys = append(c.APIKeys, k)
		}
	}
	var errs []error
	if c.DatabaseURL == "" {
		errs = append(errs, errors.New("DATABASE_URL is required"))
	}
	if len(c.APIKeys) == 0 {
		errs = append(errs, errors.New("API_KEYS is required (comma-separated)"))
	}
	return c, errors.Join(errs...)
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
	return fmt.Sprintf("env=%s addr=%s api_keys=%d timeout=%s", c.Env, c.HTTPAddr, len(c.APIKeys), c.RequestTimeout)
}
