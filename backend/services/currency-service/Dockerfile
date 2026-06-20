FROM golang:1.26-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/currency-service/go.mod backend/services/currency-service/go.sum* ./backend/services/currency-service/
COPY backend/pkg/switches/go.mod ./backend/pkg/switches/

WORKDIR /app/backend/services/currency-service
RUN go mod download

COPY backend/pkg/switches /app/backend/pkg/switches
COPY backend/services/currency-service ./

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o /bin/currency-service ./cmd

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/currency-service /app/currency-service

USER appuser

EXPOSE 8098

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8098/health || exit 1

ENTRYPOINT ["/app/currency-service"]
