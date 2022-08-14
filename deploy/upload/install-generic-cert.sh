#!/usr/bin/env bash

set -x
set -e

EMAIL=$1
DOMAIN=$2

echo sudo certbot certonly --standalone -d ${DOMAIN} -n --agree-tos --email ${EMAIL}
sudo certbot certonly --standalone -d ${DOMAIN} -n --agree-tos --email ${EMAIL}
mkdir ~/cert
sudo cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ~/cert/
sudo cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem ~/cert/
sudo chown -R ubuntu:ubuntu ~/cert/*.pem
