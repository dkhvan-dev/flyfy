FROM golang:1.26-alpine AS build

WORKDIR /src
COPY proto /proto
COPY backend/services/admin-panel/go.mod backend/services/admin-panel/go.sum* ./
COPY backend/pkg/switches/go.mod /pkg/switches/
RUN go mod download

COPY backend/pkg/switches /pkg/switches
COPY backend/services/admin-panel ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/admin-panel ./cmd

FROM alpine:3.22
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build /out/admin-panel /app/admin-panel
USER app
EXPOSE 8095
ENTRYPOINT ["/app/admin-panel"]
