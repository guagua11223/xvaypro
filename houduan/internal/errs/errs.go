package errs

import "strings"

type HTTP struct {
	Status  int
	Code    string
	Message string
}

func (e *HTTP) Error() string { return e.Message }

func New(status int, code, message string) *HTTP {
	return &HTTP{Status: status, Code: code, Message: message}
}

func IsUnique(err error) bool {
	return err != nil && strings.Contains(err.Error(), "UNIQUE constraint failed")
}
