FROM golang:1.26 AS builder

WORKDIR /app

COPY ./proto /app/proto
COPY ./backend/services/feed-service /app/backend/services/feed-service

WORKDIR /app/backend/services/feed-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o feed-service ./cmd

FROM gcr.io/distroless/base-debian12:latest

WORKDIR /opt/app

COPY --from=builder /app/backend/services/feed-service/feed-service /opt/app/feed-service

EXPOSE 8087

ENTRYPOINT ["/opt/app/feed-service"]
