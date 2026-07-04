FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/sticker-service/go.mod backend/services/sticker-service/go.sum* ./backend/services/sticker-service/

WORKDIR /app/backend/services/sticker-service
RUN go mod download

COPY backend/services/sticker-service ./

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /bin/sticker-service ./cmd \
    && go build -ldflags="-s -w" -o /bin/seed-default-stickers ./cmd/seed-default-stickers

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/sticker-service /app/sticker-service
COPY --from=builder /bin/seed-default-stickers /app/seed-default-stickers
COPY --from=builder /app/backend/services/sticker-service/migrations /app/migrations

USER appuser

EXPOSE 8092

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8092/health || exit 1

ENTRYPOINT ["/app/sticker-service"]
