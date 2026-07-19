FROM golang:1.26 AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /app

COPY ./proto /app/proto
COPY ./backend/pkg/serviceauth /app/backend/pkg/serviceauth
COPY ./backend/pkg/switches /app/backend/pkg/switches
COPY ./backend/pkg/transportauth /app/backend/pkg/transportauth
COPY ./backend/services/feed-service /app/backend/services/feed-service

WORKDIR /app/backend/services/feed-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -o feed-service ./cmd && \
    go build -o feed-service-backfill-search-index ./cmd/backfill-search-index

FROM gcr.io/distroless/base-debian12:latest

WORKDIR /opt/app

COPY --from=builder /app/backend/services/feed-service/feed-service /opt/app/feed-service
COPY --from=builder /app/backend/services/feed-service/feed-service-backfill-search-index /opt/app/feed-service-backfill-search-index

EXPOSE 8087 9098

ENTRYPOINT ["/opt/app/feed-service"]
