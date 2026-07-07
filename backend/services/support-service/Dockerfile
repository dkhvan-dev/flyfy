FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/support-service/go.mod backend/services/support-service/go.sum* ./backend/services/support-service/
COPY backend/pkg/serviceauth/go.mod backend/pkg/serviceauth/go.sum* ./backend/pkg/serviceauth/
COPY backend/pkg/transportauth/go.mod backend/pkg/transportauth/go.sum* ./backend/pkg/transportauth/
COPY proto ./proto

WORKDIR /app/backend/services/support-service
RUN go mod download

COPY backend/pkg/serviceauth /app/backend/pkg/serviceauth
COPY backend/pkg/transportauth /app/backend/pkg/transportauth
COPY backend/services/support-service ./

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /bin/support-service ./cmd && \
    go build -ldflags="-s -w" -o /bin/support-service-backfill-search-index ./cmd/backfill-search-index

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/support-service /app/support-service
COPY --from=builder /bin/support-service-backfill-search-index /app/support-service-backfill-search-index

USER appuser

EXPOSE 8100

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8100/health || exit 1

ENTRYPOINT ["/app/support-service"]
