FROM stesie/libv8-8.4 AS builder
MAINTAINER Stefan Siegl <stesie@brokenpipe.de>

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    php-dev git ca-certificates g++ make

RUN git clone https://github.com/phpv8/v8js.git /usr/local/src/v8js
WORKDIR /usr/local/src/v8js

RUN phpize
RUN ./configure --with-v8js=/opt/libv8-8.4 LDFLAGS="-lstdc++" CPPFLAGS="-DV8_COMPRESS_POINTERS"
RUN make all -j`nproc`

FROM stesie/libv8-8.4
COPY --from=builder /usr/local/src/v8js/modules/v8js.so /usr/lib/php/20170718/

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends php-cli && \
    echo extension=v8js.so > /etc/php/7.2/cli/conf.d/99-v8js.ini && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

CMD [ "php", "-a" ]
