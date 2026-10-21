# AzuraCast 0.23.4 as deployed (repo.cylo.net/azuracast:0.23.4), with PHP
# replaced by PHP 8.5.12, the release with the security fixes of 21 October
# 2026.
#
# The deployed image runs PHP 8.5.3 from the official php:8.5-fpm-trixie
# image under /usr/local. The new PHP comes from
# repo.cylo.net/php-artifacts:docker-library-php-8.5.12-fpm-trixie, a
# FROM-scratch artifact holding the /usr/local tree of PHP 8.5.12 built with
# the unmodified docker-library/php 8.5/trixie/fpm recipe (the recipe behind
# the official image; see release/php-artifact/). Only the files PHP's own
# build installs there are copied in: the CLI and FPM binaries, php-config,
# phpize, the headers, the build files and the shared extensions the recipe
# ships. The extensions AzuraCast compiled for PHP 8.5 (same module API,
# 20250925), the PHP and FPM configuration in /usr/local/etc, the Appbox
# scripts and the application itself stay exactly as deployed.
#
# PHP_IMAGE is pinned by digest. A trial build may override PHP_VERSION and
# PHP_IMAGE with another PHP image (release/build-on-builder.sh trial).

ARG PHP_VERSION=8.5.12
ARG PHP_IMAGE=repo.cylo.net/php-artifacts:docker-library-php-8.5.12-fpm-trixie@sha256:0a0865cf94221d85bd76d7287557d36de7b64e76652c029d37f0d3575280d557
ARG PHP_EXTENSION_DIR=/usr/local/lib/php/extensions/no-debug-non-zts-20250925

FROM ${PHP_IMAGE} AS patched-php

FROM repo.cylo.net/azuracast@sha256:b6eb3c765dc06eee2a430abf359090cc0cdba3551a229df95d016df63d45954f
ARG PHP_VERSION
ARG PHP_IMAGE
ARG PHP_EXTENSION_DIR

COPY --from=patched-php /usr/local/bin/php /usr/local/bin/php-config /usr/local/bin/phpize /usr/local/bin/
COPY --from=patched-php /usr/local/sbin/php-fpm /usr/local/sbin/
COPY --from=patched-php /usr/local/include/php/ /usr/local/include/php/
COPY --from=patched-php /usr/local/lib/php/build/ /usr/local/lib/php/build/
COPY --from=patched-php ${PHP_EXTENSION_DIR}/ ${PHP_EXTENSION_DIR}/

ENV PHP_VERSION=${PHP_VERSION}
LABEL org.appbox.php-source=${PHP_IMAGE}
