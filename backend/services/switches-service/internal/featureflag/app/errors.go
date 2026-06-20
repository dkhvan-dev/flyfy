package app

import (
	"errors"
	"net/http"
)

var (
	ErrFeatureFlagAlreadyExists = errors.New("Фича флаг с кодом уже существует")
	ErrFeatureFlagNotFound      = errors.New("Фича флаг с кодом не найден")
	ErrDomainAlreadyExists      = errors.New("Домен/продукт с таким кодом уже существует")
	ErrDomainNotFound           = errors.New("Домен/продукт не найден")
	ErrForbidden                = errors.New("access denied")
)

type AppError struct {
	Status  int
	Message string
	Err     error
}

func (e *AppError) Error() string {
	if e.Message != "" {
		return e.Message
	}
	if e.Err != nil {
		return e.Err.Error()
	}
	return "application error"
}

func (e *AppError) Unwrap() error {
	return e.Err
}

func BadRequest(message string) error {
	return &AppError{Status: http.StatusBadRequest, Message: message}
}

func Conflict(err error) error {
	return &AppError{Status: http.StatusConflict, Message: err.Error(), Err: err}
}

func NotFound(err error) error {
	return &AppError{Status: http.StatusNotFound, Message: err.Error(), Err: err}
}

func Forbidden(message string) error {
	return &AppError{Status: http.StatusForbidden, Message: message, Err: ErrForbidden}
}
