package app

import "errors"

var (
	ErrInvalidLanguage        = errors.New("invalid translation language")
	ErrContentNotTranslatable = errors.New("content type is not eligible for automatic translation")
	ErrInvalidRequest         = errors.New("invalid translation request")
	ErrTranslationJobNotFound = errors.New("translation job not found")
)
