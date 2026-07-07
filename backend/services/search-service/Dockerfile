FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY proto/go.mod proto/go.sum ./proto/
COPY backend/services/search-service/go.mod backend/services/search-service/go.sum ./backend/services/search-service/
COPY backend/pkg/serviceauth/go.mod backend/pkg/serviceauth/go.sum* ./backend/pkg/serviceauth/
COPY backend/pkg/transportauth/go.mod backend/pkg/transportauth/go.sum* ./backend/pkg/transportauth/

WORKDIR /app/backend/services/search-service
RUN go mod download

COPY backend/pkg/serviceauth /app/backend/pkg/serviceauth
COPY backend/pkg/transportauth /app/backend/pkg/transportauth
COPY proto /app/proto
COPY backend/services/search-service ./

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /bin/search-service ./cmd && \
    go build -ldflags="-s -w" -o /bin/rebuild-index ./cmd/rebuild-index

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/search-service /app/search-service
COPY --from=builder /bin/rebuild-index /app/rebuild-index

USER appuser

EXPOSE 8101

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8101/health || exit 1

ENTRYPOINT ["/app/search-service"]
