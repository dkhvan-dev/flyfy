APP_NAME := notification-service

.PHONY: run build test fmt vet

run:
	go run ./cmd

build:
	go build -o bin/$(APP_NAME) ./cmd

test:
	GOWORK=off go test ./...

fmt:
	go fmt ./...

vet:
	GOWORK=off go vet ./...
