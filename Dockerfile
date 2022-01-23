FROM php:8.1.1-fpm

MAINTAINER Nicolas Canfrere

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update

ARG basedeps="git gnupg apt-utils apt-transport-https build-essential openssh-client rsync sqlite3 zip unzip vim"
RUN apt-get install -y --no-install-recommends $basedeps

ARG phpextdeps="libmagickwand-dev librabbitmq-dev"
RUN apt-get install -y --no-install-recommends $phpextdeps

ARG phpmoduledeps="libenchant-2-dev libgmp-dev libxml2-dev libjpeg-dev libpng-dev libc-client-dev libkrb5-dev libldap2-dev freetds-dev libzip-dev firebird-dev libpq-dev libpspell-dev libsqlite3-dev libtidy-dev libxslt-dev libfreetype6-dev libwebp-dev libxpm-dev libmpdec-dev"
RUN apt-get install -y --no-install-recommends $phpmoduledeps
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/libsybdb.a
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/libsybdb.so

RUN cp /usr/share/zoneinfo/Europe/Paris /etc/localtime && echo "Europe/Paris" > /etc/timezone
RUN sed -i -e "s/<policy domain=\"coder\" rights=\"none\" pattern=\"PDF\" \/>/<policy domain=\"coder\" rights=\"read|write\" pattern=\"PDF\" \/>/g" /etc/ImageMagick-6/policy.xml


ARG modules="bcmath bz2 calendar dba enchant exif gd gettext \
               gmp imap intl ldap mysqli opcache pcntl pdo_dblib \
               pdo_firebird pdo_mysql pdo_pgsql pgsql pspell shmop soap \
                sockets sysvmsg sysvsem sysvshm tidy xsl zip"
RUN docker-php-ext-configure zip
RUN docker-php-ext-configure gmp
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-xpm --with-webp
RUN docker-php-ext-configure imap --with-imap --with-kerberos --with-imap-ssl

RUN docker-php-ext-install $modules

RUN docker-php-ext-enable sodium
RUN pecl install imagick-3.5.1 && docker-php-ext-enable imagick
RUN pecl install apcu && docker-php-ext-enable apcu
RUN pecl install redis && docker-php-ext-enable redis
RUN pecl install amqp-1.11.0 && docker-php-ext-enable amqp
RUN pecl install mongodb && docker-php-ext-enable mongodb
RUN pecl install decimal && docker-php-ext-enable decimal
# RUN pecl install psr && docker-php-ext-enable psr # not compatible php8 ...
RUN pecl install uuid && docker-php-ext-enable uuid
RUN pecl install xdebug-3.1.2 && docker-php-ext-enable xdebug

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY configs/xxxx-custom.ini $PHP_INI_DIR/conf.d
COPY configs/90-xdebug.ini $PHP_INI_DIR/conf.d

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*
