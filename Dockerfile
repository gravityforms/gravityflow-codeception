FROM php:8.1-cli

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
    		python3.6 \
            python3-distutils \
            python3-pip python3-apt \
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

RUN docker-php-ext-install pdo pdo_mysql

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

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 16.13.0

RUN mkdir $NVM_DIR

# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

# install node and npm
RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# confirm installation
RUN node -v
RUN npm -v

# Install gulp-cli
RUN npm install gulp-cli

# Add source-code
COPY . /repo

WORKDIR /project

ADD docker-entrypoint.sh /

RUN ["chmod", "+x", "/docker-entrypoint.sh"]
