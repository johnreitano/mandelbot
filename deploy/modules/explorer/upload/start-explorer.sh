#!/usr/bin/env bash
set -x
set -e

# nohup ignite chain serve --verbose >mandelbot.out 2>&1 </dev/null &
echo "About to start explorer node with id $(~/upload/mandelbotd tendermint show-node-id)"
pkill mandelbotd || :
sleep 1
~/upload/mandelbotd start &
sleep 1

sudo docker restart postgresql
sleep 1
sudo docker restart hasura
sleep 1

pkill bdjuno || :
sleep 1
GOPATH=$(go env GOPATH)
$GOPATH/bin/bdjuno start </dev/null &
sleep 1
