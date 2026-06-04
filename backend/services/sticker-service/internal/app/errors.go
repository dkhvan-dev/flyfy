package app

import "errors"

var (
	ErrInvalidUserID          = errors.New("invalid user id")
	ErrInvalidPackID          = errors.New("invalid sticker pack id")
	ErrInvalidStickerID       = errors.New("invalid sticker id")
	ErrInvalidUploadSessionID = errors.New("invalid sticker upload session id")
	ErrPackNotFound           = errors.New("sticker pack not found")
	ErrPackNotAccessible      = errors.New("sticker pack is not accessible")
	ErrStickerNotFound        = errors.New("sticker not found")
	ErrStickerNotAccessible   = errors.New("sticker is not accessible")
	ErrStickerBlocked         = errors.New("sticker is blocked")
	ErrUploadSessionNotFound  = errors.New("sticker upload session not found")
	ErrUploadSessionExpired   = errors.New("sticker upload session expired")
	ErrFileNotReady           = errors.New("file is not ready")
	ErrUnsupportedMedia       = errors.New("unsupported sticker media")
	ErrCustomStickersDisabled = errors.New("custom stickers are disabled")
)
