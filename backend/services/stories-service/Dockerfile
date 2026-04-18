FROM golang:1.26 AS builder

WORKDIR /app

COPY ./proto /app/proto
COPY ./backend/services/stories-service /app/backend/services/stories-service

WORKDIR /app/backend/services/stories-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o stories-service ./cmd

FROM gcr.io/distroless/base-debian12:latest

WORKDIR /opt/app

COPY --from=builder /app/backend/services/stories-service/stories-service /opt/app/stories-service

EXPOSE 8087

ENTRYPOINT ["/opt/app/stories-service"]
