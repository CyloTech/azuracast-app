# Releasing azuracast 0.23.4-1

The image is the deployed 0.23.4 digest with PHP's own files copied in from
the official `php:8.5.12-fpm-trixie` image (see the Dockerfile).

## 1. Is the patched PHP available?

Docker Hub must have `php:8.5.12-fpm-trixie`. Either of these answers it:

    docker buildx imagetools inspect docker.io/library/php:8.5.12-fpm-trixie   # on the builder
    release/build-on-builder.sh pin 8.5.12-fpm-trixie                           # fails with "not available on Docker Hub yet"

## 2-5. Pin, build, gate, push

From a clean checkout of branch `php-multipart-fix` on the Mac:

    git pull --ff-only origin php-multipart-fix
    release/build-on-builder.sh pin 8.5.12-fpm-trixie
    git commit -am "Pin php:8.5.12-fpm-trixie by digest"
    git push origin php-multipart-fix
    release/build-on-builder.sh release

`release` builds `repo.cylo.net/azuracast:0.23.4-1` on the builder from the
pushed commit, runs `release/verify-image.sh` and pushes only if the gate
passes, then prints the pushed digest.

A trial (never pushed) is `release/build-on-builder.sh trial 8.5.11-fpm-trixie`.
