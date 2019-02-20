#!/bin/bash

set -e

if [[ $DEBUG ]]; then
  set -x
fi

if [ -n "$PHP_SENDMAIL_PATH" ]; then
     sed -i 's@^;sendmail_path.*@'"sendmail_path = ${PHP_SENDMAIL_PATH}"'@' /etc/php7/php.ini
fi

if [[ $PHP_XDEBUG_ENABLED = 1 ]]; then
     sed -i 's/^;zend_extension.*/zend_extension = xdebug.so/' /etc/php7/conf.d/00_xdebug.ini
fi

if [[ $PHP_XHPROF_ENABLED = 1 ]]; then
     sed -i 's/^;extension.*/extension = xhprof.so/' /etc/php7/conf.d/20_xhprof.ini
fi

if [[ $PHP_XDEBUG_AUTOSTART = 0 ]]; then
     sed -i 's/^xdebug.remote_autostart.*/xdebug.remote_autostart = 0/' /etc/php7/conf.d/00_xdebug.ini
fi

if [[ $PHP_XDEBUG_REMOTE_CONNECT_BACK = 0 ]]; then
     sed -i 's/^xdebug.remote_connect_back.*/xdebug.remote_connect_back = 0/' /etc/php7/conf.d/00_xdebug.ini
fi

if [[ $PHP_XDEBUG_REMOTE_HOST ]]; then
     sed -i 's/^xdebug.remote_host.*/'"xdebug.remote_host = ${PHP_XDEBUG_REMOTE_HOST}"'/' /etc/php7/conf.d/00_xdebug.ini
fi

# Ensure drupal version defined.
if [ -z "$DRUPAL_VERSION" ]; then
    cp /opt/symfony.conf /etc/nginx/conf.d/default.conf
else
    if [ ! "$(ls -A /etc/nginx/conf.d)" ]; then
        cp /opt/drupal${DRUPAL_VERSION}.conf /etc/nginx/conf.d/
    else
        cp /opt/drupal${DRUPAL_VERSION}.conf /etc/nginx/conf.d/default.conf
    fi
fi



# Configure docroot.
if [ -n "$NGINX_DOCROOT" ]; then
    sed -i 's@root /var/www/html/;@'"root /var/www/html/${NGINX_DOCROOT};"'@' /etc/nginx/conf.d/*.conf
fi

if [[ -e /crontab/crontab.txt ]]; then
     crond
     crontab -u www-data /crontab/crontab.txt
fi

HOST_UID=$(stat -c %u /var/www/html)
HOST_GID=$(stat -c %g /var/www/html)

if [ -n "$HOST_GID" && "$HOST_GID" != "0" ]; then
  if ! id -g ${HOST_GID} > /dev/null 2>&1; then
    echo ok to create group...
    addgroup -g $HOST_GID user
  fi
fi

if [ -n "$HOST_UID" && "$HOST_UID" != "0" ]; then
  if ! id $HOST_UID > /dev/null 2>&1; then
    echo ok to create user...
    adduser -u $HOST_UID -s /bin/bash -D -G user user
  fi
fi


exec /usr/bin/supervisord -n -c /etc/supervisord.conf
