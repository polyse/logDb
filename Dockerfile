FROM golang:1.15 AS builder
WORKDIR /app

COPY go.mod .
COPY go.sum .
RUN go mod download

COPY . .

RUN GOOS=linux go build -buildmode=c-shared -o out_gstdout.so cmd/fadapter/main.go

FROM debian:buster as fbbuilder

ENV FLB_MAJOR 1
ENV FLB_MINOR 7
ENV FLB_PATCH 0
ENV FLB_VERSION 1.7.0

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    ca-certificates \
    cmake \
    make \
    tar \
    git \
    libssl-dev \
    libsasl2-dev \
    pkg-config \
    libsystemd-dev \
    libzstd-dev \
    zlib1g-dev \
    libpq-dev \
    postgresql-server-dev-all \
    flex \
    bison

RUN mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log /tmp/src/
RUN git clone https://github.com/fluent/fluent-bit /tmp/src/
RUN rm -rf /tmp/src/build/*

WORKDIR /tmp/src/build/
RUN cmake -DFLB_DEBUG=On \
          -DFLB_TRACE=Off \
          -DFLB_JEMALLOC=On \
          -DFLB_TLS=On \
          -DFLB_SHARED_LIB=Off \
          -DFLB_EXAMPLES=Off \
          -DFLB_HTTP_SERVER=On \
          -DFLB_IN_SYSTEMD=On \
          -DFLB_OUT_GO=On ../

RUN make -j $(getconf _NPROCESSORS_ONLN)
RUN install bin/fluent-bit /fluent-bit/bin/

# Configuration files
COPY conf/fluent-bit.conf \
    conf/parsers.conf \
    /fluent-bit/etc/

FROM gcr.io/distroless/cc-debian10
LABEL maintainer="Eduardo Silva <eduardo@treasure-data.com>"
LABEL Description="Fluent Bit docker image" Vendor="Fluent Organization" Version="1.1"

COPY --from=1 /usr/lib/x86_64-linux-gnu/*sasl* /usr/lib/x86_64-linux-gnu/
COPY --from=1 /usr/lib/x86_64-linux-gnu/libz* /usr/lib/x86_64-linux-gnu/
COPY --from=1 /lib/x86_64-linux-gnu/libz* /lib/x86_64-linux-gnu/
COPY --from=1 /usr/lib/x86_64-linux-gnu/libssl.so* /usr/lib/x86_64-linux-gnu/
COPY --from=1 /usr/lib/x86_64-linux-gnu/libcrypto.so* /usr/lib/x86_64-linux-gnu/

# These below are all needed for systemd
COPY --from=1 /lib/x86_64-linux-gnu/libsystemd* /lib/x86_64-linux-gnu/
COPY --from=1 /lib/x86_64-linux-gnu/libselinux.so* /lib/x86_64-linux-gnu/
COPY --from=1 /lib/x86_64-linux-gnu/liblzma.so* /lib/x86_64-linux-gnu/
COPY --from=1 /usr/lib/x86_64-linux-gnu/liblz4.so* /usr/lib/x86_64-linux-gnu/
COPY --from=1 /lib/x86_64-linux-gnu/libgcrypt.so* /lib/x86_64-linux-gnu/
COPY --from=1 /lib/x86_64-linux-gnu/libpcre.so* /lib/x86_64-linux-gnu/
COPY --from=1 /lib/x86_64-linux-gnu/libgpg-error.so* /lib/x86_64-linux-gnu/

COPY --from=1 /fluent-bit /fluent-bit
COPY --from=0 /app /plugin

#
EXPOSE 2020

# Entry point
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf", "-e", "/plugin/out_gstdout.so"]


