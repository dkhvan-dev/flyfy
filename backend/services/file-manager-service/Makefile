APP_NAME=file-manager-service
SERVICE_PATH=./backend/services/file-manager-service
BINARY_NAME=file-manager-service

.PHONY: tidy build run test fmt vet docker-build

tidy:
	cd $(SERVICE_PATH) && go mod tidy

fmt:
	cd $(SERVICE_PATH) && go fmt ./...

vet:
	cd $(SERVICE_PATH) && go vet ./...

test:
	cd $(SERVICE_PATH) && go test ./...

build:
	cd $(SERVICE_PATH) && go build -o $(BINARY_NAME) ./cmd

run:
	cd $(SERVICE_PATH) && go run ./cmd

docker-build:
	docker build -f $(SERVICE_PATH)/Dockerfile -t $(APP_NAME):local .

proto:
	cd proto && buf generate

migrate-up:
	@echo "Run migrations with your preferred migration tool"

migrate-down:
	@echo "Run rollback with your preferred migration tool"