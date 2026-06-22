FROM golang:1.26-alpine AS builder

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

COPY backend/services/user-route-service/go.mod backend/services/user-route-service/go.sum* ./backend/services/user-route-service/

WORKDIR /app/backend/services/user-route-service
RUN go mod download

COPY backend/services/user-route-service ./

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o /bin/user-route-service ./cmd

FROM alpine:3.22

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -S app \
    && adduser -S app -G app

WORKDIR /app
COPY --from=builder /bin/user-route-service /app/user-route-service

USER app

EXPOSE 8096
ENTRYPOINT ["/app/user-route-service"]
