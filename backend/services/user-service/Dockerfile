FROM golang:1.26 AS builder

WORKDIR /app

COPY ./proto /app/proto
COPY ./backend/services/user-service /app/backend/services/user-service

WORKDIR /app/backend/services/user-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o user-service ./cmd

FROM gcr.io/distroless/base-debian12

WORKDIR /opt/app

COPY --from=builder /app/backend/services/user-service/user-service /opt/app/user-service

EXPOSE 8084
EXPOSE 9094

ENTRYPOINT ["/opt/app/user-service"]