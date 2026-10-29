// Package reqctx carries the request id through context so every layer (HTTP
// middleware, outbound clients, logs) can use it without depending on each other.
package reqctx

import "context"

type key struct{}

func WithRequestID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, key{}, id)
}

func RequestID(ctx context.Context) string {
	id, _ := ctx.Value(key{}).(string)
	return id
}
