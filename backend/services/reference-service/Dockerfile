FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/reference-service/go.mod backend/services/reference-service/go.sum* ./backend/services/reference-service/
COPY backend/pkg/transportauth/go.mod backend/pkg/transportauth/go.sum* ./backend/pkg/transportauth/

WORKDIR /app/backend/services/reference-service
RUN go mod download

COPY backend/pkg/transportauth /app/backend/pkg/transportauth
COPY backend/services/reference-service ./

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /bin/reference-service ./cmd

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/reference-service /app/reference-service

USER appuser

EXPOSE 8089

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8089/health || exit 1

ENTRYPOINT ["/app/reference-service"]
