// Package migrations embeds the SQL files so the binary migrates the database itself.
package migrations

import "embed"

//go:embed *.sql
var FS embed.FS
