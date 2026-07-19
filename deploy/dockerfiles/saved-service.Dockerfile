FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

COPY proto ./proto
COPY backend/pkg/platformpolicy ./backend/pkg/platformpolicy
COPY backend/pkg/serviceauth ./backend/pkg/serviceauth
COPY backend/pkg/transportauth ./backend/pkg/transportauth
COPY backend/services/saved-service ./backend/services/saved-service

WORKDIR /app/backend/services/saved-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w" -o /out/saved-service ./cmd
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w" -o /out/saved-search-backfill ./cmd/saved-search-backfill

FROM alpine:3.22

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -S -g 10001 app \
    && adduser -S -D -H -u 10001 -G app app

WORKDIR /app

COPY --from=builder --chown=10001:10001 /out/saved-service /app/saved-service
COPY --from=builder --chown=10001:10001 /out/saved-search-backfill /app/saved-search-backfill

USER 10001:10001

EXPOSE 8102

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8102/health >/dev/null || exit 1

ENTRYPOINT ["/app/saved-service"]
