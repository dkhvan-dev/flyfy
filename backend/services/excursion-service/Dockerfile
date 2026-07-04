FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/excursion-service/go.mod backend/services/excursion-service/go.sum* ./backend/services/excursion-service/
COPY backend/pkg/switches/go.mod ./backend/pkg/switches/
COPY backend/pkg/trustpolicy/go.mod backend/pkg/trustpolicy/go.sum* ./backend/pkg/trustpolicy/
COPY proto ./proto

WORKDIR /app/backend/services/excursion-service
RUN go mod download

COPY backend/pkg/trustpolicy /app/backend/pkg/trustpolicy
COPY backend/pkg/switches /app/backend/pkg/switches
COPY backend/services/excursion-service ./

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /bin/excursion-service ./cmd && \
    go build -ldflags="-s -w" -o /bin/recalculate-guide-ratings ./cmd/recalculate-guide-ratings && \
    go build -ldflags="-s -w" -o /bin/backfill-guide-search-snapshot ./cmd/backfill-guide-search-snapshot

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/excursion-service /app/excursion-service
COPY --from=builder /bin/recalculate-guide-ratings /app/recalculate-guide-ratings
COPY --from=builder /bin/backfill-guide-search-snapshot /app/backfill-guide-search-snapshot
COPY --from=builder /app/backend/services/excursion-service/migrations /app/migrations

USER appuser

EXPOSE 8093

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8093/health || exit 1
  
ENTRYPOINT ["/app/excursion-service"]
