# ============================================
# Stage 1: Build
# ============================================
FROM golang:1.26-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /repo

# Копируем весь репозиторий
COPY . .

# Переходим в сервис
WORKDIR /repo/backend/services/token-service

# Скачиваем зависимости
RUN go mod download

# Собираем статический бинарь
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o /build/token-service ./cmd/

# ============================================
# Stage 2: Runtime
# ============================================
FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /build/token-service .
COPY --from=builder /repo/backend/services/token-service/migrations ./migrations

USER appuser

EXPOSE 50051 8081

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
    CMD wget -qO- http://localhost:8081/health || exit 1

ENTRYPOINT ["./token-service"]