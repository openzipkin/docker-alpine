#
# Copyright The OpenZipkin Authors
# SPDX-License-Identifier: Apache-2.0
#

# alpine_version is hard-coded here to allow the following to work:
#  * `docker build https://github.com/openzipkin/docker-alpine.git`
#
# When updating, update the README and the alpine_version ARG
#  * Use current version from https://alpinelinux.org/downloads/
#  * ARGs repeat because Dockerfile ARGs are layer specific but will reuse the value defined here.
ARG alpine_version=3.21.0

# We copy files from the context into a scratch container first to avoid a problem where docker and
# docker-compose don't share layer hashes https://github.com/docker/compose/issues/883 normally.
# COPY --from= works around the issue.
FROM scratch AS code

COPY . /code/

# See from a previously published version to avoid pulling from Docker Hub (docker.io)
# This version is only used to install the real version
FROM ghcr.io/openzipkin/alpine:3.20.3 AS install

WORKDIR /code
# Conditions aren't supported in Dockerfile instructions, so we copy source even if it isn't used.
COPY --from=code /code/ .

# Alpine's minirootfs is mirrored and only 5MB. wget on demand instead of consuming docker.io pulls
WORKDIR /install

ARG alpine_version
ENV ALPINE_VERSION=$alpine_version
RUN /code/alpine_minirootfs $ALPINE_VERSION

# Define base layer, notably not adding labels always overridden
FROM scratch AS alpine
ARG maintainer="OpenZipkin https://gitter.im/openzipkin/zipkin"
LABEL maintainer=$maintainer
LABEL org.opencontainers.image.authors=$maintainer
ARG alpine_version
LABEL alpine-version=$alpine_version

COPY --from=install /install /

# Default to UTF-8 file.encoding
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# RUN, COPY, and ADD instructions create layers. While layer count is less important in modern
# Docker, it doesn't help performance to intentionally make multiple RUN layers in a base image.
RUN \
  #
  # Java relies on /etc/nsswitch.conf. Put host files first or InetAddress.getLocalHost
  # will throw UnknownHostException as the local hostname isn't in DNS.
  echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
  #
  # Exclusively use edge repos to get recent packages, but avoid conflicts with 3.21
  echo 'https://dl-cdn.alpinelinux.org/alpine/edge/main' > /etc/apk/repositories && \
  echo 'https://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories && \
  echo 'https://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories && \
  #
  # Finalize install:
  # * java-cacerts: implicitly gets normal ca-certs used outside Java (this does not depend on java)
  # * gcompat: BoringSSL for Netty per https://github.com/grpc/grpc-java/blob/master/SECURITY.md#netty
  apk add --no-cache java-cacerts ca-certificates gcompat && \
  # Typically, only amd64 is tested in CI: Run a command to ensure binaries match current arch.
  ldd /usr/lib/libz.so.1

ENTRYPOINT ["/bin/sh"]
