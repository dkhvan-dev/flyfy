FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/chat-service/go.mod backend/services/chat-service/go.sum* ./backend/services/chat-service/
COPY backend/pkg/switches/go.mod ./backend/pkg/switches/
COPY backend/pkg/trustpolicy/go.mod backend/pkg/trustpolicy/go.sum* ./backend/pkg/trustpolicy/
COPY proto ./proto

WORKDIR /app/backend/services/chat-service
RUN go mod download

COPY backend/pkg/trustpolicy /app/backend/pkg/trustpolicy
COPY backend/pkg/switches /app/backend/pkg/switches
COPY backend/services/chat-service ./

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /bin/chat-service ./cmd

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/chat-service /app/chat-service
COPY --from=builder /app/backend/services/chat-service/migrations /app/migrations

USER appuser

EXPOSE 8088 9097

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8088/health || exit 1

ENTRYPOINT ["/app/chat-service"]
