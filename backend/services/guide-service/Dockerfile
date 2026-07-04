FROM golang:1.26 AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /app

COPY ./proto /app/proto
COPY ./backend/services/guide-service /app/backend/services/guide-service

WORKDIR /app/backend/services/guide-service

RUN go mod download
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o guide-service ./cmd

FROM gcr.io/distroless/base-debian12

WORKDIR /opt/app

COPY --from=builder /app/backend/services/guide-service/guide-service /opt/app/guide-service

EXPOSE 8085
EXPOSE 9095

ENTRYPOINT ["/opt/app/guide-service"]