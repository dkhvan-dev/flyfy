FROM golang:1.26-alpine AS builder

ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /src
COPY backend/services/switches-service/go.mod backend/services/switches-service/go.sum* ./
RUN go mod download
COPY backend/services/switches-service ./
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /out/switches-service ./cmd

FROM alpine:3.22

RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder /out/switches-service /app/switches-service
USER app
EXPOSE 8096
ENTRYPOINT ["/app/switches-service"]
