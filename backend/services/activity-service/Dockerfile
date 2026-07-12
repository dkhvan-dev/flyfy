FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/activity-service/go.mod backend/services/activity-service/go.sum* ./backend/services/activity-service/
COPY backend/pkg/serviceauth/go.mod backend/pkg/serviceauth/go.sum* ./backend/pkg/serviceauth/
COPY backend/pkg/switches/go.mod ./backend/pkg/switches/
COPY backend/pkg/trustpolicy/go.mod backend/pkg/trustpolicy/go.sum* ./backend/pkg/trustpolicy/
COPY backend/pkg/transportauth/go.mod backend/pkg/transportauth/go.sum* ./backend/pkg/transportauth/
COPY proto ./proto

WORKDIR /app/backend/services/activity-service
RUN go mod download

COPY backend/pkg/trustpolicy /app/backend/pkg/trustpolicy
COPY backend/pkg/serviceauth /app/backend/pkg/serviceauth
COPY backend/pkg/switches /app/backend/pkg/switches
COPY backend/pkg/transportauth /app/backend/pkg/transportauth
COPY backend/services/activity-service ./

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /bin/activity-service ./cmd
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /bin/activity-service-backfill-search-index ./cmd/backfill-search-index
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /bin/activity-service-backfill-translations ./cmd/backfill-activity-translations

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/activity-service /app/activity-service
COPY --from=builder /bin/activity-service-backfill-search-index /app/activity-service-backfill-search-index
COPY --from=builder /bin/activity-service-backfill-translations /app/activity-service-backfill-translations
COPY --from=builder /app/backend/services/activity-service/migrations /app/migrations

USER appuser

EXPOSE 8086 9096

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8086/health || exit 1

ENTRYPOINT ["/app/activity-service"]
