FROM php:fpm

RUN mkdir /web
COPY ./websites /web

RUN docker-php-ext-install pdo pdo_mysql