FROM phusion/baseimage:latest
MAINTAINER Stefan Siegl <stesie@brokenpipe.de>

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        git subversion make g++ python2.7 curl php7.0-dev chrpath wget bzip2 && \
    ln -s /usr/bin/python2.7 /usr/bin/python && \
    \
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /tmp/depot_tools && \
    export PATH="$PATH:/tmp/depot_tools" && \
    \
    cd /usr/local/src && fetch v8 && cd v8 && \
    git checkout 5.4.500.40 && gclient sync && \
    export GYPFLAGS="-Dv8_use_external_startup_data=0" && \
    export GYPFLAGS="${GYPFLAGS} -Dlinux_use_bundled_gold=0" && \
    make native library=shared snapshot=on -j4 && \
    \
    mkdir -p /usr/local/lib && \
    cp /usr/local/src/v8/out/native/lib.target/lib*.so /usr/local/lib && \
    echo -e "create /usr/local/lib/libv8_libplatform.a\naddlib out/native/obj.target/src/libv8_libplatform.a\nsave\nend" | ar -M && \
    cp -R /usr/local/src/v8/include /usr/local && \
    chrpath -r '$ORIGIN' /usr/local/lib/libv8.so && \
    \
    git clone https://github.com/preillyme/v8js.git /usr/local/src/v8js && \
    cd /usr/local/src/v8js && phpize && ./configure --with-v8js=/usr/local && \
    export NO_INTERACTION=1 && \
    make all test install && \
    \
    echo extension=v8js.so > /etc/php5/cli/conf.d/99-v8js.ini && \
    \
    rm -rf /tmp/depot_tools /usr/local/src/v8 /usr/local/src/v8js && \
    apt-get remove subversion make g++ python2.7 curl chrpath wget bzip2 && \
    apt-get clean
