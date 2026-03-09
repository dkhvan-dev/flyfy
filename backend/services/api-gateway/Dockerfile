FROM golang:1.26 AS builder

WORKDIR /app

COPY ./proto /app/proto
COPY ./backend/services/api-gateway /app/backend/services/api-gateway

WORKDIR /app/backend/services/api-gateway

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o api-gateway ./cmd

FROM gcr.io/distroless/base-debian12

WORKDIR /opt/app

COPY --from=builder /app/backend/services/api-gateway/api-gateway /opt/app/api-gateway

EXPOSE 8080

ENTRYPOINT ["/opt/app/api-gateway"]