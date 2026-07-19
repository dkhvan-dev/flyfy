APP_NAME := saved-service
BIN_DIR := bin
BIN := $(BIN_DIR)/$(APP_NAME)
GOCACHE ?= /private/tmp/inflap-saved-go-build

.PHONY: run build test fmt vet docker-build

run:
	GOWORK=off GOCACHE=$(GOCACHE) go run ./cmd

build:
	mkdir -p $(BIN_DIR)
	GOWORK=off GOCACHE=$(GOCACHE) go build -o $(BIN) ./cmd

test:
	GOWORK=off GOCACHE=$(GOCACHE) go test ./...

fmt:
	gofmt -w $$(find . -name '*.go' -not -path './bin/*')

vet:
	GOWORK=off GOCACHE=$(GOCACHE) go vet ./...

docker-build:
	docker build -f Dockerfile -t inflap/saved-service:local ../../..
