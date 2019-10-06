FROM swift:5.1 AS builder
ARG CONFIG=release
WORKDIR /src
RUN apt-get update && apt-get install -y \
        libssl-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
COPY . .
RUN swift build -c $CONFIG --static-swift-stdlib

FROM swift:5.1-slim
WORKDIR /
COPY --from=builder /src/.build/release/docker-watch /usr/local/bin/
CMD ["docker-watch"]
