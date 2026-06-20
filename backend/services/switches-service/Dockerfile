FROM golang:1.26-alpine AS builder

WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/switches-service ./cmd

FROM alpine:3.22

RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder /out/switches-service /app/switches-service
USER app
EXPOSE 8096
ENTRYPOINT ["/app/switches-service"]
