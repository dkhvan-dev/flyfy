FROM golang:1.26 AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /app

COPY ./backend/pkg/transportauth /app/backend/pkg/transportauth
COPY ./backend/services/payment-service /app/backend/services/payment-service

WORKDIR /app/backend/services/payment-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o payment-service ./cmd

FROM gcr.io/distroless/base-debian12:latest

WORKDIR /opt/app

COPY --from=builder /app/backend/services/payment-service/payment-service /opt/app/payment-service

EXPOSE 8091

ENTRYPOINT ["/opt/app/payment-service"]
