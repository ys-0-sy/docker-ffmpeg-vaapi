FROM debian
MAINTAINER Yuta Saito <yuta.saito0703@gmail.com>

WORKDIR /work

ENV TARGET_VERSION=4.1.4 \
    LIBVA_VERSION=2.3.0 \
    LIBDRM_VERSION=2.4.80 \
    SRC=/usr \
    PKG_CONFIG_PATH=/usr/lib/pkgconfig

RUN apt-get update && \
    # Install libdrm
    apt-get install -y libdrm2 libdrm-dev && \
    # Install build dependencies
    build_deps="automake autoconf bzip2 \
                cmake curl libfreetype6-dev gcc \
                g++ git libtool make \
                mercurial nasm build-essential \
                pkg-config yasm zlib1g-dev" && \
    apt-get install -y ${build_deps} && \
    # Build libva
    DIR=$(mktemp -d) && cd ${DIR} && \
    curl -sL https://github.com/intel/libva/releases/download/${LIBVA_VERSION}/libva-${LIBVA_VERSION}.tar.bz2 | \
    tar -jx --strip-components=1 && \
    ./configure CFLAGS=' -O2' CXXFLAGS=' -O2' --prefix=${SRC} && \
    make && make install && \
    rm -rf ${DIR} && \
    # Build libva-intel-driver
    DIR=$(mktemp -d) && cd ${DIR} && \
    curl -sL https://github.com/intel/intel-vaapi-driver/releases/download/${LIBVA_VERSION}/intel-vaapi-driver-${LIBVA_VERSION}.tar.bz2 | \
    tar -jx --strip-components=1 && \
    ./configure && \
    make && make install && \
    rm -rf ${DIR} && \
    # Build ffmpeg
    DIR=$(mktemp -d) && cd ${DIR} && \
    curl -sL http://ffmpeg.org/releases/ffmpeg-${TARGET_VERSION}.tar.gz | \
    tar -zx --strip-components=1 && \
    ./configure \
        --prefix=${SRC} \
        --enable-small \
        --enable-gpl \
        --enable-vaapi \
        --disable-doc \
        --disable-debug && \
    make && make install && \
    make distclean && \
    hash -r && \
    # Cleanup build dependencies and temporary files
    rm -rf ${DIR} && \
    apt-get -y remove ${build_deps} && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    ffmpeg -buildconf

ENTRYPOINT ffmpeg
