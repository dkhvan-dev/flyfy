FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/notification-service/go.mod backend/services/notification-service/go.sum* ./backend/services/notification-service/

WORKDIR /app/backend/services/notification-service
RUN go mod download

COPY backend/services/notification-service ./

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /bin/notification-service ./cmd

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/notification-service /app/notification-service
COPY --from=builder /app/backend/services/notification-service/migrations /app/migrations

USER appuser

EXPOSE 8097

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8097/health || exit 1

ENTRYPOINT ["/app/notification-service"]
