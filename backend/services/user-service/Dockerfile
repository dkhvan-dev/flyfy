FROM golang:1.26 AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /app

COPY ./proto /app/proto
COPY ./backend/pkg/serviceauth /app/backend/pkg/serviceauth
COPY ./backend/pkg/switches /app/backend/pkg/switches
COPY ./backend/pkg/transportauth /app/backend/pkg/transportauth
COPY ./backend/services/user-service /app/backend/services/user-service

WORKDIR /app/backend/services/user-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o user-service ./cmd
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o user-service-backfill-feed-social-outbox ./cmd/backfill-feed-social-outbox
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o user-service-backfill-search-index ./cmd/backfill-search-index

FROM gcr.io/distroless/base-debian12

WORKDIR /opt/app

COPY --from=builder /app/backend/services/user-service/user-service /opt/app/user-service
COPY --from=builder /app/backend/services/user-service/user-service-backfill-feed-social-outbox /opt/app/user-service-backfill-feed-social-outbox
COPY --from=builder /app/backend/services/user-service/user-service-backfill-search-index /opt/app/user-service-backfill-search-index

EXPOSE 8084
EXPOSE 9094

ENTRYPOINT ["/opt/app/user-service"]
