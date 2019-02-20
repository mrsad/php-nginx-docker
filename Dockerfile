FROM alpine:3.6

# Create user www-data
RUN addgroup -S -g 82 www-data && \
    adduser -u 82 -s /bin/bash -D -G www-data www-data && \
    addgroup -S nginx && \
    adduser -S -D -H -h /var/www/localhost/htdocs -s /sbin/nologin -G nginx -g nginx nginx && \
    addgroup nginx www-data

# Install packages
#RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories && \
#    echo '@edgemain http://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories
RUN apk add --update \
        bash \
        libressl \
        ca-certificates \
        openssh-client \
        rsync \
        git \
        curl \
        wget \
        gzip \
        tar \
        patch \
        perl \
        pcre \
        imap \
        imagemagick \
        mariadb-client \
        yaml \
        file \
        icu-libs \
        # Temp packages
        build-base \
        autoconf \
        libtool \
        php7-dev \
        pcre-dev \
        imagemagick-dev \
        yaml-dev \
        zlib-dev \
        libmemcached \
        libmemcached-dev \
        libmemcached-libs \
        openssl \
        libressl-dev \
        # PHP packages
        php7 \
        php7-fpm \
        php7-opcache \
        php7-session \
        php7-dom \
        php7-xml \
        php7-xmlreader \
        php7-ctype \
        php7-ftp \
        php7-gd \
        php7-json \
        php7-posix \
        php7-curl \
        php7-pdo \
        php7-pdo_mysql \
        php7-sockets \
        php7-zlib \
        php7-mcrypt \
        php7-mysqli \
        php7-sqlite3 \
        php7-bz2 \
        php7-phar \
        php7-openssl \
        php7-posix \
        php7-zip \
        php7-calendar \
        php7-iconv \
        php7-imap \
        php7-soap \
        php7-dev \
        php7-pear \
        php7-redis \
        php7-mbstring \
        php7-xdebug \
        php7-exif \
        php7-xsl \
        php7-ldap \
        php7-bcmath \
        rabbitmq-c \
        rabbitmq-c-dev \
        php7-memcached \
        php7-intl \
        php7-tokenizer \
        php7-simplexml \
        php7-xmlwriter \
        php7-imagick \
        php7-apcu \
        nginx \
        nginx-mod-http-upload-progress \
        nginx-mod-http-lua \
        luajit \
        geoip \
        gd \
        libgd \
        supervisor 

# install node-8 && yarn
ENV NODE_VERSION 8.15.0
RUN apk add --no-cache \
        libstdc++ \
        xz \
    && apk add --no-cache --virtual .build-deps \
        binutils-gold \
        curl \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        python \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz" \
    && tar -xf "node-v$NODE_VERSION.tar.xz" \
    && cd "node-v$NODE_VERSION" \
    && ./configure \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && apk del .build-deps \
    && cd .. \
    && rm -Rf "node-v$NODE_VERSION" \
    && rm "node-v$NODE_VERSION.tar.xz"

ENV YARN_VERSION 1.13.0
RUN apk add --no-cache --virtual .build-deps-yarn curl gnupg tar \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz \
  && apk del .build-deps-yarn

    # Create symlinks for backward compatibility
RUN ln -sf /usr/bin/php7 /usr/bin/php && \
    ln -sf /usr/sbin/php-fpm7 /usr/bin/php-fpm && \
    # Install imagick
    sed -ie 's/-n//g' /usr/bin/pecl && \
    yes | pecl install yaml-2.0.0 && \
    echo 'extension=yaml.so' > /etc/php7/conf.d/yaml.ini && \
    # Install amqp
    mkdir -p $HOME/php-amqp && \
    cd $HOME/php-amqp && \
    git clone https://github.com/pdezwart/php-amqp.git . && git checkout v1.9.3 && \
    phpize --clean && phpize && ./configure && make install && \
    echo 'extension=amqp.so' > /etc/php7/conf.d/amqp.ini && \
    # Install uploadprogess
    cd /tmp/ && wget https://github.com/Jan-E/uploadprogress/archive/master.zip && \
    unzip master.zip && \
    cd uploadprogress-master/ && \
    phpize7 && ./configure --with-php-config=/usr/bin/php-config7 && \
    make && make install && \
    echo 'extension=uploadprogress.so' > /etc/php7/conf.d/20_uploadprogress.ini && \
    cd .. && rm -rf ./master.zip ./uploadprogress-master && \
    cd /tmp/ && wget https://github.com/longxinH/xhprof/archive/master.zip && \
    unzip master.zip && \
    cd xhprof-master/extension/ && \
    phpize7 && ./configure --with-php-config=/usr/bin/php-config7 && \
    make && make install && \
    cd .. && mv xhprof_* /usr/share/php7/ && \
    cd /tmp/ && rm -rf ./master.zip ./xhprof-master && \
    # Disable Xdebug
    rm /etc/php7/conf.d/xdebug.ini && \
    # Install composer
    curl -sS https://getcomposer.org/installer | php7 -- --install-dir=/usr/local/bin --filename=composer && \
    # Install PHPUnit
    curl -sSL https://phar.phpunit.de/phpunit.phar -o phpunit.phar && \
        chmod +x phpunit.phar && \
        mv phpunit.phar /usr/local/bin/phpunit && \
    # Cleanup
    apk del --purge \
        *-dev \
        build-base \
        autoconf \
        libtool \
        && \
    rm -rf \
        /usr/include/php \
        /usr/lib/php/build \
        /var/cache/apk/* \
        /tmp/* \
        /root/.composer

# Configure php.ini
RUN sed -i \
        -e "s/^expose_php.*/expose_php = Off/" \
        -e "s/^;date.timezone.*/date.timezone = UTC/" \
        -e "s/^memory_limit.*/memory_limit = -1/" \
        -e "s/^max_execution_time.*/max_execution_time = 300/" \
        -e "s/^post_max_size.*/post_max_size = 512M/" \
        -e "s/^upload_max_filesize.*/upload_max_filesize = 512M/" \
        -e "s/^error_reporting.*/error_reporting = E_ALL/" \
        -e "s/^display_errors.*/display_errors = On/" \
        -e "s/^display_startup_errors.*/display_startup_errors = On/" \
        -e "s/^track_errors.*/track_errors = On/" \
        -e "s/^mysqlnd.collect_memory_statistics.*/mysqlnd.collect_memory_statistics = On/" \
        /etc/php7/php.ini && \
    echo "error_log = \"/proc/self/fd/2\"" | tee -a /etc/php7/php.ini

# Copy PHP configs
COPY conf/00_opcache.ini /etc/php7/conf.d/
COPY conf/00_xdebug.ini /etc/php7/conf.d/
COPY conf/php-fpm.conf /etc/php7/
COPY conf/20_xhprof.ini /etc/php7/conf.d/

COPY conf/supervisord.conf /etc/supervisord.conf

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/fastcgi_params /etc/nginx/fastcgi_params

COPY conf/symfony.conf /opt/
COPY conf/drupal7.conf /opt/
COPY conf/drupal8.conf /opt/

# Create work dir
RUN mkdir -p /var/www/html && \
    mkdir -p /var/www/site-php && \
    chown -R www-data:www-data /var/www

WORKDIR /var/www/html
EXPOSE 9000
EXPOSE 80 443
# Init www-data user
USER www-data

RUN composer global require hirak/prestissimo --optimize-autoloader && \
    rm -rf ~/.composer/.cache

USER root

RUN addgroup -g 1000 developer \
    && adduser -u 1000 -G developer -s /bin/sh -h /home/developer -D developer

#RUN mkdir -p /.composer && chmod 1777 /.composer && chmod 777 /

COPY docker-entrypoint.sh /usr/local/bin/
CMD docker-entrypoint.sh
