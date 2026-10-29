// Package shared holds domain building blocks used by every bounded context.
// It depends only on the standard library.
package shared

import (
	"errors"
	"fmt"
)

// Kind classifies a domain error. The HTTP layer maps kinds to status codes;
// the domain never knows about HTTP.
type Kind int

const (
	KindInvalid  Kind = iota + 1 // input breaks an invariant
	KindNotFound                 // aggregate does not exist
	KindConflict                 // state does not allow the operation
)

// Error is the single error type returned by domain and application code.
type Error struct {
	Kind    Kind
	Code    string // stable, machine-readable, e.g. "invalid_confidence"
	Message string // human-readable detail
}

func (e *Error) Error() string { return fmt.Sprintf("%s: %s", e.Code, e.Message) }

// Invalid, NotFound and Conflict build domain errors.
func Invalid(code, msg string) *Error  { return &Error{Kind: KindInvalid, Code: code, Message: msg} }
func NotFound(code, msg string) *Error { return &Error{Kind: KindNotFound, Code: code, Message: msg} }
func Conflict(code, msg string) *Error { return &Error{Kind: KindConflict, Code: code, Message: msg} }

// As returns the domain error wrapped in err, if any.
func As(err error) (*Error, bool) {
	var de *Error
	ok := errors.As(err, &de)
	return de, ok
}
