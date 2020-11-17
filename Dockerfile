#
# Copyright 2020 The OpenZipkin Authors
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.
#

# We copy files from the context into a scratch container first to avoid a problem where docker and
# docker-compose don't share layer hashes https://github.com/docker/compose/issues/883 normally.
# COPY --from= works around the issue.
FROM scratch as scratch

COPY . /code/

# The builder image can be almost anything, but it might as well be Alpine.
#
# Use a fixed version likely to be cached by Google. This will avoid consuming
# Docker Hub pull quota, which can result in build outages.
#
# While tempting, copies are unlikely to work because they often don't republish
# as multi-arch. For example, https://quay.io/repository/app-sre/alpine is amd64
FROM alpine:3.12.1 as install

WORKDIR /code
# Conditions aren't supported in Dockerfile instructions, so we copy source even if it isn't used.
COPY --from=scratch /code/ .

# Alpine's minirootfs is mirrored and only 5MB. Build on demand instead of consuming docker.io pulls
WORKDIR /install
# Use current version here: https://alpinelinux.org/downloads/
ARG version=3.12.1
ENV ALPINE_VERSION=$version
RUN /code/alpine_minirootfs $ALPINE_VERSION

# Define base layer, notably not adding labels always overridden
FROM scratch as alpine
ARG maintainer="OpenZipkin https://gitter.im/openzipkin/zipkin"
LABEL maintainer=$maintainer
LABEL org.opencontainers.image.authors=$maintainer

COPY --from=install /install /

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Java relies on /etc/nsswitch.conf. Put host files first or InetAddress.getLocalHost
# will throw UnknownHostException as the local hostname isn't in DNS.
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# Later installations may require more recent versions of packages such as nodejs
RUN for repository in main testing community; do \
      repository_url=https://dl-cdn.alpinelinux.org/alpine/edge/${repository} && \
      grep -qF -- $repository_url /etc/apk/repositories || echo $repository_url >> /etc/apk/repositories; \
    done

# Finalize install:
# * java-cacerts: implicitly gets normal ca-certs used outside Java (this does not depend on java)
# * libc6-compat: BoringSSL for Netty per https://github.com/grpc/grpc-java/blob/master/SECURITY.md#netty
RUN apk add --no-cache java-cacerts libc6-compat

ENTRYPOINT ["/bin/sh"]
