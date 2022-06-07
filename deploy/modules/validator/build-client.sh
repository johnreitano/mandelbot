#!/usr/bin/env bash

set -x
set -e

sudo apt update -y

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

# pkill ignite || : # if failed, ignite wasn't running
pkill mandelbotd || : # if failed, ignite wasn't running
sleep 1
cd ~/mandelbot
# ignite chain build --output build
make build-mandelbot-linux

ulimit -n 4096 # set maximum number of open files to 4096
