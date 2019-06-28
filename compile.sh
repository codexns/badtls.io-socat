#!/bin/bash

SOCAT_URL="http://www.dest-unreach.org/socat/download/socat-1.7.3.1.tar.gz"
SOCAT_ARCHIVE=$(basename $SOCAT_URL)
SOCAT_DIR=$(basename $SOCAT_ARCHIVE .tar.gz)

# Version 1.0.2 was the release before adding DH param checks
OPENSSL_URL="https://www.openssl.org/source/old/1.0.2/openssl-1.0.2.tar.gz"
OPENSSL_ARCHIVE=$(basename $OPENSSL_URL)
OPENSSL_DIR=$(basename $OPENSSL_ARCHIVE .tar.gz)

ROOT=$(pwd)
BUILD="$ROOT/build"
DOWNLOAD="$ROOT/downloads"
PREFIX="$ROOT/env"
BIN="$ROOT/bin"
MACHINE_TYPE=$(uname -sm | sed -e 's/ /-/' | tr '[:upper:]' '[:lower:]')

set -e

mkdir -p $BIN
mkdir -p $BUILD
mkdir -p $DOWNLOAD
mkdir -p $PREFIX
mkdir -p $PREFIX/include
mkdir -p $PREFIX/lib
mkdir -p $PREFIX/bin
mkdir -p $PREFIX/share
mkdir -p $PREFIX/usr

cd $DOWNLOAD

if [[ $(command -v curl) == "" ]]; then
    FETCH="wget"
else
    FETCH="curl -O --location"
fi


if [[ ! -e $SOCAT_ARCHIVE ]]; then
    echo "Downloading socat"
    $FETCH $SOCAT_URL
fi

if [[ ! -e $OPENSSL_ARCHIVE ]]; then
    echo "Downloading openssl"
    $FETCH $OPENSSL_URL
fi


cd $BUILD

if [[ ! -e $OPENSSL_DIR ]]; then
    echo "Extracting openssl"
    tar xvfz $DOWNLOAD/$OPENSSL_ARCHIVE

    cd $OPENSSL_DIR/
    echo "Compiling openssl"
    if [[ $MACHINE_TYPE == "darwin-x86_64" ]]; then
        ./Configure darwin64-x86_64-cc enable-static-engine no-rc5 shared -mmacosx-version-min=10.9 --prefix=$PREFIX
    else
        ./config enable-static-engine no-rc5 shared --prefix=$PREFIX -fPIC -U_FORTIFY_SOURCE
        make depend
    fi
    make
    make install
    cd ..
fi


rm -Rf $SOCAT_DIR/
tar xvfz $DOWNLOAD/$SOCAT_ARCHIVE

cd $SOCAT_DIR/

patch -p1 <<'EOF'
--- a/configure 2016-03-11 17:21:27.000000000 -0500
+++ b/configure 2016-03-11 17:30:31.000000000 -0500
@@ -5076,7 +5076,7 @@
   sc_cv_have_openssl_ssl_h=yes; OPENSSL_ROOT="";
 else
   sc_cv_have_openssl_ssl_h=no
-       for D in "/sw" "/usr/local" "/opt/freeware" "/usr/sfw" "/usr/local/ssl"; do
+       for D in "../../env"; do
 	I="$D/include"
 	i="$I/openssl/ssl.h"
 	if test -r "$i"; then
EOF

if [[ $MACHINE_TYPE == "darwin-x86_64" ]]; then
    SOCAT_CFLAGS="-mmacosx-version-min=10.9"
else
    SOCAT_CFLAGS="-U_FORTIFY_SOURCE"
fi
./configure --disable-readline --prefix=$PREFIX CFLAGS="$SOCAT_CFLAGS"
if [[ $MACHINE_TYPE == "darwin-x86_64" ]]; then
    sed -i '' -E 's# -L\.\./\.\./env/lib -lssl -lcrypto#../../env/lib/libssl.a ../../env/lib/libcrypto.a#' Makefile
else
    sed -i -r 's# -L\.\./\.\./env/lib -lssl -lcrypto#../../env/lib/libssl.a ../../env/lib/libcrypto.a -ldl#' Makefile
fi
make
make install

cp $PREFIX/bin/socat $BIN/socat-$MACHINE_TYPE

cd $ROOT
