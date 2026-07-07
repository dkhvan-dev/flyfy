FROM golang:1.26 AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /app

COPY ./backend/pkg/transportauth /app/backend/pkg/transportauth
COPY ./backend/services/anti-fraud-service /app/backend/services/anti-fraud-service

WORKDIR /app/backend/services/anti-fraud-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o anti-fraud-service ./cmd

FROM gcr.io/distroless/base-debian12:latest

WORKDIR /opt/app

COPY --from=builder /app/backend/services/anti-fraud-service/anti-fraud-service /opt/app/anti-fraud-service

EXPOSE 8096

ENTRYPOINT ["/opt/app/anti-fraud-service"]
