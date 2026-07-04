FROM golang:1.26 AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /app

COPY ./proto /app/proto
COPY ./backend/pkg/switches /app/backend/pkg/switches
COPY ./backend/services/place-service /app/backend/services/place-service

WORKDIR /app/backend/services/place-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o place-service ./cmd

FROM gcr.io/distroless/base-debian12:latest

WORKDIR /opt/app

COPY --from=builder /app/backend/services/place-service/place-service /opt/app/place-service

EXPOSE 8090

ENTRYPOINT ["/opt/app/place-service"]
