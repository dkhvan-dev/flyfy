FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/translation-service/go.mod backend/services/translation-service/go.sum* ./backend/services/translation-service/
COPY proto/go.mod proto/go.sum* ./proto/
COPY backend/pkg/serviceauth/go.mod backend/pkg/serviceauth/go.sum* ./backend/pkg/serviceauth/
COPY backend/pkg/transportauth/go.mod backend/pkg/transportauth/go.sum* ./backend/pkg/transportauth/

WORKDIR /app/backend/services/translation-service
RUN go mod download

COPY proto /app/proto
COPY backend/pkg/serviceauth /app/backend/pkg/serviceauth
COPY backend/pkg/transportauth /app/backend/pkg/transportauth
COPY backend/services/translation-service ./

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /bin/translation-service ./cmd

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/translation-service /app/translation-service

USER appuser

EXPOSE 8094

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8094/health/ready || exit 1

ENTRYPOINT ["/app/translation-service"]
