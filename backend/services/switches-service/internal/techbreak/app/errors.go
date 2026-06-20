package app

import (
	"errors"
	"net/http"
)

var (
	ErrBreakScopesMustBeEmpty        = errors.New("Переданный список scope'ов тех. перерыва не принадлежит домену")
	ErrBreakWithSameNameAlreadyExist = errors.New("Тех. перерыв с таким названием уже существует и/или он находится в архиве")
	ErrBreakNotFound                 = errors.New("Тех. перерыв не найден")
	ErrScopeAlreadyExists            = errors.New("Scope уже существует с кодом {}")
	ErrScopeNotFound                 = errors.New("Scope тех. перерыва не найден")
	ErrScopeHasActiveBreaks          = errors.New("Невозможно удалить пока имеется действующий тех. перерыв с таким Scope")
	ErrScopeNotRelatedToDomain       = errors.New("Scope не найден, либо не принадлежит вашему домену/продукту")
	ErrDomainAlreadyExists           = errors.New("Домен/продукт с таким кодом уже существует")
	ErrDomainNotFound                = errors.New("Домен/продукт не найден")
	ErrForbidden                     = errors.New("access denied")
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
