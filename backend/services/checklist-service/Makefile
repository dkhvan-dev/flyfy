APP_NAME := checklist-service
BIN_DIR := bin
BIN := $(BIN_DIR)/$(APP_NAME)
GOCACHE ?= /private/tmp/inflap-checklist-go-build

.PHONY: run build test fmt vet clean

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

clean:
	rm -rf $(BIN_DIR)
