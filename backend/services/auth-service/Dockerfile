# ============================================
# Stage 1: Build
# ============================================
FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache git ca-certificates

ENV GOWORK=off

WORKDIR /app

COPY proto/go.mod proto/go.sum ./proto/
COPY backend/services/auth-service/go.mod backend/services/auth-service/go.sum ./backend/services/auth-service/
COPY backend/pkg/transportauth/go.mod backend/pkg/transportauth/go.sum* ./backend/pkg/transportauth/

WORKDIR /app/backend/services/auth-service
RUN go mod download

WORKDIR /app
COPY proto ./proto
COPY backend/pkg/transportauth ./backend/pkg/transportauth
COPY backend/services/auth-service ./backend/services/auth-service

WORKDIR /app/backend/services/auth-service

# Собираем бинарь
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
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
COPY --from=builder /app/backend/services/auth-service/migrations ./migrations

USER appuser

EXPOSE 50052 8082

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
    CMD wget -qO- http://localhost:8082/health || exit 1

ENTRYPOINT ["./auth-service"]
