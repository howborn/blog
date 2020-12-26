FROM php:7.3.7-fpm-alpine3.9

RUN echo 'https://mirrors.aliyun.com/alpine/v3.9/main/' > /etc/apk/repositories && \
    echo 'https://mirrors.aliyun.com/alpine/v3.9/community/' >> /etc/apk/repositories

# PHPIZE_DEPS 包含 gcc g++ 等编译辅助类库，完成编译后删除
RUN apk add --no-cache $PHPIZE_DEPS \
    && apk add --no-cache libstdc++ libzip-dev vim\
    && apk update \
#   && pecl install redis-4.3.0 \
    && pecl install zip \
#   && docker-php-ext-enable redis zip \
    && docker-php-ext-enable zip \
    && apk del $PHPIZE_DEPS
# docker-php-ext-install 指令已经包含编译辅助类库的删除逻辑
RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev \
    && apk update \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
#   && docker-php-ext-install -j$(nproc) pdo_mysql \
    && docker-php-ext-install -j$(nproc) opcache \
    && docker-php-ext-install -j$(nproc) bcmath

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# composer
#RUN php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" \
#    && php composer-setup.php \
#    && php -r "unlink('composer-setup.php');" \
#    && mv composer.phar /usr/local/bin/composer

ADD conf.d/* $PHP_INI_DIR/conf.d/