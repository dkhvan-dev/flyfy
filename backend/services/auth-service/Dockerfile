# ============================================
# Stage 1: Build
# ============================================
FROM golang:1.26-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /repo

# Копируем весь репозиторий, чтобы были доступны:
# - backend/services/auth-service
# - proto (или contracts)
COPY . .

WORKDIR /repo/backend/services/auth-service

# Скачиваем зависимости уже в контексте монорепы
RUN go mod download

# Собираем бинарь
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o /build/auth-service ./cmd/

# ============================================
# Stage 2: Runtime
# ============================================
FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /build/auth-service .
COPY --from=builder /repo/backend/services/auth-service/migrations ./migrations

USER appuser

EXPOSE 50052 8082

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
    CMD wget -qO- http://localhost:8082/health || exit 1

ENTRYPOINT ["./auth-service"]