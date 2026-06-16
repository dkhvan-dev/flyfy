SERVICE_NAME=user-service
PROTO_MODULE=kz/inflap/proto

.PHONY: run build build-backfill-feed-social-outbox backfill-feed-social-outbox backfill-feed-social-outbox-drain test tidy fmt vet docker-build

run:
	go run ./cmd

build:
	go build -o bin/$(SERVICE_NAME) ./cmd

build-backfill-feed-social-outbox:
	go build -o bin/$(SERVICE_NAME)-backfill-feed-social-outbox ./cmd/backfill-feed-social-outbox

backfill-feed-social-outbox:
	go run ./cmd/backfill-feed-social-outbox

backfill-feed-social-outbox-drain:
	go run ./cmd/backfill-feed-social-outbox -drain

test:
	go test ./...

tidy:
	go mod tidy

fmt:
	go fmt ./...

vet:
	go vet ./...

docker-build:
	docker build -t $(SERVICE_NAME):local -f Dockerfile .

proto-tidy:
	cd ../../../proto && go mod tidy
