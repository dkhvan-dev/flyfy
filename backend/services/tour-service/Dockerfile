FROM golang:1.26-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/tour-service/go.mod backend/services/tour-service/go.sum* ./backend/services/tour-service/
COPY proto ./proto

WORKDIR /app/backend/services/tour-service
RUN go mod download

COPY backend/services/tour-service ./

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o /bin/tour-service ./cmd

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/tour-service /app/tour-service
COPY --from=builder /app/backend/services/tour-service/migrations /app/migrations

USER appuser

EXPOSE 8093

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8093/health || exit 1
  
ENTRYPOINT ["/app/tour-service"]