ARG COMPOSER_VERSION=2.1.14
ARG PHP_VERSION=8.1.0-fpm-alpine3.15
ARG NODE_VERSION=16.13.1-alpine3.13
ARG NGINX_VERSION=1.21.4-alpine

# PHP  CONTAINER
FROM composer:${COMPOSER_VERSION} as composer
FROM php:${PHP_VERSION} as builder

LABEL maintainer="glefer@itroom.fr"

ENV COMPOSER_ALLOW_SUPERUSER 1

WORKDIR /app

RUN apk add --no-cache --virtual .build-deps libzip-dev icu-dev $PHPIZE_DEPS  \
    && apk add --no-cache curl icu-libs libintl libzip \
    && pecl install apcu \
    && docker-php-ext-configure intl  \
    && docker-php-ext-install opcache intl pdo_mysql zip intl exif \
    && docker-php-ext-enable apcu  intl \
    && pecl clear-cache \
    && apk del .build-deps \
    && rm -rf /tmp/*

# GD INSTALLATION
#RUN apk add --no-cache findutils gd freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev perl && \
#  docker-php-ext-configure gd --with-freetype --with-jpeg && \
#  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
#  docker-php-ext-install -j${NPROC} gd && \
#  apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev

COPY infra/docker/php/conf/symfony.ini /usr/local/etc/php/conf.d/symfony.ini
RUN curl -sSL https://github.com/fabpot/local-php-security-checker/releases/download/v1.2.0/local-php-security-checker_1.2.0_linux_amd64 -o /usr/local/bin/local-php-security-checker
COPY infra/docker/php/scripts/php-fpm-healthcheck /usr/local/bin/

RUN chmod +x /usr/local/bin/local-php-security-checker /usr/local/bin/php-fpm-healthcheck
RUN set -xe && echo "pm.status_path = /status" >> /usr/local/etc/php-fpm.d/zz-docker.conf
HEALTHCHECK --interval=2s CMD bash php-fpm-healthcheck


RUN apk add tzdata supervisor && mkdir /etc/supervisor.d/
COPY infra/docker/php/conf/supervisor.ini /etc/supervisor.d/supervisor.ini
CMD /usr/bin/supervisord --pidfile=/run/supervisord.pid -n -c /etc/supervisord.conf

COPY --from=composer /usr/bin/composer /usr/bin/composer


## Dev application
FROM builder as dev

RUN apk add --no-cache --virtual .build-deps  $PHPIZE_DEPS  \
    && apk add --no-cache git \
    && pecl install pcov \
    && docker-php-ext-enable pcov \
    && pecl clear-cache \
    && apk del .build-deps \
    && rm -rf /tmp/*

COPY infra/docker/php/scripts/install-symfony.sh /usr/local/bin/

RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && architecture=$(uname -m) \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/alpine/$architecture/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8307\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz


## BUILD ASSETS
FROM node:${NODE_VERSION} as node-builder
WORKDIR /app
COPY package.* yarn.* webpack.config.js /app/
RUN yarn install
COPY assets /app/assets
RUN yarn encore production

## Production
FROM builder as prod
ENV APP_ENV prod
RUN  sed -i 's/opcache.validate_timestamps.*/opcache.validate_timestamps=0/' /usr/local/etc/php/conf.d/symfony.ini
COPY --from=node-builder /app/public /app/public
COPY --chown=www-data . /app
RUN composer install -o -a --no-dev && chown -R www-data .
RUN rm -rf infra/ /usr/bin/composer

## NGINX  CONTAINER
FROM nginx:${NGINX_VERSION} as nginx
COPY infra/docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=node-builder /app/public /app/public
