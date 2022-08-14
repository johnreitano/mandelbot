#!/usr/bin/env bash

set -x
set -e

EMAIL=$1
DOMAIN=$2
PORT=$3

sudo DEBIAN_FRONTEND=noninteractive apt install -y nginx
sudo killall nginx 2>/dev/null || :
cat ~/upload/default.nginx | sed 's/__DOMAIN__/'${DOMAIN}'/g' | sed 's/__PORT__/'${PORT}'/g' >/tmp/default.nginx
sudo mv -f /tmp/default.nginx /etc/nginx/sites-enabled/default
sudo certbot --nginx -d ${DOMAIN} -n --agree-tos --email ${EMAIL}
sudo systemctl restart nginx
