APP_NAME := sticker-service

.PHONY: run build seed-default-stickers test fmt vet

run:
	go run ./cmd

build:
	go build -o bin/$(APP_NAME) ./cmd

seed-default-stickers:
	GOWORK=off go run ./cmd/seed-default-stickers

test:
	GOWORK=off go test ./...

fmt:
	go fmt ./...

vet:
	GOWORK=off go vet ./...
