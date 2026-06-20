FROM golang:1.26-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/activity-service/go.mod backend/services/activity-service/go.sum* ./backend/services/activity-service/
COPY backend/pkg/switches/go.mod ./backend/pkg/switches/
COPY backend/pkg/trustpolicy/go.mod backend/pkg/trustpolicy/go.sum* ./backend/pkg/trustpolicy/
COPY proto ./proto

WORKDIR /app/backend/services/activity-service
RUN go mod download

COPY backend/pkg/trustpolicy /app/backend/pkg/trustpolicy
COPY backend/pkg/switches /app/backend/pkg/switches
COPY backend/services/activity-service ./

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o /bin/activity-service ./cmd

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/activity-service /app/activity-service
COPY --from=builder /app/backend/services/activity-service/migrations /app/migrations

USER appuser

EXPOSE 8086 9096

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8086/health || exit 1

ENTRYPOINT ["/app/activity-service"]
