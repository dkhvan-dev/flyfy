FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

COPY backend/services/checklist-service/go.mod backend/services/checklist-service/go.sum* ./backend/services/checklist-service/

WORKDIR /app/backend/services/checklist-service
RUN go mod download

COPY backend/services/checklist-service ./

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /bin/checklist-service ./cmd

FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -g 1001 appgroup \
    && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=builder /bin/checklist-service /app/checklist-service

USER appuser

EXPOSE 8099

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:8099/health || exit 1

ENTRYPOINT ["/app/checklist-service"]
