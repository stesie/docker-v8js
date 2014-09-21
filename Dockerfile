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
RUN cd /usr/local/src/v8 && \
	make dependencies
RUN cd /usr/local/src/v8 && \
	make x64.debug library=shared -j4 && \
	mkdir -p /usr/local/v8/lib && \
	cp out/x64.debug/lib.target/lib*.so /usr/local/v8/lib && \
	echo "create /usr/local/v8/lib/libv8_libplatform.a\naddlib out/x64.debug/obj.target/tools/gyp/libv8_libplatform.a\nsave\nend" | ar -M && \
	cp -R include /usr/local/v8 && \
	make clean

# fetch and install php5
RUN apt-get -y install wget && apt-get clean
RUN cd /usr/local/src && \
	wget http://de1.php.net/distributions/php-5.5.17.tar.bz2 && \
	tar xvjf php-5.5.17.tar.bz2
RUN apt-get -y install libxml2-dev && apt-get clean
RUN cd /usr/local/src/php-5.5.17 && \
	./configure --enable-maintainer-zts --enable-debug && \
	make -j4 && \
	make install && \
	make clean

# get v8js, compile and install
RUN git clone https://github.com/preillyme/v8js.git /usr/local/src/v8js
RUN apt-get -y install autoconf gdb screen && apt-get clean
RUN cd /usr/local/src/v8js && phpize && ./configure --with-v8js=/usr/local/v8
ENV NO_INTERACTION 1
RUN cd /usr/local/src/v8js && make all test install

# autoload v8js.so
RUN echo extension=v8js.so >> /usr/local/lib/php.ini
