FROM golang:1.26 AS builder

WORKDIR /app

COPY ./backend/services/payment-service /app/backend/services/payment-service

WORKDIR /app/backend/services/payment-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o payment-service ./cmd

FROM gcr.io/distroless/base-debian12:latest

WORKDIR /opt/app

COPY --from=builder /app/backend/services/payment-service/payment-service /opt/app/payment-service

EXPOSE 8091

ENTRYPOINT ["/opt/app/payment-service"]
