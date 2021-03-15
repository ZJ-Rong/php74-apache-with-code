FROM php:7.4-apache
MAINTAINER ZJ-Rong <qq307365873@gmail.com>

RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libmemcached-dev \
    zlib1g-dev \
    libltdl7 \
    libltdl-dev \
    libpq-dev \
    libzip-dev \
    libsqlite3-dev \
    git \
    curl \
    libcurl3-dev \
    rsyslog \
    cron \
    supervisor \
    unzip \
    libicu-dev \
    --no-install-recommends \
    && docker-php-ext-install -j$(nproc) iconv pdo_mysql pdo_pgsql pdo_sqlite zip curl\
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

RUN pecl install apcu memcached mongodb redis \
	&& docker-php-ext-enable apcu memcached mongodb redis

RUN pecl install mcrypt \
    && docker-php-ext-enable mcrypt

RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/supervisor

#调整时区

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo "date.timezone = Asia/Shanghai" >> /etc/php.ini

#安装nodejs和yarn

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update && apt-get install -y nodejs yarn

#安装composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/bin --filename=composer \
    && php -r "unlink('composer-setup.php');" \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

#配置apache

RUN a2enmod ssl rewrite
RUN { \
    echo '<VirtualHost *:80>';\
    	echo 'ServerAdmin webmaster@localhost';\
    	echo 'DocumentRoot /var/www/html';\
    	echo 'ErrorLog ${APACHE_LOG_DIR}/error.log';\
    	echo 'CustomLog ${APACHE_LOG_DIR}/access.log combined';\
    	echo 'SetEnv HTTPS ${FORCE_HTTPS}';\
    echo '</VirtualHost>';\
} > /etc/apache2/sites-available/000-default.conf
ENV HTTPS off
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN echo "export FORCE_HTTPS=\${HTTPS}" >> /etc/apache2/envvars
