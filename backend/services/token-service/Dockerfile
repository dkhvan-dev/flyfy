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
COPY backend/services/token-service/go.mod backend/services/token-service/go.sum ./backend/services/token-service/
COPY backend/pkg/transportauth/go.mod backend/pkg/transportauth/go.sum* ./backend/pkg/transportauth/

WORKDIR /app/backend/services/token-service
RUN go mod download

WORKDIR /app
COPY proto ./proto
COPY backend/pkg/transportauth ./backend/pkg/transportauth
COPY backend/services/token-service ./backend/services/token-service

WORKDIR /app/backend/services/token-service

# Собираем статический бинарь
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /build/token-service ./cmd/

# ============================================
# Stage 2: Runtime
# ============================================
FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser \
    && mkdir -p /var/lib/inflap/token-service \
    && chown -R appuser:appgroup /var/lib/inflap

WORKDIR /app

COPY --from=builder /build/token-service .
COPY --from=builder /app/backend/services/token-service/migrations ./migrations

USER appuser

EXPOSE 50051 8081

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
    CMD wget -qO- http://localhost:8081/health || exit 1

ENTRYPOINT ["./token-service"]
