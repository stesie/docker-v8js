FROM phusion/baseimage:latest
MAINTAINER Stefan Siegl <stesie@brokenpipe.de>

RUN apt-get update
RUN apt-get -y install git subversion make g++ python
RUN apt-get clean

# depot tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /usr/local/depot_tools
ENV PATH $PATH:/usr/local/depot_tools

# download v8
RUN git clone -b master --depth 1 https://github.com/v8/v8.git /usr/local/src/v8

# compile v8
RUN cd /usr/local/src/v8 && make dependencies
RUN cd /usr/local/src/v8 && make native library=shared -j4

# install v8
RUN mkdir -p /usr/local/v8/lib
RUN cp /usr/local/src/v8/out/native/lib.target/lib*.so /usr/local/v8/lib
RUN cp /usr/local/src/v8/out/native/obj.target/tools/gyp/libv8_libplatform.a /usr/local/v8/lib
RUN cp -R /usr/local/src/v8/include /usr/local/v8

RUN cd /usr/local/src/v8 && make clean

# get v8js, compile and install
RUN git clone https://github.com/preillyme/v8js.git /usr/local/src/v8js
RUN apt-get -y install php5-dev
RUN cd /usr/local/src/v8js && phpize && ./configure --with-v8js=/usr/local/v8
ENV NO_INTERACTION 1
RUN cd /usr/local/src/v8js && make all test install

# autoload v8js.so
RUN echo extension=v8js.so > /etc/php5/cli/conf.d/99-v8js.ini
