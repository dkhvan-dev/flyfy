FROM golang:1.26 AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /app

COPY ./proto /app/proto
COPY ./backend/pkg/natstransport /app/backend/pkg/natstransport
COPY ./backend/pkg/serviceauth /app/backend/pkg/serviceauth
COPY ./backend/pkg/switches /app/backend/pkg/switches
COPY ./backend/pkg/transportauth /app/backend/pkg/transportauth
COPY ./backend/services/place-service /app/backend/services/place-service

WORKDIR /app/backend/services/place-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o place-service ./cmd && \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o place-service-backfill-search-index ./cmd/backfill-search-index

FROM gcr.io/distroless/base-debian12:latest

WORKDIR /opt/app

COPY --from=builder /app/backend/services/place-service/place-service /opt/app/place-service
COPY --from=builder /app/backend/services/place-service/place-service-backfill-search-index /opt/app/place-service-backfill-search-index

EXPOSE 8090 9099

ENTRYPOINT ["/opt/app/place-service"]
