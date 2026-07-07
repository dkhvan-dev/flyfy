FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY proto ./proto
COPY backend/pkg/transportauth ./backend/pkg/transportauth
COPY backend/services/trust-service ./backend/services/trust-service

WORKDIR /app/backend/services/trust-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags="-s -w" -o /bin/trust-service ./cmd

FROM alpine:3.22

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/trust-service /app/trust-service

USER appuser

EXPOSE 9096

ENTRYPOINT ["/app/trust-service"]
