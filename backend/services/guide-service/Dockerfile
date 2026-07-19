FROM golang:1.26 AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /app

COPY ./proto /app/proto
COPY ./backend/pkg/natstransport /app/backend/pkg/natstransport
COPY ./backend/pkg/serviceauth /app/backend/pkg/serviceauth
COPY ./backend/pkg/transportauth /app/backend/pkg/transportauth
COPY ./backend/services/guide-service /app/backend/services/guide-service

WORKDIR /app/backend/services/guide-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o guide-service ./cmd
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o guide-service-backfill-search-index ./cmd/backfill-search-index

FROM gcr.io/distroless/base-debian12

WORKDIR /opt/app

COPY --from=builder /app/backend/services/guide-service/guide-service /opt/app/guide-service
COPY --from=builder /app/backend/services/guide-service/guide-service-backfill-search-index /opt/app/guide-service-backfill-search-index

EXPOSE 8085
EXPOSE 9095

ENTRYPOINT ["/opt/app/guide-service"]
