# badtls.io socat build

One of the badtls.io tests is to ensure that a TLS connection with DH params that
are too small fails. However, recent versions of OpenSSL (obviously) don't
support DH params of 512 since it is a security vulnerability.

To allow for testing to take place, a TLS proxy is placed in front of the web
server, configured with small DH params. The simplest option for this is a
statically-linked build of socat, using OpenSSL 1.0.2.

The `./compile.sh` script will build socat from source, either on Linux or Mac.
For most users, the pre-compiled binaries in bin/ should suffice.
