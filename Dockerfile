# AzuraCast 0.23.4 as deployed (repo.cylo.net/azuracast:0.23.4), with PHP
# replaced by the same files from an official PHP image.
#
# The deployed image runs PHP 8.5.3 from the official php:8.5-fpm-trixie
# image under /usr/local. Only the files PHP's own build installs there are
# copied in: the CLI and FPM binaries, php-config, phpize, the headers, the
# build files and the shared extensions the official image ships. The
# extensions AzuraCast compiled for PHP 8.5 (same module API, 20250925), the
# PHP and FPM configuration in /usr/local/etc, the Appbox scripts and the
# application itself stay exactly as deployed.
#
# Release: `release/build-on-builder.sh pin 8.5.12-fpm-trixie` pins
# PHP_IMAGE by digest. A trial build overrides PHP_VERSION and PHP_IMAGE
# with the current unpatched release.

ARG PHP_VERSION=8.5.12
ARG PHP_IMAGE=php:8.5.12-fpm-trixie
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
