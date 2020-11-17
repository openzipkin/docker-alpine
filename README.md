[![Gitter chat](http://img.shields.io/badge/gitter-join%20chat%20%E2%86%92-brightgreen.svg)](https://gitter.im/openzipkin/zipkin)
![Build Status](https://github.com/openzipkin/docker-alpine/workflows/test/badge.svg)

`ghcr.io/openzipkin/alpine` is a minimal [Alpine Linux](https://alpinelinux.org) image.

On GitHub Container Registry: [ghcr.io/openzipkin/alpine](https://github.com/orgs/openzipkin/packages/container/package/alpine) includes:
 * `master` tag: latest commit
 * `N.M.L` tag: release

## Release process
The Docker build is driven by `build-bin/build`. The argument to this must be Alpine's most specific
version, ex `3.12.1` not `3.12`
 * You can look here: https://alpinelinux.org/downloads/

Build the `Dockerfile` and verify the image you built matches that version.

Ex.
```bash
./build-bin/build 3.12.1
```

Next, verify the built image matches that version.

For example, given the following output from `docker run --rm openzipkin/alpine:test -c 'cat /etc/alpine-release'`...
```
3.12.1
```

To release the image, push a tag named the same as the arg to `build-bin/build` (ex `3.12.1`).
This will trigger a [GitHub Actions](https://github.com/openzipkin/docker-alpine/actions) job to push the image.
