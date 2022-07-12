FROM alpine:3.16.0 as builder

ENV UNBOUND_VERSION 1.16.1

RUN apk update && apk add \
    curl \
    build-base \
    openssl-dev \
    expat-dev \
    tar \
    gzip \
    && curl -LO https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz \
    && tar -xzf unbound-${UNBOUND_VERSION}.tar.gz \
    && cd unbound-${UNBOUND_VERSION} \
    && ./configure \
    && make \
    && make install \
    && unbound -V

FROM alpine:3.16.0

ENV UNBOUND_VERSION 1.16.1

LABEL maintainer="Kirill Shtrykov" \
      org.opencontainers.image.version=${UNBOUND_VERSION} \
      org.opencontainers.image.title="kirillshtrykov/unbound" \
      org.opencontainers.image.description="a validating, recursive, and caching DNS resolver" \
      org.opencontainers.image.url="https://github.com/kirill-shtrykov/unbound" \
      org.opencontainers.image.vendor="Kirill Shtrykov" \
      org.opencontainers.image.licenses="GPLv3" \
      org.opencontainers.image.source="https://github.com/kirill-shtrykov/unbound"

VOLUME /etc/unbound/unbound.conf.d

COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/sbin/unbound /usr/local/sbin/unbound
COPY unbound.conf /etc/unbound/unbound.conf

RUN apk add --no-cache ca-certificates \
    && rm -rf /var/cache/apk/* \
    && addgroup -S unbound \
    && adduser -S -h /var/unbound -g Unbound -G unbound unbound

EXPOSE 53/tcp
EXPOSE 53/udp

ENTRYPOINT ["/usr/local/sbin/unbound"]

CMD ["-p","-c","/etc/unbound/unbound.conf"]
