# GLM-Free-API - pure-Go bridge, no CGO, tiny static image

FROM golang:1.27-alpine AS build

WORKDIR /src

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /zai-api main.go

FROM alpine:3.20

RUN adduser -D -u 10001 bridge

WORKDIR /app

COPY --from=build /zai-api /app/zai-api
COPY tokens.sqlite /app/tokens.sqlite

ENV PORT=3001 HOST=0.0.0.0

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s CMD wget -qO- http://127.0.0.1:${PORT}/health || exit 1

ENTRYPOINT ["/app/zai-api"]
