FROM golang:1.26 AS builder

WORKDIR /app

COPY ./proto /app/proto
COPY ./backend/pkg/switches /app/backend/pkg/switches
COPY ./backend/services/attraction-service /app/backend/services/attraction-service

WORKDIR /app/backend/services/attraction-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o attraction-service ./cmd

FROM gcr.io/distroless/base-debian12:latest

WORKDIR /opt/app

COPY --from=builder /app/backend/services/attraction-service/attraction-service /opt/app/attraction-service

EXPOSE 8090

ENTRYPOINT ["/opt/app/attraction-service"]
