FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

COPY backend/services/user-route-service/go.mod backend/services/user-route-service/go.sum* ./backend/services/user-route-service/
COPY backend/pkg/transportauth/go.mod backend/pkg/transportauth/go.sum* ./backend/pkg/transportauth/

WORKDIR /app/backend/services/user-route-service
RUN go mod download

COPY backend/pkg/transportauth /app/backend/pkg/transportauth
COPY backend/services/user-route-service ./

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
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
