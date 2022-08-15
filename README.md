[![Gitter chat](http://img.shields.io/badge/gitter-join%20chat%20%E2%86%92-brightgreen.svg)](https://gitter.im/openzipkin/zipkin)
[![Build Status](https://github.com/openzipkin/docker-alpine/workflows/test/badge.svg)](https://github.com/openzipkin/docker-alpine/actions?query=workflow%3Atest)

`ghcr.io/openzipkin/alpine` is a minimal [Alpine Linux](https://alpinelinux.org) image including
CA certs and libc6-compat.

GitHub Container Registry: [ghcr.io/openzipkin/alpine](https://github.com/orgs/openzipkin/packages/container/package/alpine) includes:
 * `master` tag: latest commit
 * `MAJOR.MINOR.PATCH` tag: release corresponding to a [Current Alpine Version](https://alpinelinux.org/downloads/)

## Using this image
This is an internal base layer primarily used in [docker-java](https://github.com/openzipkin/docker-java).

To browse the image, run it in interactive mode with TTY enabled like so:
```bash
docker run -ti --rm ghcr.io/openzipkin/alpine:3.16.2
/ #
```

## Release process
Build the `Dockerfile` using the current version from https://alpinelinux.org/downloads/:
```bash
# Note 3.16.2 not 3.16!
./build-bin/build 3.16.2
```

Next, verify the built image matches that version:
```bash
docker run --rm openzipkin/alpine:test -c 'cat /etc/alpine-release'
3.16.2
```

To release the image, push a tag matching the arg to `build-bin/build` (ex `3.16.2`).
This triggers a [GitHub Actions](https://github.com/openzipkin/docker-alpine/actions) job to push the image.
