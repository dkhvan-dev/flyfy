FROM golang:1.26 AS builder

WORKDIR /app

COPY ./backend/services/anti-fraud-service /app/backend/services/anti-fraud-service

WORKDIR /app/backend/services/anti-fraud-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o anti-fraud-service ./cmd

FROM gcr.io/distroless/base-debian12:latest

WORKDIR /opt/app

COPY --from=builder /app/backend/services/anti-fraud-service/anti-fraud-service /opt/app/anti-fraud-service

EXPOSE 8096

ENTRYPOINT ["/opt/app/anti-fraud-service"]
