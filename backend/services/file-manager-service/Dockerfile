FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /app

RUN apk add --no-cache git ca-certificates tzdata

COPY backend/services/file-manager-service/go.mod backend/services/file-manager-service/go.sum* ./backend/services/file-manager-service/
COPY backend/pkg/switches/go.mod ./backend/pkg/switches/
COPY backend/pkg/trustpolicy/go.mod backend/pkg/trustpolicy/go.sum* ./backend/pkg/trustpolicy/
COPY proto ./proto

WORKDIR /app/backend/services/file-manager-service
RUN go mod download

COPY backend/pkg/trustpolicy /app/backend/pkg/trustpolicy
COPY backend/pkg/switches /app/backend/pkg/switches
COPY backend/services/file-manager-service ./ 
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /bin/file-manager-service ./cmd

FROM alpine:3.22

WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata && update-ca-certificates

COPY --from=builder /bin/file-manager-service /app/file-manager-service
COPY --from=builder /app/backend/services/file-manager-service/migrations /app/migrations

EXPOSE 8083 9093

CMD ["/app/file-manager-service"]
