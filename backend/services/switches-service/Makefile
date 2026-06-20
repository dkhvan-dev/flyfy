.PHONY: run test fmt vet docker-build

run:
	go run ./cmd

test:
	go test ./...

fmt:
	go fmt ./...

vet:
	go vet ./...

docker-build:
	docker build -t inflap/switches-service .
