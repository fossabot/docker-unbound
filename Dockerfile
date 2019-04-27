# Fully static compiled unbound with a minimal image based on distroless 

# Use alpine because it has recent building tools with the necessary patches in GCC & MUSL to make our live easier
# builder stage
FROM alpine:3.9 as builder

ARG LIBEVENT_VERSION=release-2.1.8-stable
ARG LIBEXPAT_VERSION=R_2_2_6
ARG LIBHIREDIS_VERSION=0.14.0
ARG OPENSSL_VERSION=1.1.1b
ARG UNBOUND_VERSION=1.9.1


RUN set -ex \
	&& apk update  \
	&& apk add \
	 git \
	 build-base \
	 automake \
	 autoconf \
	 ca-certificates \
	 pkgconf \
	 libtool \
	 curl \
	 linux-headers

# Download & build libevent
WORKDIR /src
RUN set -ex \
	&& git clone https://github.com/libevent/libevent.git \
	&& cd libevent \
	&& git checkout tags/${LIBEVENT_VERSION} \
	&& ./autogen.sh \
	&& ./configure --prefix=$PWD/install \
           --disable-shared \
           --enable-static \
           --enable-gcc-hardening \
           --disable-samples \
           --disable-libevent-regress \
           --disable-debug-mode \
           --disable-openssl \
           --enable-function-sections \
    && make -j $(nproc)  \
    && make install-strip

# Download & build Libexpat
WORKDIR /src    
RUN set -ex \
	&& git clone https://github.com/libexpat/libexpat.git \
	&& cd libexpat/expat \
	&& git checkout tags/${LIBEXPAT_VERSION} \
	&& ./buildconf.sh \
	&&  ./configure --prefix=$PWD/install \
		--disable-shared \
        --enable-static \
        --enable-fast-install \
        --without-docbook \
        --without-xmlwf \ 
    && make -j $(nproc) \
    && make install-strip


# Download & build Libhiredis
WORKDIR /src
RUN set -ex \
	&& curl -fsSL "https://github.com/redis/hiredis/archive/v${LIBHIREDIS_VERSION}.tar.gz" | tar zxvf - \
	&& mv hiredis-${LIBHIREDIS_VERSION} libhiredis \
	&& cd libhiredis \
	&& cp Makefile Makefile.orig \
	&& sed -e 's/REAL_CFLAGS=$(OPTIMIZATION) -fPIC $(CFLAGS) $(WARNINGS) $(DEBUG_FLAGS)/REAL_CFLAGS=$(OPTIMIZATION) -fPIE $(CFLAGS) $(WARNINGS) $(DEBUG_FLAGS)/g' Makefile.orig > Makefile \
	&& PREFIX=$PWD/install make -j $(nproc) install


# Download & build OpenSSL
WORKDIR /src    
RUN set -ex \
	&& curl -fsSL "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" | tar zxvf - \
	&& mv openssl-${OPENSSL_VERSION} openssl \
	&& cd openssl \
	&& ./config --prefix=$PWD/install/ --openssldir=$PWD/install/ \
		no-shared \
		no-dso \
		enable-ec_nistp_64_gcc_128 \
		no-srp \
		no-psk \
		no-dgram \
		no-ssl \
		no-afalgeng \
		no-capieng \
		no-hw-padlock \
		no-ocsp \
		no-srtp \
		no-cms \
		no-comp \
		no-zlib \
		no-filenames \
		no-nextprotoneg \
		no-makedepend \
		no-rfc3779 \
		no-ct \
		no-ts \
		no-tests \
		no-bf \
		no-rc2 \
		no-rc4 \
		no-idea \
		no-rmd160 \
		no-seed \
		no-siphash \
		no-sm2 \
		no-sm3 \
		no-sm4 \
		no-whirlpool \
		no-blake2 \
		no-camellia \
		no-cast \
		no-des \
		no-md4 \
		no-mdc2 \
		no-scrypt \
		no-cmac \
		no-gost \
		threads \
		--release \
		--api=1.0.0 \
	&& make -j$(nproc) install_dev 
	
	
	
# Download & build  Unbound
WORKDIR /src    
RUN set -ex \
	&& curl -fsSL "https://www.nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz" | tar zxvf - \
	&& mv unbound-${UNBOUND_VERSION} unbound \
	&& cd unbound \
	#Change ar and ranlib to gcc-ar and gcc-ranlib to support FLTO
	&& rm /usr/bin/ar \
	&& ln -s /usr/bin/gcc-ar /usr/bin/ar \
	&& rm /usr/bin/ranlib \
	&& ln -s /usr/bin/gcc-ranlib /usr/bin/ranlib \
	&& ./configure --prefix=/usr \
			--disable-shared \
			--enable-static \
			--with-libevent=/src/libevent/install \
			--with-libexpat=/src/libexpat/expat/install \
			--with-ssl=/src/openssl/install \
			--with-libhiredis=/src/libhiredis/install\
			--enable-pie \
			--enable-static-exe \
			--enable-relro-now \
			--disable-rpath \
			--enable-subnet \
			--disable-gost \
		 	--with-pthreads \
		 	--with-username=unbound \
		 	--with-conf-file=/etc/unbound/unbound.conf \
		 	--with-run-dir=/var/lib/unbound \
		 	--with-share-dir=/usr/share/unbound \
	&& cp Makefile Makefile.orig \
	&& sed -e 's/staticexe=-static/staticexe=-all-static/g' Makefile.orig > Makefile \
	&& make -j -j$(nproc) \
	&& strip --strip-debug unbound unbound-anchor unbound-checkconf unbound-control unbound-host  \
	&& make test

# Compile entrypoint
WORKDIR /src/entrypoint
COPY entrypoint.c . 
RUN set -ex \
	&& gcc -fPIE -static-pie -o entrypoint -O2 entrypoint.c \
	&& strip --strip-debug  entrypoint


# Distroless
FROM ubuntu:18.04 as distroless

ARG BUILDTOOLS_VERSION=0.22.0
ARG BAZEL_VERSION=0.24.0

RUN set -ex \
	&& apt-get update -qq \
	&& apt-get  --no-install-recommends --yes -q install \
		git \
		wget \
		golang \
    	ca-certificates \
    	curl \
    	python \
    	build-essential \
    	openssl
    

WORKDIR /root
RUN set -ex \
	&& git clone https://github.com/GoogleContainerTools/distroless.git \
	&& mkdir -p distroless/distroless 

COPY distroless/ /root/distroless/distroless/

# Build base image
WORKDIR /root/distroless	
RUN	set -ex \
	&& export PATH=$PATH:$HOME/bin && mkdir -p $HOME/bin \
	&& wget https://github.com/bazelbuild/buildtools/releases/download/${BUILDTOOLS_VERSION}/buildifier && chmod +x buildifier && mv buildifier $HOME/bin/ \
	&& wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-linux-x86_64 \
	&& mv bazel-${BAZEL_VERSION}-linux-x86_64 bazel && chmod +x bazel && mv bazel $HOME/bin/ \
	&& cp base/tmp.tar distroless/ \
	&& cp base/nsswitch.tar distroless/ \
	&& ./buildifier.sh \
	&& bazel build //distroless:unbound \
	&& mkdir finalimage \
	&& tar -xf bazel-bin/distroless/unbound-layer.tar -C finalimage \
	&& mkdir -p /root/distroless/finalimage/var/lib/unbound \
	&& mkdir -p /root/distroless/finalimage/etc/unbound \
	&& mkdir -p /root/distroless/finalimage/usr/share/unbound
	
#Download lastest root.hints
RUN set -ex \
	&& wget http://www.internic.net/domain/named.root -O /root/distroless/finalimage/etc/unbound/named.root 

#Copy tor files here in order to avoid additionnals layers in final image
COPY --from=builder /src/unbound/unbound /root/distroless/finalimage/usr/bin/
COPY --from=builder /src/unbound/unbound-anchor /root/distroless/finalimage/usr/bin/
COPY --from=builder /src/unbound/unbound-checkconf /root/distroless/finalimage/usr/bin/
COPY --from=builder /src/unbound/unbound-control /root/distroless/finalimage/usr/bin/
COPY --from=builder /src/unbound/unbound-host /root/distroless/finalimage/usr/bin/
COPY --from=builder /src/entrypoint /root/distroless/finalimage/
COPY unbound.conf /root/distroless/finalimage/etc/unbound/

COPY --from=builder /src/unbound/smallapp/unbound-control-setup.sh.in /root/unbound-control-setup.sh.in
WORKDIR /root
RUN set -ex \
	&& sed -e 's#DESTDIR=@ub_conf_dir@#DESTDIR=/root/distroless/finalimage/usr/share/unbound#g' unbound-control-setup.sh.in > unbound-control-setup.sh \
	&& chmod +x unbound-control-setup.sh \
	&& /root/unbound-control-setup.sh 

# runtime stage
FROM scratch
 
COPY --from=distroless /root/distroless/finalimage/ /
# Set correct owner for /var/lib/* and /usr/share/unbound/
COPY --from=distroless --chown=1001:1001 /root/distroless/finalimage/var/lib/ /var/lib/
COPY --from=distroless --chown=1001:1001 /root/distroless/finalimage/usr/share/unbound/ /usr/share/unbound/


VOLUME /var/lib/unbound

STOPSIGNAL SIGINT

CMD ["/entrypoint"]
