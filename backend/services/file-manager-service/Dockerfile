FROM golang:1.26-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git ca-certificates tzdata

COPY backend/services/file-manager-service/go.mod backend/services/file-manager-service/go.sum* ./backend/services/file-manager-service/
COPY backend/pkg/trustpolicy/go.mod backend/pkg/trustpolicy/go.sum* ./backend/pkg/trustpolicy/
COPY proto ./proto

WORKDIR /app/backend/services/file-manager-service
RUN go mod download

COPY backend/pkg/trustpolicy /app/backend/pkg/trustpolicy
COPY backend/services/file-manager-service ./ 
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /bin/file-manager-service ./cmd

FROM alpine:3.22

WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata && update-ca-certificates

COPY --from=builder /bin/file-manager-service /app/file-manager-service
COPY --from=builder /app/backend/services/file-manager-service/migrations /app/migrations

EXPOSE 8083 9093

CMD ["/app/file-manager-service"]
