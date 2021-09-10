FROM python:3.7-alpine3.12

COPY requirements.txt ./
COPY library/vmaf-1.5.3.tar.gz ./
COPY library/libwebp-1.0.2.tar.gz ./
COPY library/lame-3.100.tar.gz ./
COPY library/ffmpeg-snapshot.tar.bz2 ./

# mysql-config not found issue: https://stackoverflow.com/questions/25682408/docker-setup-with-a-mysql-container-for-a-python-app/51185814
# https://hub.docker.com/r/psitrax/powerdns/dockerfile
# These libs make this image size > 1GB

# Fix 'libwebp not found using pkg-config' issue. Refer to https://github.com/lovell/sharp/issues/190

RUN set -eux; \
    apk upgrade; \
    apk update; \
    apk add --no-cache build-base curl coreutils nasm cmake zlib-dev jpeg-dev libressl-dev; \
    apk add --no-cache --virtual .build-deps mariadb-dev; \
    pip3 install -r requirements.txt; \
    tar -zxvf vmaf-1.5.3.tar.gz; \
    rm vmaf-1.5.3.tar.gz; \
    ( \
        cd vmaf-1.5.3; \
        make -j2; \
        make install; \
        make clean; \
    ); \
    apk add --no-cache x264-dev; \
    tar -zxvf libwebp-1.0.2.tar.gz; \
    rm libwebp-1.0.2.tar.gz; \
    ( \
        cd libwebp-1.0.2; \
        ./configure; \
        make -j2; \
        make install; \
        make clean; \
        pkg-config --modversion libwebp; \
    ); \
    tar -zxvf lame-3.100.tar.gz; \
    rm lame-3.100.tar.gz; \
    ( \
        cd lame-3.100; \
        ./configure; \
        make -j2; \
        make install; \
        make clean; \
    ); \
    tar -jxf ffmpeg-snapshot.tar.bz2; \
    rm ffmpeg-snapshot.tar.bz2; \
    ( \
        cd ffmpeg; \
        ./configure --enable-libvmaf --enable-version3  --enable-libx264 --enable-gpl --enable-libwebp \
        --enable-libmp3lame --enable-openssl --enable-nonfree --extra-ldflags=-L/usr/local/lib \
        --disable-debug --disable-doc --disable-ffplay; \
        make -j32; \
        make install; \
        make clean; \
    ); \
    rm -rf vmaf-1.5.3 libwebp-1.0.2 lame-3.100 ffmpeg; \
    ffprobe -version; \
    ffmpeg -version


