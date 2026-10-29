package internal_test

// Enforces the DDD dependency rule (see AGENTS.md): inner layers never import outer ones.

import (
	"go/parser"
	"go/token"
	"io/fs"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

const module = "github.com/Paulmburu/ai-crop-disease-platform/go-backend/"

var forbidden = map[string][]string{
	"domain":      {"internal/application", "internal/infrastructure", "internal/interfaces", "net/http", "database/sql", "github.com/jackc", "github.com/go-chi"},
	"application": {"internal/infrastructure", "internal/interfaces", "net/http", "database/sql", "github.com/jackc", "github.com/go-chi"},
	"interfaces":  {"internal/infrastructure"},
}

func TestLayerDependencies(t *testing.T) {
	for layer, banned := range forbidden {
		err := filepath.WalkDir(layer, func(path string, d fs.DirEntry, err error) error {
			if err != nil || d.IsDir() || !strings.HasSuffix(path, ".go") {
				return err
			}
			f, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
			if err != nil {
				return err
			}
			for _, imp := range f.Imports {
				p, _ := strconv.Unquote(imp.Path.Value)
				for _, b := range banned {
					if strings.HasPrefix(p, b) || strings.HasPrefix(p, module+b) {
						t.Errorf("%s: layer %q must not import %q", path, layer, p)
					}
				}
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
}
