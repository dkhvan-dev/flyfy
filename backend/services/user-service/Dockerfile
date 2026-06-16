FROM golang:1.26 AS builder

WORKDIR /app

COPY ./proto /app/proto
COPY ./backend/services/user-service /app/backend/services/user-service

WORKDIR /app/backend/services/user-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o user-service ./cmd
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o user-service-backfill-feed-social-outbox ./cmd/backfill-feed-social-outbox

FROM gcr.io/distroless/base-debian12

WORKDIR /opt/app

COPY --from=builder /app/backend/services/user-service/user-service /opt/app/user-service
COPY --from=builder /app/backend/services/user-service/user-service-backfill-feed-social-outbox /opt/app/user-service-backfill-feed-social-outbox

EXPOSE 8084
EXPOSE 9094

ENTRYPOINT ["/opt/app/user-service"]
