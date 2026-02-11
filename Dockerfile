# Stage 1: Install dependencies
FROM golang:1.24-alpine AS deps
RUN apk add --no-cache libc6-compat git
WORKDIR /app
# Copy manifest
COPY go.mod go.sum ./
RUN go mod download

# Stage 2: Builder
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY --from=deps /go/pkg /go/pkg
COPY . .
# Build-time Arguments
ARG APP_VERSION=1.0.0
ENV CGO_ENABLED=0
ENV GOOS=linux
# Compile binary
RUN go build -ldflags="-s -w -X main.Version=${APP_VERSION}" -o main .

# Stage 3: Runner
FROM alpine:3.19 AS runner
WORKDIR /app
#metadata
LABEL author="Yansha"
LABEL project="Go Distributed Limiter"
# Create non-root user
RUN addgroup --system --gid 1001 gopher && \
    adduser --system --uid 1001 gopher
COPY --from=builder --chown=gopher:gopher /app/main ./
# Set Environment Variables
ENV APP_ENV=production
ENV REDIS_ADDR=redis:6379
# Use non-root user to run our application
USER gopher
EXPOSE 8080
ENV PORT 8080

# Run the binary
CMD ["./main"]