FROM golang:1.26 AS builder

ARG TARGETOS=linux
ARG TARGETARCH

WORKDIR /app

COPY proto ./proto
COPY backend/pkg/platformpolicy ./backend/pkg/platformpolicy
COPY backend/pkg/serviceauth ./backend/pkg/serviceauth
COPY backend/pkg/transportauth ./backend/pkg/transportauth
COPY backend/services/api-gateway ./backend/services/api-gateway

WORKDIR /app/backend/services/api-gateway

RUN go mod download
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w" -o /out/api-gateway ./cmd

FROM gcr.io/distroless/base-debian12

WORKDIR /opt/app

COPY --from=builder /out/api-gateway /opt/app/api-gateway

EXPOSE 8080

ENTRYPOINT ["/opt/app/api-gateway"]
