.PHONY: run test fmt vet build docker-build

run:
	go run ./cmd

test:
	GOWORK=off go test ./...

fmt:
	gofmt -w $$(find . -name '*.go')

vet:
	GOWORK=off go vet ./...

build:
	GOWORK=off go build -o bin/user-route-service ./cmd

docker-build:
	docker build -t inflap/user-route-service:local .
