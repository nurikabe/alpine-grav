#!/bin/ash

[ -f /run-pre.sh ] && /run-pre.sh

if [ ! -d /usr/html ] ; then
  mkdir -p /usr/html
  chown -R nginx:nginx /usr/html
else
  chown -R nginx:nginx /usr/html
fi

if [ ! -d /usr/html/system ] ; then
  curl -fLk -o /tmp/grav.zip  "https://github.com/getgrav/grav/releases/download/$GRAV_VERSION/grav-admin-v$GRAV_VERSION.zip"
  mkdir /tmp/grav-src
  unzip /tmp/grav.zip -d /tmp/grav-src
  mv -f /tmp/grav-src/grav-admin/* /usr/html/
  rm -R /tmp/grav*
  chown -R nginx:nginx /usr/html
else
  chown -R nginx:nginx /usr/html
fi

chown -R nginx:nginx /usr/html

find /usr/html -type f | xargs chmod 664
find /usr/html -type d | xargs chmod 775
find /usr/html -type d | xargs chmod +s

# install certs if virtual host defined and certs.conf is non-zero
if [ "$VIRTUAL_HOST" ] && [ ! -s ./certs.conf ] ; then
  certbot certonly -n --webroot -w /usr/html -d VIRTUAL_HOST
  printf "ssl_certificate_key /etc/letsencrypt/live/$VIRTUAL_HOST/privkey.pem;\n" > certs.conf
  printf "ssl_certificate /etc/letsencrypt/live/$VIRTUAL_HOST/fullchain.pem;\n" >> certs.conf
  # redirect http traffic to https
  printf "server { listen 80; return 301 https://$server_name$request_uri; }\n" >> certs.conf
  # start crond in the background
  crond
else
  touch /etc/nginx/certs.conf
fi

# start php-fpm
mkdir -p /usr/logs/php-fpm
php-fpm7

# start nginx
mkdir -p /usr/logs/nginx
mkdir -p /tmp/nginx
chown nginx /tmp/nginx
nginx
