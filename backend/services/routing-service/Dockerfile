FROM golang:1.26-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/routing-service/go.mod backend/services/routing-service/go.sum* ./backend/services/routing-service/

WORKDIR /app/backend/services/routing-service
RUN go mod download

COPY backend/services/routing-service ./

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o /bin/routing-service ./cmd

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/routing-service /app/routing-service

USER appuser

EXPOSE 8094

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8094/health || exit 1

ENTRYPOINT ["/app/routing-service"]
