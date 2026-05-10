SERVICE_NAME=tour-service

.PHONY: run build test tidy fmt vet docker-build

run:
	go run ./cmd

build:
	go build -o bin/$(SERVICE_NAME) ./cmd

test:
	GOWORK=off go test ./...

tidy:
	GOWORK=off go mod tidy

fmt:
	go fmt ./...

vet:
	GOWORK=off go vet ./...
	
docker-build:
	docker build -t $(SERVICE_NAME):local -f Dockerfile ../../..