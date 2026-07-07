FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/routing-service/go.mod backend/services/routing-service/go.sum* ./backend/services/routing-service/
COPY backend/pkg/transportauth/go.mod backend/pkg/transportauth/go.sum* ./backend/pkg/transportauth/

WORKDIR /app/backend/services/routing-service
RUN go mod download

COPY backend/pkg/transportauth /app/backend/pkg/transportauth
COPY backend/services/routing-service ./

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /bin/routing-service ./cmd

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/routing-service /app/routing-service

USER appuser

EXPOSE 8094

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8094/health || exit 1

ENTRYPOINT ["/app/routing-service"]
