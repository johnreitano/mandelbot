#!/usr/bin/env bash
set -x
set -e

# nohup ignite chain serve --verbose >mandelbot.out 2>&1 </dev/null &
# nohup upload/mandelbotd start >mandelbot.out 2>&1 </dev/null &
echo "About to start explorer node with id $(upload/mandelbotd tendermint show-node-id)"
upload/mandelbotd start </dev/null &
sleep 10

sudo docker start postgresql
sudo docker start hasura
GOPATH=$(go env GOPATH)
$GOPATH/bin/bdjuno start </dev/null &
