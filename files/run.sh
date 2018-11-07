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

# install certs if virtual host and email defined and certs.conf is non-zero
if [ "$VIRTUAL_HOST" ] && [ $LETSENCRYPT_EMAIL ] && [ ! -s ./certs.conf ] ; then
  # nginx not yet running so use certbot's "standalone" built-in web server
  certbot certonly -n --standalone -d $VIRTUAL_HOST --agree-tos --email $LETSENCRYPT_EMAIL
  printf "ssl_certificate_key /etc/letsencrypt/live/$VIRTUAL_HOST/privkey.pem;\n" > /etc/nginx/certs.conf
  printf "ssl_certificate /etc/letsencrypt/live/$VIRTUAL_HOST/fullchain.pem;\n" >> /etc/nginx/certs.conf
  # redirect http traffic to https
  printf 'server { listen 80; return 301 https://$server_name$request_uri; }' > /etc/nginx/redirect.conf
  # start crond in the background
  crond
fi

# touch include conf files to ensure that nginx will always start
touch /etc/nginx/certs.conf
touch /etc/nginx/redirect.conf

# start php-fpm
mkdir -p /usr/logs/php-fpm
php-fpm7

# start nginx
mkdir -p /usr/logs/nginx
mkdir -p /tmp/nginx
chown nginx /tmp/nginx
nginx
