#!/usr/bin/env bash
set -x
set -e

cd ~/mandelbot
# nohup ignite chain serve --verbose >mandelbot.out 2>&1 </dev/null &
# nohup build/mandelbotd start >mandelbot.out 2>&1 </dev/null &
echo "About to start explorer node with id $(build/mandelbotd tendermint show-node-id)"
build/mandelbotd start </dev/null &
sleep 10

sudo docker start postgresql
sudo docker start hasura
GOPATH=$(go env GOPATH)
$GOPATH/bin/bdjuno start </dev/null &
