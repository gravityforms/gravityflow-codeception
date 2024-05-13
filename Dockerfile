FROM php:7.4-cli

MAINTAINER Rocketgenius support@gravityforms.com


# Install required system packages
RUN apt-get update && \
    apt-get -y install \
            git \
            rsync \
            libssl-dev \
            libfreetype6-dev \
            libjpeg62-turbo-dev \
            sudo less \
            zlib1g-dev \
            libssl-dev \
            libzip-dev \
            mariadb-client \
            libpcre3 \
            libpcre3-dev \
            zip unzip \
        --no-install-recommends && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install php extensions
RUN docker-php-ext-install \
	bcmath \
	zip \
	# Add mysql driver required for wp-browser
	mysqli \
	# Additional dependencies.
	&& docker-php-ext-install -j$(nproc) iconv gd \
	&& docker-php-ext-configure gd --with-freetype --with-jpeg \
    && curl -sL https://deb.nodesource.com/setup_16.x | bash -  \
    && apt-get install -y nodejs

# Configure php
RUN echo "date.timezone = UTC" >> /usr/local/etc/php/php.ini

# Install composer
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN curl -sS https://getcomposer.org/installer | php -- \
        --filename=composer \
        --install-dir=/usr/local/bin

RUN composer global require "lucatume/wp-browser=^2.4" \
	"codeception/module-asserts=^1.3" \
	"codeception/module-phpbrowser=^1.0" \
	"codeception/module-webdriver=^1.1" \
	"codeception/module-db=^1.0" \
	"codeception/module-filesystem=^1.0" \
	"codeception/module-cli=^1.1" \
	"codeception/module-rest=^1.2" \
	"codeception/util-universalframework=^1.0" --prefer-dist --optimize-autoloader && \
    composer clear-cache && \
    ln -s ~/.composer/vendor/bin/codecept /usr/local/bin/codecept

# Add WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp

# Prepare application
WORKDIR /repo

# Add source-code
COPY . /repo

WORKDIR /project

ADD docker-entrypoint.sh /

RUN ["chmod", "+x", "/docker-entrypoint.sh"]
