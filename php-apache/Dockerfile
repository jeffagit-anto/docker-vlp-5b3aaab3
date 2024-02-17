FROM php:7.4-apache

RUN apt-get update && \
    apt-get install -y libpq-dev && \
    docker-php-ext-install pgsql

RUN a2enmod proxy_http rewrite
