#!/usr/bin/env bash

set -x
set -e

# # sleep until instance is ready
# until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
#     sleep 1
# done

sudo apt update -y
sudo snap install core
sudo snap refresh core

if [[ -z "$(which make)" ]]; then
    sudo apt install -y make
fi
if [[ -z "$(which go)" ]]; then
    sudo snap install go --classic
fi
if [[ -z "$(which dasel)" ]]; then
    sudo wget -qO /usr/local/bin/dasel https://github.com/TomWright/dasel/releases/latest/download/dasel_linux_amd64
    sudo chmod a+x /usr/local/bin/dasel
fi
if [[ -z "$(which jq)" ]]; then
    sudo apt install -y jq
fi
if [[ -z "$(which ignite)" ]]; then
    sudo curl https://get.ignite.com/cli! | sudo bash
fi
if [[ -z "$(which certbot)" ]]; then
    sudo snap install --classic certbot
    sudo ln -s /snap/bin/certbot /usr/bin/certbot
fi

# pkill ignite || : # if failed, ignite wasn't running
pkill mandelbotd || : # if failed, mandelbotd wasn't running
sleep 1

ulimit -n 4096 # set maximum number of open files to 4096
